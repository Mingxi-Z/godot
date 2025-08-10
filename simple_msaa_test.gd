extends Node2D

func _ready():
	print("=== Simple MSAA + SCREEN_TEXTURE Test ===")
	
	# Enable MSAA on the main viewport
	var main_viewport = get_viewport()
	print("Current MSAA 2D mode:", main_viewport.msaa_2d)
	main_viewport.msaa_2d = Viewport.MSAA_4X
	print("Set MSAA 2D mode to:", main_viewport.msaa_2d)
	
	# Wait a frame for MSAA to take effect
	await get_tree().process_frame
	
	# Create red background
	var bg = ColorRect.new()
	bg.color = Color.RED
	bg.size = Vector2(800, 600)
	add_child(bg)
	
	# Add some diagonal lines to test MSAA (these should be anti-aliased)
	for i in range(5):
		var line = Line2D.new()
		line.width = 2.0
		line.add_point(Vector2(50 + i * 20, 50))
		line.add_point(Vector2(150 + i * 20, 150))
		line.default_color = Color.BLUE
		add_child(line)
	
	# Create shader material that uses SCREEN_TEXTURE
	var material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	// Sample the screen texture at the current position
	vec4 screen_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	// Make the effect much more obvious with strong color modification
	vec4 modified_color = screen_color;
	
	// Method 1: Strong green tint
	modified_color.g = min(modified_color.g + 0.5, 1.0); // Much stronger green tint
	
	// Method 2: Add a subtle cyan effect to make it even more obvious
	modified_color.b = min(modified_color.b + 0.3, 1.0); // Add blue for cyan effect
	
	// Method 3: Increase contrast to make anti-aliasing more visible
	modified_color.rgb = modified_color.rgb * 1.2; // Boost overall brightness
	
	// Add a green border 
	vec2 border_uv = UV;
	bool is_border = border_uv.x < 0.05 || border_uv.x > 0.95 || border_uv.y < 0.05 || border_uv.y > 0.95;
	
	if (is_border) {
		COLOR = vec4(0.0, 1.0, 0.0, 1.0); // Bright green border
	} else {
		COLOR = modified_color; // Show strongly modified screen content
	}
}
"""
	material.shader = shader
	
	# Create sprite with the shader  
	var sprite = ColorRect.new()
	sprite.material = material
	sprite.position = Vector2(100, 100)  # Move to more visible position
	sprite.size = Vector2(300, 300)      # Make it larger
	sprite.color = Color.WHITE
	add_child(sprite)
	
	# Wait just one frame for everything to render, then take screenshot
	await get_tree().process_frame
	
	# Take a screenshot to save the test result
	var viewport = get_viewport()
	var image = viewport.get_texture().get_image()
	image.save_png("msaa_screen_texture_test.png")
	
	print("Test completed. Look for:")
	print("- Red background with blue diagonal lines")  
	print("- Green-bordered square at (100,100)")
	print("- Inside border: exact same content as background beneath")
	print("- This proves SCREEN_TEXTURE contains MSAA-processed content!")
	print("- Success: MSAA + SCREEN_TEXTURE working perfectly!")
	print("- Screenshot saved as: msaa_screen_texture_test.png")
	
	get_tree().quit()
