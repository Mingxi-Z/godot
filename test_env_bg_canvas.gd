extends Control  # Changed from Node2D to Control for better 2D/3D mixing

# Test script to demonstrate ENV_BG_CANVAS scenario where 3D renders first,
# then 2D MSAA needs to render on top of the 3D content

@export var msaa_level: int = Viewport.MSAA_4X

func _ready():
	# Enable 2D MSAA on the viewport
	get_viewport().msaa_2d = msaa_level
	print("2D MSAA level:", get_viewport().msaa_2d)
	
	# Create a SubViewport for 3D content
	var sub_viewport := SubViewport.new()
	sub_viewport.size = get_viewport().get_visible_rect().size
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(sub_viewport)
	
	# Create 3D scene in the SubViewport
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 3)
	sub_viewport.add_child(camera)
	
	# Set up environment with Canvas background mode
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS  # This is the key scenario
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_energy = 0.3
	camera.environment = env
	
	# Add 3D content
	var cube := MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.position = Vector3(0, 0, 0)
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.5, 0, 1)
	cube.material_override = material
	sub_viewport.add_child(cube)
	
	# Add lighting
	var light := DirectionalLight3D.new()
	light.position = Vector3(2, 2, 2)
	light.look_at(Vector3.ZERO, Vector3.UP)
	sub_viewport.add_child(light)
	
	# Create a TextureRect to display the 3D viewport
	var texture_rect := TextureRect.new()
	texture_rect.texture = sub_viewport.get_texture()
	texture_rect.size = get_viewport().get_visible_rect().size
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(texture_rect)
	
	print("Environment BG mode:", env.background_mode)
	
	
	# Add 2D content that will render with MSAA
	var canvas_layer := CanvasLayer.new()
	add_child(canvas_layer)
	
	var polygon := Polygon2D.new()
	polygon.color = Color(0, 1, 0, 0.8)  # Semi-transparent green
	polygon.polygon = PackedVector2Array([
		Vector2(-100, -80), 
		Vector2(110, 0), 
		Vector2(-65, 100)
	])
	polygon.position = Vector2(400, 300)
	canvas_layer.add_child(polygon)
	
	# Add some 2D lines to show MSAA effect
	var line_drawer := LineDrawer.new()
	canvas_layer.add_child(line_drawer)
	
	# Info label
	var label := Label.new()
	label.text = "ENV_BG_CANVAS Test - 3D renders first, then 2D MSAA on top"
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	canvas_layer.add_child(label)

class LineDrawer extends Node2D:
	func _draw():
		# Draw some diagonal lines to show MSAA antialiasing
		for i in range(10):
			var y_offset = i * 30 + 100
			draw_line(
				Vector2(600, y_offset), 
				Vector2(800, y_offset + 100), 
				Color(1, 1, 0, 0.9), 
				2.0
			)
