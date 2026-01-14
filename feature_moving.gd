extends Node

@export var is_enabled: bool = true # Wird vom Manager gesteuert

var manager: XRInteractionManager
var controller: XRController3D
var raycast: RayCast3D

var rotation_offset: Basis

func setup(_manager, _fp, _controller, _raycast):
	manager = _manager
	controller = _controller
	raycast = _raycast
	
	# WICHTIG: Signale IMMER im Setup verbinden, nicht während der Laufzeit
	if not manager.object_picked_up.is_connected(_on_picked):
		manager.object_picked_up.connect(_on_picked)
	
	if not manager.object_dropped.is_connected(_on_dropped):
		manager.object_dropped.connect(_on_dropped)
	
	set_process(false)

func _on_picked(obj):
	# --- DER TORWÄCHTER (WICHTIG!) ---
	# Wenn der Manager sagt "Moving ist aus", brechen wir hier sofort ab.
	# Auch wenn das Signal kommt, ignorieren wir es.
	if not is_enabled:
		return 

	# Ab hier läuft der normale Code weiter
	print("MOVING FEATURE: Started")
	
	rotation_offset = controller.global_transform.basis.inverse() * obj.global_transform.basis
	set_process(true)

func _on_dropped(_obj):
	# Stoppt das Script sofort
	set_process(false)

func _process(_delta):
	# Doppelte Sicherheit
	if not is_enabled or not manager: 
		set_process(false)
		return
		
	var obj = manager.held_object
	if not obj: return 

	# 1. Position Logik
	if raycast.is_colliding():
		obj.global_position = raycast.get_collision_point()
	else:
		var controller_forward = -raycast.global_transform.basis.z
		obj.global_position = raycast.global_position + (controller_forward * 2.0)

	# 2. Rotation Logik
	var current_scale = obj.scale
	obj.global_transform.basis = controller.global_transform.basis * rotation_offset
	obj.scale = current_scale
