extends Node3D

# ZIEHE HIER DEINE BUTTONS IM INSPECTOR REIN!
@export var buttons: Array[Area3D] 

var target_object: Node3D
var camera: Node3D
var world_radius: float = 0.5
var is_active: bool = false

# Diese Funktion wird vom Feature_RadialMenu aufgerufen
func open_menu_at(obj: Node3D, _camera: Node3D):
	print("HALO: Öffne Menü an Objekt: ", obj.name)
	target_object = obj
	camera = _camera
	is_active = true
	visible = true
	
	# 1. Größe des Objekts ermitteln (mit Fallback)
	var aabb = _find_visual_aabb(target_object)
	var world_size = aabb.size * target_object.scale
	# Wir nehmen die größte Seite des Objekts
	var max_dim = max(world_size.x, max(world_size.y, world_size.z))
	
	# Sicherheits-Check: Wenn 0 rauskommt, nehmen wir 0.5m
	if max_dim < 0.1: max_dim = 0.5
	
	# Radius = Halbe Objektgröße + 20cm Abstand
	world_radius = (max_dim / 2.0) + 0.20
	print("HALO: Berechneter Radius: ", world_radius)
	
	# Sofort einmal updaten
	_update_menu_visuals()

func close_menu():
	is_active = false
	visible = false
	target_object = null

func _process(_delta):
	if not is_active or not target_object or not camera: return
	_update_menu_visuals()

func _update_menu_visuals():
	# A. Position: Menü folgt dem Objekt
	global_position = target_object.global_position
	
	# B. Rotation: Billboard (Schaut immer zur Kamera)
	look_at(camera.global_position, Vector3.UP)
	
	# C. Scale: Bleibt in der Ferne lesbar
	var dist = global_position.distance_to(camera.global_position)
	var display_scale = clamp(dist * 0.4, 0.5, 3.0) 
	scale = Vector3.ONE * display_scale
	
	# D. Button Anordnung (Der wichtigste Teil!)
	if buttons.size() == 0:
		print("ERROR: Keine Buttons im 'buttons' Array zugewiesen!")
		return

	# Wir rechnen den Scale raus, damit der Kreis in der Welt stabil bleibt
	var local_radius = world_radius / display_scale
	var angle_step = (2 * PI) / buttons.size()
	
	for i in range(buttons.size()):
		var btn = buttons[i]
		# Start oben (90 Grad / PI/2)
		var angle = i * angle_step + (PI / 2) 
		
		# Position im Kreis berechnen (lokal X/Y)
		var x = cos(angle) * local_radius
		var y = sin(angle) * local_radius
		
		btn.position = Vector3(x, y, 0)
		btn.rotation = Vector3.ZERO

# Hilfsfunktion, um Mesh-Größe zu finden (verhindert Crash bei Area3D)
func _find_visual_aabb(node: Node3D) -> AABB:
	if node is VisualInstance3D: return node.get_aabb()
	for child in node.get_children():
		if child is VisualInstance3D: return child.get_aabb()
	var parent = node.get_parent()
	if parent:
		if parent is VisualInstance3D: return parent.get_aabb()
		for sibling in parent.get_children():
			if sibling is VisualInstance3D: return sibling.get_aabb()
	# Fallback Box
	return AABB(Vector3(-0.5,-0.5,-0.5), Vector3(1,1,1))
