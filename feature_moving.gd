extends Node

@export var is_enabled: bool = true

var manager: XRInteractionManager
var controller: XRController3D
var raycast: RayCast3D

var rotation_offset: Basis

func setup(_manager, _fp, _controller, _raycast):
	manager = _manager
	controller = _controller
	raycast = _raycast
	
	# waiting for signal
	manager.object_picked_up.connect(_on_picked)
	
	# Prozess deaktivieren falls nichts gehalten wird
	set_process(false)

func _on_picked(obj):
	# Rotationsoffset berechnen
	rotation_offset = controller.global_transform.basis.inverse() * obj.global_transform.basis
	
	# Update-Loop starten
	set_process(true)
	
	# Wenn gedroppt wird, stoppen wir das Script automatisch via Signal check oder im process
	# Besser: Wir verbinden auch Drop signal
	if not manager.object_dropped.is_connected(_on_dropped):
		manager.object_dropped.connect(_on_dropped)

func _on_dropped(_obj):
	set_process(false)

func _process(_delta):
	if not manager: return
	var obj = manager.held_object
	if not obj: return # Sollte nicht passieren, aber sicher ist sicher

	# 1. Position
	if raycast.is_colliding():
		obj.global_position = raycast.get_collision_point()
	else:
		var controller_forward = -raycast.global_transform.basis.z
		obj.global_position = raycast.global_position + (controller_forward * 2.0)

	# 2. Rotation (Mit Scale-Fix!)
	var current_scale = obj.scale
	obj.global_transform.basis = controller.global_transform.basis * rotation_offset
	obj.scale = current_scale
