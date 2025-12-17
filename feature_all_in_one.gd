extends Node

@export var is_enabled: bool = true

var manager: XRInteractionManager
var controller: XRController3D # Rechte Hand (nur für Position)
var rotate_hand: XRController3D # Linke Hand (für Rotation)
var raycast: RayCast3D

var rotation_offset: Basis

func setup(_manager, _fp, _controller, _raycast):
	manager = _manager
	controller = _controller
	raycast = _raycast
	
	# NEU: Wir holen uns die Linke Hand für die Rotation
	rotate_hand = manager.left_controller
	
	if not rotate_hand:
		printerr("WARNUNG: Feature_Grabber hat keine Linke Hand für Rotation gefunden!")
	
	manager.object_picked_up.connect(_on_picked)
	manager.object_dropped.connect(_on_dropped)
	set_process(false)

func _on_picked(obj):
	if not is_enabled: return
	
	# NEU: Wir berechnen den Offset zur LINKEN Hand
	# Damit springt das Objekt nicht, sondern dreht sich relativ zur linken Hand weiter
	if rotate_hand:
		rotation_offset = rotate_hand.global_transform.basis.inverse() * obj.global_transform.basis
	
	set_process(true)

func _on_dropped(_obj):
	set_process(false)

func _process(_delta):
	var obj = manager.held_object
	if not obj: return

	# 1. POSITION (Weiterhin Rechte Hand / Raycast)
	if raycast.is_colliding():
		obj.global_position = raycast.get_collision_point()
	else:
		var controller_forward = -raycast.global_transform.basis.z
		obj.global_position = raycast.global_position + (controller_forward * 2.0)

	# 2. ROTATION (Jetzst Linke Hand)
	if rotate_hand:
		# Scale-Fix (wichtig, damit Scaler und Rotation sich nicht beißen)
		var current_scale = obj.scale
		
		# Wir nehmen die Basis der LINKEN Hand + den ursprünglichen Offset
		obj.global_transform.basis = rotate_hand.global_transform.basis * rotation_offset
		
		# Scale wiederherstellen
		obj.scale = current_scale
