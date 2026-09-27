extends CanvasLayer

var move_touch := -1
var move_start := Vector2.ZERO
var move_vector := Vector2.ZERO

var joystick_center := Vector2(130, 590)
var joystick_radius := 75.0

var jump_button := Rect2(1080, 570, 140, 100)

func _ready():
	create_controls()

func create_controls():
	var layer := Control.new()
	layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer)

	var joystick := ColorRect.new()
	joystick.name = "JoystickArea"
	joystick.position = Vector2(30, 490)
	joystick.size = Vector2(200, 200)
	joystick.color = Color(0.1, 0.1, 0.1, 0.18)
	joystick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(joystick)

	var jump := Button.new()
	jump.name = "JumpButton"
	jump.text = "PULAR"
	jump.position = Vector2(1080, 570)
	jump.size = Vector2(140, 100)
	jump.add_theme_font_size_override("font_size", 22)
	jump.pressed.connect(_jump_pressed)
	layer.add_child(jump)

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < 280:
				move_touch = event.index
				move_start = event.position
		elif event.index == move_touch:
			move_touch = -1
			move_vector = Vector2.ZERO

	elif event is InputEventScreenDrag:
		if event.index == move_touch:
			var offset := event.position - move_start

			if offset.length() > joystick_radius:
				offset = offset.normalized() * joystick_radius

			move_vector = offset / joystick_radius

func _jump_pressed():
	var player = get_tree().get_first_node_in_group("player")

	if player and player.is_on_floor():
		player.velocity.y = 7.0
