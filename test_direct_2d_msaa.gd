extends Node2D

# Direct test for 3D->2D MSAA blitting scenario
# This simulates rendering 3D content first, then 2D MSAA on top

@export var msaa_level: int = Viewport.MSAA_4X

func _ready():
	# Enable 2D MSAA
	get_viewport().msaa_2d = msaa_level
	
	print("2D MSAA level:", get_viewport().msaa_2d)
	print("Testing 2D MSAA rendering - this should show smooth edges")
	
	# Create visible 2D content with sharp edges to test MSAA
	_create_test_content()
	
	set_process(true)

func _create_test_content():
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.2, 1.0)
	bg.size = get_viewport().get_visible_rect().size
	bg.z_index = -100
	add_child(bg)
	
	# Rotating triangle - good for seeing MSAA on edges
	var triangle := Polygon2D.new()
	triangle.color = Color(1, 0.3, 0.3, 0.9)
	triangle.polygon = PackedVector2Array([
		Vector2(-80, -60),
		Vector2(90, 10),
		Vector2(-40, 80)
	])
	triangle.position = Vector2(300, 250)
	add_child(triangle)
	
	# Store reference for animation
	triangle.set_meta("rotate", true)
	
	# Circle using custom draw - shows curved edge antialiasing
	var circle_drawer := CircleDrawer.new()
	circle_drawer.position = Vector2(600, 200)
	add_child(circle_drawer)
	
	# Diagonal lines - perfect for showing stair-stepping vs smooth
	var line_drawer := LineDrawer.new()
	add_child(line_drawer)
	
	# Info labels
	var label := Label.new()
	label.text = "2D MSAA Test Scene\nPress SPACE to toggle MSAA\nLook at edges - smooth = MSAA on, jagged = MSAA off"
	label.position = Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)
	
	var status_label := Label.new()
	status_label.name = "StatusLabel"
	status_label.text = "MSAA: " + _get_msaa_name(msaa_level)
	status_label.position = Vector2(10, get_viewport().get_visible_rect().size.y - 40)
	status_label.add_theme_font_size_override("font_size", 20)
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
	# Animate the triangle
	for child in get_children():
		if child.has_meta("rotate"):
			child.rotation += delta * 0.8

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		# Toggle MSAA
		if get_viewport().msaa_2d == Viewport.MSAA_DISABLED:
			get_viewport().msaa_2d = msaa_level
		else:
			get_viewport().msaa_2d = Viewport.MSAA_DISABLED
		
		# Update status
		var status_label = get_node("StatusLabel")
		if status_label:
			status_label.text = "MSAA: " + _get_msaa_name(get_viewport().msaa_2d)
		
		print("Toggled 2D MSAA to:", get_viewport().msaa_2d)

class CircleDrawer extends Node2D:
	func _draw():
		# Draw a circle with sharp edges to test antialiasing
		draw_circle(Vector2.ZERO, 80, Color(0.2, 0.8, 0.2, 0.8))
		# Draw outline
		draw_arc(Vector2.ZERO, 80, 0, TAU, 32, Color.WHITE, 2.0)

class LineDrawer extends Node2D:
	func _draw():
		# Draw diagonal lines at various angles to show antialiasing
		var colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.MAGENTA]
		
		for i in range(20):
			var start_x = 50 + i * 30
			var start_y = 350
			var end_x = start_x + 150
			var end_y = start_y + 200 + (i * 10)
			
			draw_line(
				Vector2(start_x, start_y),
				Vector2(end_x, end_y),
				colors[i % colors.size()],
				2.0
			)
