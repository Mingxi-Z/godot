extends Node2D

# Test for actual 3D->2D MSAA blitting scenario
# This creates 3D content first, then 2D MSAA content that needs the 3D as base

@export var msaa_level: int = Viewport.MSAA_4X

var rotating_cube: MeshInstance3D

func _ready():
	# Enable both 2D and 3D MSAA
	get_viewport().msaa_2d = msaa_level
	get_viewport().msaa_3d = msaa_level
	
	print("2D MSAA level:", get_viewport().msaa_2d)
	print("3D MSAA level:", get_viewport().msaa_3d)
	print("This tests the 3D->2D blit scenario in canvas_begin")
	
	# Step 1: Create 3D content that renders FIRST
	_create_3d_content()
	
	# Step 2: Create 2D content that renders ON TOP with MSAA
	# This is where the blit from 3D to 2D MSAA buffer might be needed
	_create_2d_overlay()
	
	set_process(true)

func _create_3d_content():
	# Create a 3D scene that renders first
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 3)
	add_child(camera)
	
	# 3D Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.2
	camera.environment = env
	
	# 3D lighting
	var light := DirectionalLight3D.new()
	light.position = Vector3(2, 2, 2)
	light.look_at(Vector3.ZERO, Vector3.UP)
	add_child(light)
	
	# 3D rotating cube
	rotating_cube = MeshInstance3D.new()
	rotating_cube.mesh = BoxMesh.new()
	rotating_cube.position = Vector3(0, 0, 0)
	
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.4, 0.2, 1.0)  # Orange
	material.metallic = 0.1
	material.roughness = 0.7
	rotating_cube.material_override = material
	add_child(rotating_cube)
	
	# Add a sphere for more 3D content
	var sphere := MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.position = Vector3(-1.5, 0, 0)
	
	var sphere_material := StandardMaterial3D.new()
	sphere_material.albedo_color = Color(0.2, 0.6, 0.9, 1.0)  # Blue
	sphere_material.metallic = 0.3
	sphere_material.roughness = 0.4
	sphere.material_override = sphere_material
	add_child(sphere)

func _create_2d_overlay():
	# This 2D content renders AFTER 3D content
	# When 2D MSAA is enabled, it needs the 3D result as base
	# This is the scenario where 3D->2D blit might be needed
	
	# Semi-transparent 2D shapes that overlay the 3D content
	var overlay_triangle := Polygon2D.new()
	overlay_triangle.color = Color(1, 0, 0, 0.6)  # Semi-transparent red
	overlay_triangle.polygon = PackedVector2Array([
		Vector2(-100, -80),
		Vector2(120, 20), 
		Vector2(-60, 100)
	])
	overlay_triangle.position = Vector2(300, 250)
	overlay_triangle.set_meta("rotate", true)
	add_child(overlay_triangle)
	
	# 2D lines that cross over 3D content
	var line_overlay := LineOverlay.new()
	add_child(line_overlay)
	
	# UI elements
	var ui_panel := ColorRect.new()
	ui_panel.color = Color(0, 0, 0, 0.7)  # Semi-transparent black
	ui_panel.size = Vector2(300, 100)
	ui_panel.position = Vector2(10, 10)
	add_child(ui_panel)
	
	var info_label := Label.new()
	info_label.text = "3D->2D MSAA Blit Test\n3D: Orange cube + blue sphere\n2D: Red triangle + lines (with MSAA)\nPress SPACE to toggle MSAA"
	info_label.position = Vector2(15, 15)
	info_label.add_theme_font_size_override("font_size", 12)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	add_child(info_label)
	
	var status_label := Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "2D MSAA: " + _get_msaa_name(msaa_level)
	status_label.position = Vector2(400, 10)
	status_label.add_theme_font_size_override("font_size", 16)
	status_label.add_theme_color_override("font_color", Color.YELLOW)
	add_child(status_label)

func _get_msaa_name(level: int) -> String:
	match level:
		Viewport.MSAA_DISABLED: return "DISABLED"
		Viewport.MSAA_2X: return "2X"
		Viewport.MSAA_4X: return "4X"
		Viewport.MSAA_8X: return "8X"
		_: return "UNKNOWN"

func _process(delta):
	# Animate 3D cube
	if rotating_cube:
		rotating_cube.rotation = Vector3(
			delta * 0.3 + rotating_cube.rotation.x,
			delta * 0.5 + rotating_cube.rotation.y,
			delta * 0.2 + rotating_cube.rotation.z
		)
	
	# Animate 2D overlay
	for child in get_children():
		if child.has_meta("rotate"):
			child.rotation += delta * 0.4

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		# Toggle MSAA to test the difference
		if get_viewport().msaa_2d == Viewport.MSAA_DISABLED:
			get_viewport().msaa_2d = msaa_level
		else:
			get_viewport().msaa_2d = Viewport.MSAA_DISABLED
		
		# Update status
		var status_label = get_node("StatusLabel")
		if status_label:
			status_label.text = "2D MSAA: " + _get_msaa_name(get_viewport().msaa_2d)
		
		print("Toggled 2D MSAA to:", get_viewport().msaa_2d)
		print("This should test if 3D->2D blit is working correctly")

class LineOverlay extends Node2D:
	func _draw():
		# Draw 2D lines that cross over the 3D content
		# These lines should be anti-aliased when 2D MSAA is enabled
		var screen_center = get_viewport().get_visible_rect().size * 0.5
		
		# Cross pattern
		draw_line(
			Vector2(screen_center.x - 200, screen_center.y - 150),
			Vector2(screen_center.x + 200, screen_center.y + 150),
			Color(0, 1, 0, 0.8), 3.0
		)
		draw_line(
			Vector2(screen_center.x + 200, screen_center.y - 150), 
			Vector2(screen_center.x - 200, screen_center.y + 150),
			Color(0, 1, 0, 0.8), 3.0
		)
		
		# Diagonal lines at various angles
		for i in range(8):
			var angle = i * PI / 4
			var start = screen_center + Vector2(cos(angle), sin(angle)) * 100
			var end = screen_center + Vector2(cos(angle), sin(angle)) * 250
			draw_line(start, end, Color(1, 1, 0, 0.7), 2.0)
