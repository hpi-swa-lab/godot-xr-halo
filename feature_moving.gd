# Feature_Moving.gd
extends Node

@export var is_enabled: bool = true 

var manager: XRInteractionManager
var controller: XRController3D
var raycast: RayCast3D

# var rotation_offset: Basis  <-- WURDE ENTFERNT (Brauchen wir nicht mehr)

func setup(_manager, _fp, _controller, _raycast):
	manager = _manager
	controller = _controller
	raycast = _raycast
	
	if not manager.object_picked_up.is_connected(_on_picked):
		manager.object_picked_up.connect(_on_picked)
	
	if not manager.object_dropped.is_connected(_on_dropped):
		manager.object_dropped.connect(_on_dropped)
	
	set_process(false)

func _on_picked(obj):
	if not is_enabled: return 
	
	# Wir müssen hier keinen Rotation-Offset mehr berechnen, 
	# da wir die Rotation des Objekts einfach so lassen, wie sie ist.
	
	set_process(true)

func _on_dropped(_obj):
	set_process(false)

func _process(_delta):
	if not is_enabled or not manager: 
		set_process(false)
		return
		
	var obj = manager.held_object
	if not obj or not is_instance_valid(obj): 
		set_process(false)
		return 

	# 1. Position Logik (Bleibt gleich)
	# Wir ändern NUR die global_position. Die Rotation (Basis) bleibt unberührt.
	if raycast.is_colliding():
		# Wir setzen die Position auf den Kollisionspunkt
		obj.global_position = raycast.get_collision_point()
	else:
		# Wenn wir in den Himmel zeigen, halten wir es in fester Distanz
		var controller_forward = -raycast.global_transform.basis.z
		obj.global_position = raycast.global_position + (controller_forward * 2.0)

	# 2. Rotation Logik <-- WURDE ENTFERNT
	# Da wir diesen Block gelöscht haben, behält das Objekt einfach seine
	# aktuelle Rotation bei, egal wie du den Controller drehst.
