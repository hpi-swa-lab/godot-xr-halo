extends Node

@export var is_enabled: bool = true
@export var sensitivity: float = 1.5
@export var deadzone: float = 0.05

var manager: XRInteractionManager
var scaling_hand: XRController3D
var initial_hand_height: float = 0.0

func setup(_manager, _fp, _right_controller, _raycast):
	manager = _manager
	scaling_hand = manager.left_controller

	if not scaling_hand:
		printerr("ERROR: Feature_Scaling - Left Controller missing!")
		is_enabled = false
		return

	manager.object_picked_up.connect(_on_picked)
	manager.object_dropped.connect(_on_dropped)
	set_process(false)

func _on_picked(_obj):
	if not is_enabled:
		return

	initial_hand_height = scaling_hand.global_position.y
	set_process(true)

func _on_dropped(_obj):
	set_process(false)

func _process(delta):
	var obj = manager.held_object
	if not obj:
		return

	var current_hand_y = scaling_hand.global_position.y
	var diff = current_hand_y - initial_hand_height

	# Only scale when hand movement exceeds deadzone
	if abs(diff) > deadzone:
		var scale_change_percent = diff * sensitivity * delta
		var new_scale = obj.scale + (obj.scale * scale_change_percent)
		obj.scale = new_scale.clamp(Vector3(0.01, 0.01, 0.01), Vector3(10.0, 10.0, 10.0))
