# Feature_Moving.gd
extends Node

@export var is_enabled: bool = true
@export var collision_buffer: float = 0.0  # Distance to keep from other objects
@export var max_collision_checks: int = 8  # Number of adjustment attempts
@export var enable_debug: bool = false  # Toggle for debugging collision visualization

var manager: XRInteractionManager
var controller: XRController3D
var raycast: RayCast3D
var object_size: float = 0.8  # Will be calculated from object bounds

func setup(_manager, _fp, _controller, _raycast):
	manager = _manager
	controller = _controller
	raycast = _raycast
	
	if not manager.object_picked_up.is_connected(_on_picked):
		manager.object_picked_up.connect(_on_picked)
	
	if not manager.object_dropped.is_connected(_on_dropped):
		manager.object_dropped.connect(_on_dropped)
	
	set_process(false)

func _on_picked(_obj):
	if not is_enabled:
		return
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
	
	var target_position: Vector3
	
	# Get desired position from raycast or forward direction
	if raycast.is_colliding():
		target_position = raycast.get_collision_point()
	else:
		var controller_forward = -raycast.global_transform.basis.z
		target_position = raycast.global_position + (controller_forward * 2.0)
	
	# Calculate object bounds for better collision detection
	if object_size < 0.1:
		object_size = _calculate_object_radius(obj)
	
	# Multi-pass collision resolution
	target_position = _resolve_collisions(obj, target_position)
	obj.global_position = target_position

func _calculate_object_radius(obj: Node3D) -> float:
	"""Calculate the approximate radius of the object from its collision shape"""
	var collision_shape = _find_collision_shape(obj)
	
	if not collision_shape or not collision_shape.shape:
		return 1.0
	
	var shape = collision_shape.shape
	
	# Calculate radius based on the shape type
	if shape is SphereShape3D:
		return shape.radius
	elif shape is BoxShape3D:
		var size = shape.size / 2.0
		return size.length()
	elif shape is CapsuleShape3D:
		return max(shape.radius, shape.height / 2.0)
	elif shape is CylinderShape3D:
		return max(shape.radius, shape.height / 2.0)
	
	# Fallback: use shape's AABB
	var aabb = shape.get_debug_mesh().get_aabb()
	return (aabb.size / 2.0).length()

func _resolve_collisions(obj: Node3D, desired_pos: Vector3) -> Vector3:
	"""Iteratively resolve collisions by pushing object away from obstacles"""
	var current_pos = desired_pos
	var adjustment_distance = collision_buffer + object_size
	
	for attempt in range(max_collision_checks):
		var colliding_objects = _get_colliding_objects(obj, current_pos)
		
		if colliding_objects.is_empty():
			if enable_debug:
				print("✓ Position clear at attempt %d" % attempt)
			return current_pos
		
		# Calculate average push direction away from all colliders
		var push_direction = Vector3.ZERO
		for collider in colliding_objects:
			var direction = (current_pos - collider.global_position).normalized()
			push_direction += direction
		
		push_direction = push_direction.normalized()
		current_pos = current_pos + (push_direction * adjustment_distance * 0.5)
		
		if enable_debug:
			print("Collision detected - pushing away (attempt %d)" % (attempt + 1))
	
	if enable_debug:
		print("⚠ Max collision checks reached - returning best position")
	return current_pos

func _get_colliding_objects(obj: Node3D, test_pos: Vector3) -> Array:
	"""Get all objects colliding at the test position"""
	var colliding = []
	
	# Try to get the collision shape from the object
	var collision_shape = _find_collision_shape(obj)
	if not collision_shape:
		return colliding
	
	var space_state = obj.get_world_3d().direct_space_state
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = collision_shape.shape
	query.transform.origin = test_pos
	query.collide_with_areas = true  # Include areas (XRToolsInteractableArea)
	query.collide_with_bodies = true
	
	var result = space_state.intersect_shape(query)
	
	for collision in result:
		var collider = collision["collider"]
		
		# Get the actual interactive object (parent XRToolsInteractableArea if collider is CollisionShape3D)
		var interactive_obj = collider
		if collider is CollisionShape3D and collider.get_parent():
			interactive_obj = collider.get_parent()
		
		# Exclude the object itself, ground, and other non-interactive objects
		if interactive_obj != obj and interactive_obj != manager.held_object and not _is_ground(interactive_obj):
			# Only add if not already in list (avoid duplicates)
			if interactive_obj not in colliding:
				colliding.append(interactive_obj)
	
	return colliding

func _find_collision_shape(obj: Node3D) -> CollisionShape3D:
	"""Find the collision shape in the object or its children"""
	if obj is CollisionShape3D:
		return obj
	
	for child in obj.get_children():
		if child is CollisionShape3D:
			return child
		var found = _find_collision_shape(child)
		if found:
			return found
	
	return null

func _is_ground(node: Node) -> bool:
	"""Check if node is a ground/terrain object"""
	return node.name.to_lower().contains("ground") or \
		   node.name.to_lower().contains("floor") or \
		   node.name.to_lower().contains("terrain")
