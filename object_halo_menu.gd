extends Node3D

@export var buttons: Array[Area3D] # Ziehe hier deine Button-Instanzen rein!

var target_object: Node3D
var camera: Node3D
var world_radius: float = 0.5
var is_active: bool = false

func open_menu_at(obj: Node3D, _camera: Node3D):
	target_object = obj
	camera = _camera
	is_active = true
	visible = true
	
	# --- FIX START: Robuste Größenberechnung ---
	
	# Wir rufen eine Hilfsfunktion auf, die nach einem Mesh sucht
	var aabb = _find_visual_aabb(target_object)
	
	# Skalierung des Objekts berücksichtigen (falls Parent skaliert ist)
	var world_size = aabb.size * target_object.scale
	var max_dim = max(world_size.x, max(world_size.y, world_size.z))
	
	# Fallback: Wenn das Objekt winzig ist (0), nehmen wir einen Standardwert
	if max_dim < 0.1: max_dim = 0.5
	
	world_radius = (max_dim / 2.0) + 0.25 
	
	# --- FIX ENDE ---
	
	# Buttons einmalig platzieren (optional auch in process)
	_update_button_positions(1.0) # Startwert

# --- NEUE HILFSFUNKTION ---
func _find_visual_aabb(node: Node3D) -> AABB:
	# 1. Ist der Node selbst ein Mesh? (z.B. MeshInstance3D)
	if node is VisualInstance3D:
		return node.get_aabb()
	
	# 2. Hat der Node Kinder, die Meshes sind?
	for child in node.get_children():
		if child is VisualInstance3D:
			return child.get_aabb()
			
	# 3. Ist der Node Teil einer Gruppe (z.B. InteractableArea unter einem RigidBody)?
	# Wir schauen beim "Vater" (Parent) nach Geschwistern.
	var parent = node.get_parent()
	if parent:
		# Ist der Vater selbst das Mesh?
		if parent is VisualInstance3D:
			return parent.get_aabb()
		
		# Hat der Vater ein anderes Kind, das ein Mesh ist?
		for sibling in parent.get_children():
			if sibling is VisualInstance3D:
				return sibling.get_aabb()

	# 4. Fallback: Nichts gefunden? Wir geben eine Standard-Box zurück (Größe 1x1x1)
	# Das verhindert den Crash.
	print("WARNUNG: Kein Mesh für AABB gefunden bei: ", node.name, " - Nutze Standardgröße.")
	return AABB(Vector3(-0.5, -0.5, -0.5), Vector3(1, 1, 1))
	
	
func close_menu():
	is_active = false
	visible = false
	target_object = null

func _process(_delta):
	if not is_active or not target_object or not camera:
		return

	# A. Position: Menü klebt am Objekt
	global_position = target_object.global_position
	
	# B. Ausrichtung: Billboard (Z-Achse zeigt zur Kamera)
	look_at(camera.global_position, Vector3.UP)
	
	# C. Konstante Bildschirmgröße (Screen Size Scaling)
	# Damit das Menü lesbar bleibt, auch wenn man weit weg ist.
	var dist = global_position.distance_to(camera.global_position)
	var display_scale = clamp(dist * 0.3, 0.5, 5.0) # Nicht zu klein, nicht zu riesig
	scale = Vector3.ONE * display_scale
	
	# D. Button-Anordnung korrigieren
	# Da wir den Parent skalieren (C), müssen wir die lokale Position der Buttons anpassen,
	# damit der "Welt-Radius" (world_radius) korrekt eingehalten wird.
	_update_button_positions(display_scale)

func _update_button_positions(current_scale: float):
	if buttons.size() == 0: return
	
	var angle_step = (2 * PI) / buttons.size()
	
	# Der lokale Radius muss durch den Scale geteilt werden, um im Welt-Raum gleich zu bleiben
	var local_radius = world_radius / current_scale
	
	for i in range(buttons.size()):
		var btn = buttons[i]
		# Start bei 90 Grad (oben)
		var angle = i * angle_step + (PI / 2) 
		
		# Position im Kreis (lokale X/Y Ebene wegen look_at)
		var x = cos(angle) * local_radius
		var y = sin(angle) * local_radius
		
		btn.position = Vector3(x, y, 0)
		btn.rotation = Vector3.ZERO # Buttons gerade halten
