extends Node2D

# Simpler test for ENV_BG_CANVAS + 2D MSAA scenario
# This creates the exact case where the blit might be needed

@export var msaa_level: int = Viewport.MSAA_4X

var rotating_shape: Polygon2D

func _ready():
	# Enable 2D MSAA
	get_viewport().msaa_2d = msaa_level
	
	# Add 2D shapes FIRST (these will be the background)
	rotating_shape = Polygon2D.new()
	rotating_shape.color = Color(1, 0, 0, 0.8)
	rotating_shape.polygon = PackedVector2Array([
		Vector2(-50, -40), 
		Vector2(60, 0), 
		Vector2(-30, 50)
	])
	rotating_shape.position = Vector2(400, 300)
	add_child(rotating_shape)
	
	# Add diagonal lines to show MSAA
	var line_node := LineNode.new()
	add_child(line_node)
	
	# Add a background color using ColorRect
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2, 1.0)  # Dark blue background
	bg.size = Vector2(1200, 800)
	bg.z_index = -100  # Behind everything
	add_child(bg)
	
	# For BG_CANVAS mode, we need a Camera3D and some 3D content
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 5)
	add_child(camera)
	
	# Add 3D content that will render ON TOP of the 2D canvas
	var cube := MeshInstance3D.new()
	cube.mesh = BoxMesh.new()
	cube.position = Vector3(0, 0, 0)
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 0, 0.7)  # Semi-transparent green
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cube.material_override = material
	add_child(cube)
	
	# Add lighting for the 3D content
	var light := DirectionalLight3D.new()
	light.position = Vector3(2, 2, 2)
	light.look_at(Vector3.ZERO, Vector3.UP)
	add_child(light)
	
	# Set environment to BG_CANVAS mode - this makes 2D canvas the background
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	camera.environment = env
	
	print("2D MSAA level:", get_viewport().msaa_2d)
	print("Environment BG mode: BG_CANVAS")
	print("This creates the scenario where 3D renders on 2D background with MSAA")
	
	# Info
	var label := Label.new()
	label.text = "BG_CANVAS + 2D MSAA Test\n2D content = background, 3D cube = foreground\nPress SPACE to toggle MSAA"
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)
	
	set_process(true)

func _process(delta):
	if rotating_shape:
		rotating_shape.rotation += delta * 0.5

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		# Toggle MSAA to see the difference
		if get_viewport().msaa_2d == Viewport.MSAA_DISABLED:
			get_viewport().msaa_2d = msaa_level
		else:
			get_viewport().msaa_2d = Viewport.MSAA_DISABLED
		print("Toggled 2D MSAA to:", get_viewport().msaa_2d)

class LineNode extends Node2D:
	func _draw():
		# Draw diagonal lines to show jaggies vs smooth edges
		for i in range(15):
			var y = 100 + i * 25
			draw_line(
				Vector2(100, y), 
				Vector2(600, y + 200), 
				Color(1, 1, 0, 0.9), 
				1.5
			)
