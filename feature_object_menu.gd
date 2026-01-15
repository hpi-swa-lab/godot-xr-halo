extends Node3D

# --- ObjectHaloMenu.gd ---

@export var buttons: Array[Area3D] 

var target_object: Node3D
var camera: Node3D
var world_radius: float = 0.5
var is_active: bool = false

# Einheitliche Öffnen-Funktion
func open_menu(obj: Node3D, _camera: Node3D):
	target_object = obj
	camera = _camera
	is_active = true
	visible = true
	
	# AABB Größe finden (Dein Fix von vorhin)
	var aabb = _find_visual_aabb(target_object)
	var world_size = aabb.size * target_object.scale
	var max_dim = max(world_size.x, max(world_size.y, world_size.z))
	if max_dim < 0.1: max_dim = 0.5 # Fallback
	
	world_radius = (max_dim / 2.0) + 0.25 
	
	# Einmaliges Update
	_process(0)

func close_menu():
	is_active = false
	visible = false
	target_object = null

func _process(_delta):
	if not is_active or not target_object or not camera: return

	# 1. Position & Billboard
	global_position = target_object.global_position
	look_at(camera.global_position, Vector3.UP)
	
	# 2. Scale
	var dist = global_position.distance_to(camera.global_position)
	var display_scale = clamp(dist * 0.3, 0.5, 5.0)
	scale = Vector3.ONE * display_scale
	
	# 3. Button Positionen anpassen
	if buttons.size() > 0:
		var angle_step = (2 * PI) / buttons.size()
		var local_radius = world_radius / display_scale
		
		for i in range(buttons.size()):
			var btn = buttons[i]
			var angle = i * angle_step + (PI / 2) 
			btn.position = Vector3(cos(angle), sin(angle), 0) * local_radius
			btn.rotation = Vector3.ZERO

# Die wichtige Hilfsfunktion
func _find_visual_aabb(node: Node3D) -> AABB:
	if node is VisualInstance3D: return node.get_aabb()
	for child in node.get_children():
		if child is VisualInstance3D: return child.get_aabb()
	var parent = node.get_parent()
	if parent:
		if parent is VisualInstance3D: return parent.get_aabb()
		for sibling in parent.get_children():
			if sibling is VisualInstance3D: return sibling.get_aabb()
	return AABB(Vector3(-0.5,-0.5,-0.5), Vector3(1,1,1))
