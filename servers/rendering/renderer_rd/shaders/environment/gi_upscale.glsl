#[compute]

#version 450

#VERSION_DEFINES

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0) uniform sampler2D source_ambient;
layout(set = 0, binding = 1) uniform sampler2D source_reflection;
layout(set = 0, binding = 2) uniform sampler2D source_depth;
layout(set = 0, binding = 3) uniform sampler2D source_normal_roughness;

layout(rgba16f, set = 1, binding = 0) uniform restrict writeonly image2D dest_ambient;
layout(rgba16f, set = 1, binding = 1) uniform restrict writeonly image2D dest_reflection;

vec3 fetch_normal(ivec2 pos) {
	vec3 normal = texelFetch(source_normal_roughness, pos, 0).xyz;
	normal = normalize(normal * 2.0 - 1.0);
	return normal;
}

void main() {
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
	ivec2 full_size = imageSize(dest_ambient);
	ivec2 half_size = textureSize(source_ambient, 0);

	if (any(greaterThanEqual(pos, full_size))) {
		return;
	}

	vec2 uv = (vec2(pos) + vec2(0.5)) / vec2(full_size);
	vec2 half_coord = vec2(pos) / 2.0; // Half-resolution GI texel q is computed from full-resolution pixel 2q.
	ivec2 base_coord = ivec2(floor(half_coord));
	vec2 fraction = fract(half_coord);

	ivec2 sample_positions[4] = ivec2[](
		clamp(base_coord, ivec2(0), ivec2(half_size - 1)),
		clamp(base_coord + ivec2(1, 0), ivec2(0), ivec2(half_size - 1)),
		clamp(base_coord + ivec2(0, 1), ivec2(0), ivec2(half_size - 1)),
		clamp(base_coord + ivec2(1, 1), ivec2(0), ivec2(half_size - 1))
	);

	ivec2 guide_positions[4] = ivec2[](
		clamp(sample_positions[0] << 1, ivec2(0), ivec2(full_size - 1)),
		clamp(sample_positions[1] << 1, ivec2(0), ivec2(full_size - 1)),
		clamp(sample_positions[2] << 1, ivec2(0), ivec2(full_size - 1)),
		clamp(sample_positions[3] << 1, ivec2(0), ivec2(full_size - 1))
	);

	float left_weight = 1.0 - fraction.x;
	float right_weight = fraction.x;
	float top_weight = 1.0 - fraction.y;
	float bottom_weight = fraction.y;

	vec4 weight_spatial = vec4(
		left_weight * top_weight,
		right_weight * top_weight,
		left_weight * bottom_weight,
		right_weight * bottom_weight
	);

	float depth = texelFetch(source_depth, pos, 0).r;
	vec3 normal = fetch_normal(pos);

	vec4 ambient[4] = vec4[](
		texelFetch(source_ambient, sample_positions[0], 0),
		texelFetch(source_ambient, sample_positions[1], 0),
		texelFetch(source_ambient, sample_positions[2], 0),
		texelFetch(source_ambient, sample_positions[3], 0)
	);

	vec4 reflection[4] = vec4[](
		texelFetch(source_reflection, sample_positions[0], 0),
		texelFetch(source_reflection, sample_positions[1], 0),
		texelFetch(source_reflection, sample_positions[2], 0),
		texelFetch(source_reflection, sample_positions[3], 0)
	);

	vec4 sample_depths = vec4(
		texelFetch(source_depth, guide_positions[0], 0).r,
		texelFetch(source_depth, guide_positions[1], 0).r,
		texelFetch(source_depth, guide_positions[2], 0).r,
		texelFetch(source_depth, guide_positions[3], 0).r
	);

	vec3 sample_normal[4] = vec3[](
		fetch_normal(guide_positions[0]),
		fetch_normal(guide_positions[1]),
		fetch_normal(guide_positions[2]),
		fetch_normal(guide_positions[3])
	);

	// Match SSR resolve: compare raw depth buffer values, not linear view-space depth.
	const float DEPTH_FACTOR = 2048.0;
	vec4 depth_diff = abs(sample_depths - vec4(depth));
	vec4 weight_depth = exp(-depth_diff * DEPTH_FACTOR);

	const float NORMAL_FACTOR = 32.0;
	vec4 normal_similarity = vec4(
		dot(normal, sample_normal[0]),
		dot(normal, sample_normal[1]),
		dot(normal, sample_normal[2]),
		dot(normal, sample_normal[3])
	);
	vec4 normal_diff = clamp(vec4(1.0) - normal_similarity, 0.0, 1.0);
	vec4 weight_normal = exp(-normal_diff * NORMAL_FACTOR);

	vec4 weight = weight_spatial * weight_depth * weight_normal;

	vec4 ambient_result = ambient[0] * weight.x + ambient[1] * weight.y + ambient[2] * weight.z + ambient[3] * weight.w;
	vec4 reflection_result = reflection[0] * weight.x + reflection[1] * weight.y + reflection[2] * weight.z + reflection[3] * weight.w;
	float weight_sum = dot(weight, vec4(1.0));
	if (weight_sum > 1e-6) {
		ambient_result /= weight_sum;
		reflection_result /= weight_sum;
	} else { // Fall back to the original screen-UV bilinear sampling.
		ambient_result = textureLod(source_ambient, uv, 0);
		reflection_result = textureLod(source_reflection, uv, 0);
	}

	imageStore(dest_ambient, pos, ambient_result);
	imageStore(dest_reflection, pos, reflection_result);
}
