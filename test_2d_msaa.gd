extends Node2D

# Combined 2D and 3D MSAA test (Godot 4.x API).
# Renders both 2D and 3D geometry with configurable MSAA for comparison.

# Custom drawer classes for 2D elements
class_name CombinedMSAATest

class GridDrawer extends Node2D:
	func _draw():
		var c = Color(0.15, 0.15, 0.15)
		for x in range(0, 2561, 20):
			draw_line(Vector2(x, 0), Vector2(x, 1440), c, 1.0)
		for y in range(0, 1441, 20):
			draw_line(Vector2(0, y), Vector2(2560, y), c, 1.0)

class CircleDrawer extends Node2D:
	func _draw():
		draw_circle(Vector2.ZERO, 150, Color(0.1, 0.4, 1.0, 0.85))

class LinesDrawer extends Node2D:
	func _draw():
		var col = Color(1, 1, 0)
		for i in range(25):
			var off = i * 12
			draw_line(Vector2(100 + off, 1300), Vector2(800 + off, 600), col, 1.5)


# --- Modified for 3D MSAA blit to 2D demo ---
@export var msaa_level: int = Viewport.MSAA_4X # Options: MSAA_DISABLED, MSAA_2X, MSAA_4X, MSAA_8X

var rotating_polygon: Polygon2D
var rotating_cube: MeshInstance3D
var info_label: Label
var t := 0.0

# 3D Viewport and Sprite2D for blitting
var msaa_3d_viewport: SubViewport
var msaa_3d_sprite: Sprite2D

func _ready():
	# Set MSAA on the main (root) viewport for 2D
	if has_method("get_viewport"):
		get_viewport().msaa_2d = msaa_level
	print("Root viewport 2D MSAA level:", get_viewport().msaa_2d)

	# Create 2D scene in main viewport
	var screen_size = DisplayServer.screen_get_size()
	_create_2d_scene(self, screen_size)


	# Create 3D MSAA SubViewport and Sprite2D to display it
	msaa_3d_viewport = SubViewport.new()
	msaa_3d_viewport.name = "MSAA3DViewport"
	msaa_3d_viewport.size = screen_size
	msaa_3d_viewport.disable_3d = false
	msaa_3d_viewport.transparent_bg = false
	msaa_3d_viewport.msaa_3d = msaa_level
	msaa_3d_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(msaa_3d_viewport)

	_create_3d_scene(msaa_3d_viewport)

	msaa_3d_sprite = Sprite2D.new()
	msaa_3d_sprite.name = "MSAA3DSprite"
	msaa_3d_sprite.texture = msaa_3d_viewport.get_texture()
	msaa_3d_sprite.position = Vector2(screen_size.x * 0.5, screen_size.y * 0.5)
	msaa_3d_sprite.centered = true
	msaa_3d_sprite.modulate = Color(1, 1, 1, 0.85) # Slight transparency for overlay
	add_child(msaa_3d_sprite)

	# Info label
	info_label = Label.new()
	info_label.position = Vector2(10, screen_size.y - 50)
	info_label.add_theme_font_size_override("font_size", 20)
	info_label.add_theme_color_override("font_color", Color.WHITE)
	info_label.text = "3D MSAA blitted to 2D - Press SPACE to cycle MSAA"
	add_child(info_label)

	set_process(true)

func _create_split_viewport_scene():
	pass # Disabled in this demo

func _create_combined_scene(root: Node):
	pass # Disabled in this demo

func _create_2d_scene(root: Node, viewport_size: Vector2):
	# Background grid (to expose edge smoothing on diagonals / alpha borders)
	var grid := GridDrawer.new()
	grid.name = "Grid2D"
	root.add_child(grid)

	# Static shapes using simple Control nodes for sharp edges.
	var green_rect := ColorRect.new()
	green_rect.color = Color(0, 1, 0, 1)
	green_rect.position = Vector2(viewport_size.x * 0.1, viewport_size.y * 0.2)
	green_rect.custom_minimum_size = Vector2(viewport_size.x * 0.3, viewport_size.y * 0.15)
	root.add_child(green_rect)

	# Rotating polygon (triangle) to easily see edge smoothing.
	rotating_polygon = Polygon2D.new()
	rotating_polygon.color = Color(1, 0, 0, 0.9)
	rotating_polygon.polygon = PackedVector2Array([Vector2(-100, -80), Vector2(110, 0), Vector2(-65, 100)])
	rotating_polygon.position = Vector2(viewport_size.x * 0.5, viewport_size.y * 0.5)
	root.add_child(rotating_polygon)

	# Overlapping circle (drawn with primitive to stress AA) via helper node.
	var circle := CircleDrawer.new()
	circle.position = Vector2(viewport_size.x * 0.7, viewport_size.y * 0.3)
	root.add_child(circle)

	# Thin diagonal lines to show stair stepping differences.
	var lines := LinesDrawer.new()
	root.add_child(lines)

	# 2D Info label.
	var label_2d := Label.new()
	label_2d.text = "2D MSAA (%s)" % _get_msaa_name(msaa_level)
	label_2d.position = Vector2(10, 10)
	label_2d.add_theme_font_size_override("font_size", 18)
	label_2d.add_theme_color_override("font_color", Color.CYAN)
	root.add_child(label_2d)

func _create_3d_scene(root: Node):
	# Create a 3D scene with camera and lighting
	var camera := Camera3D.new()
	camera.position = Vector3(0, 0, 3)
	root.add_child(camera)
	
	# Add some lighting
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = Sky.new()
	env.sky.sky_material = ProceduralSkyMaterial.new()
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.3
	camera.environment = env
	
	var light := DirectionalLight3D.new()
	light.position = Vector3(2, 2, 2)
	light.look_at(Vector3.ZERO, Vector3.UP)
	root.add_child(light)
	
	# Rotating cube with sharp edges (perfect for MSAA testing)
	rotating_cube = MeshInstance3D.new()
	rotating_cube.mesh = BoxMesh.new()
	rotating_cube.position = Vector3(0, 0, 0)
	
	# Create a material for the cube
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.5, 0, 1)  # Orange
	material.metallic = 0.2
	material.roughness = 0.3
	rotating_cube.material_override = material
	root.add_child(rotating_cube)
	
	# Add a sphere with smooth surfaces (good for edge comparison)
	var sphere := MeshInstance3D.new()
	sphere.mesh = SphereMesh.new()
	sphere.position = Vector3(-1.5, 0, 0)
	
	var sphere_material := StandardMaterial3D.new()
	sphere_material.albedo_color = Color(0, 0.7, 1, 1)  # Blue
	sphere_material.metallic = 0.1
	sphere_material.roughness = 0.4
	sphere.material_override = sphere_material
	root.add_child(sphere)
	
	# Add a cylinder for more geometric variety
	var cylinder := MeshInstance3D.new()
	cylinder.mesh = CylinderMesh.new()
	cylinder.position = Vector3(1.5, 0, 0)
	cylinder.rotation = Vector3(0, 0, PI/4)  # Slight rotation for edge visibility
	
	var cyl_material := StandardMaterial3D.new()
	cyl_material.albedo_color = Color(0.8, 0, 0.8, 1)  # Magenta
	cyl_material.metallic = 0.3
	cyl_material.roughness = 0.2
	cylinder.material_override = cyl_material
	root.add_child(cylinder)
	
	# 3D Info label overlay
	var label_3d := Label.new()
	label_3d.text = "3D MSAA (%s)" % _get_msaa_name(msaa_level)
	label_3d.position = Vector2(10, 10)
	label_3d.add_theme_font_size_override("font_size", 18)
	label_3d.add_theme_color_override("font_color", Color.YELLOW)
	root.add_child(label_3d)

func _get_msaa_name(level: int) -> String:
	match level:
		Viewport.MSAA_DISABLED: return "DISABLED"
		Viewport.MSAA_2X: return "2X"
		Viewport.MSAA_4X: return "4X"
		Viewport.MSAA_8X: return "8X"
		_: return "UNKNOWN"
func _process(delta):
	t += delta
	
	# Animate 2D polygon
	if rotating_polygon:
		rotating_polygon.rotation = t * 0.5
	
	# Animate 3D cube
	if rotating_cube:
		rotating_cube.rotation = Vector3(t * 0.3, t * 0.5, t * 0.2)

func _input(event):
	# Press SPACE to cycle through MSAA levels
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			cycle_msaa()

func cycle_msaa():
	# Helper to cycle MSAA at runtime for comparison.
	var levels = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X, Viewport.MSAA_8X]
	var level_names = ["DISABLED", "2X", "4X", "8X"]
	var idx = levels.find(msaa_level)
	idx = (idx + 1) % levels.size()
	msaa_level = levels[idx]

	# Update main viewport (2D)
	get_viewport().msaa_2d = msaa_level
	# Update 3D MSAA viewport
	if msaa_3d_viewport:
		msaa_3d_viewport.msaa_3d = msaa_level

	print("Switched MSAA to: %s (%d)" % [level_names[idx], msaa_level])
	print("2D MSAA level:", get_viewport().msaa_2d)
	print("3D MSAA level:", msaa_3d_viewport.msaa_3d if msaa_3d_viewport else "N/A")

	# Update info label
	if info_label:
		info_label.text = "3D MSAA blitted to 2D (%s) - Press SPACE to cycle" % level_names[idx]

	# Force a redraw on all custom drawing nodes in 2D
	var all_nodes_2d = _get_all_children(self)
	for node in all_nodes_2d:
		if node.has_method("queue_redraw"):
			node.queue_redraw()

func _update_labels(level_name: String):
	pass # Not used in this demo

func _get_all_children(node: Node) -> Array:
	var children = []
	for child in node.get_children():
		children.append(child)
		children.append_array(_get_all_children(child))
	return children
