extends Node

@export var is_enabled: bool = true
@export var rotation_speed: float = 3.0

var manager: XRInteractionManager
var rotate_hand: XRController3D

func setup(_manager, _fp, _controller, _raycast):
	manager = _manager
	rotate_hand = manager.left_controller
	
	if not rotate_hand:
		printerr("ERROR: Feature_Rotating - Left Controller missing!")
	
	if not manager.object_picked_up.is_connected(_on_picked):
		manager.object_picked_up.connect(_on_picked)
	
	if not manager.object_dropped.is_connected(_on_dropped):
		manager.object_dropped.connect(_on_dropped)
		
	set_process(false)

func _on_picked(obj):
	if not is_enabled:
		return
	set_process(true)

func _on_dropped(_obj):
	set_process(false)

func _process(delta):
	if not is_enabled or not manager or not rotate_hand:
		set_process(false)
		return

	var obj = manager.held_object
	if not obj:
		return

	var joystick = rotate_hand.get_vector2("primary")
	
	# Apply deadzone to prevent drift
	if joystick.length() < 0.1:
		return

	# Rotate around world Y-axis (horizontal spin)
	obj.rotate_y(-joystick.x * rotation_speed * delta)
	
	# Rotate around local X-axis (tilt)
	obj.rotate_object_local(Vector3.RIGHT, -joystick.y * rotation_speed * delta)
