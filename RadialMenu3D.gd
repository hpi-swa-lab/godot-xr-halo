@tool
extends Node3D

signal option_selected(option_name)

# --- KONFIGURATION (Daten) ---
# Wir nutzen zwei Listen statt einer externen Klasse. 
# WICHTIG: Achte darauf, dass beide Listen gleich lang sind!
@export var option_ids: Array[String] = ["Move", "Scale", "Delete", "Reset"]
@export var option_icons: Array[Texture2D]

# --- KONFIGURATION (Optik) ---
@export_group("Visuals")
@export var outer_radius: float = 0.15
@export var inner_radius: float = 0.05
@export var color_normal: Color = Color(0.2, 0.2, 0.2, 0.8)
@export var color_hover: Color = Color(1.0, 0.0, 0.0, 0.8)
@export var icon_scale: float = 0.001 # Größe der Icons anpassen

# --- INTERNE VARIABLEN ---
var slices: Array[MeshInstance3D] = []
var selected_index: int = -1

func _ready():
	# Einmaliges Generieren beim Start
	generate_menu()

func _process(_delta):
	# Erlaubt Live-Updates im Editor, wenn du Werte änderst
	if Engine.is_editor_hint():
		# Kleiner Hack, damit er nicht jeden Frame neu baut, sondern nur bei Änderungen
		# Für Produktion ok, solange wir nicht ständig properties ändern
		pass

# --- GENERIERUNG ---
func generate_menu():
	# Alte Slices löschen
	for s in slices: 
		if is_instance_valid(s): s.queue_free()
	slices.clear()
	
	var count = option_ids.size()
	if count == 0: return
	
	var angle_per_slice = TAU / count
	
	for i in range(count):
		var start_angle = i * angle_per_slice
		var end_angle = (i + 1) * angle_per_slice
		
		# 1. Mesh erstellen
		var slice_mesh = _create_slice_mesh(start_angle, end_angle)
		
		# 2. Node erstellen
		var slice_obj = MeshInstance3D.new()
		slice_obj.mesh = slice_mesh
		slice_obj.name = "Slice_" + option_ids[i]
		
		# 3. Material
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_normal
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED # Zeigt Vorder- und Rückseite
		slice_obj.material_override = mat
		
		add_child(slice_obj)
		slices.append(slice_obj)
		
		# 4. Icon hinzufügen (Falls vorhanden)
		if i < option_icons.size() and option_icons[i] != null:
			_add_icon(slice_obj, start_angle, end_angle, option_icons[i])

func _create_slice_mesh(start_angle, end_angle) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var steps = 16 
	
	for s in range(steps):
		var t1 = float(s) / steps
		var t2 = float(s + 1) / steps
		
		var a1 = lerp(start_angle, end_angle, t1)
		var a2 = lerp(start_angle, end_angle, t2)
		
		# Koordinaten berechnen (Z-Achse ist 0, wir bauen flach auf XY)
		var v_in_1 = Vector3(cos(a1) * inner_radius, sin(a1) * inner_radius, 0)
		var v_out_1 = Vector3(cos(a1) * outer_radius, sin(a1) * outer_radius, 0)
		var v_in_2 = Vector3(cos(a2) * inner_radius, sin(a2) * inner_radius, 0)
		var v_out_2 = Vector3(cos(a2) * outer_radius, sin(a2) * outer_radius, 0)
		
		# Normals für korrekte Beleuchtung
		st.set_normal(Vector3(0, 0, 1))
		
		# Dreieck 1
		st.add_vertex(v_in_1)
		st.add_vertex(v_out_1)
		st.add_vertex(v_in_2)
		
		# Dreieck 2
		st.add_vertex(v_out_1)
		st.add_vertex(v_out_2)
		st.add_vertex(v_in_2)
		
	return st.commit()

func _add_icon(parent, start, end, texture):
	var mid_angle = (start + end) / 2.0
	var mid_radius = (inner_radius + outer_radius) / 2.0
	
	var sprite = Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = icon_scale
	sprite.render_priority = 1 # Über dem Mesh zeichnen
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED # Flach auf dem Menü liegen
	
	# Position berechnen
	var pos = Vector3(cos(mid_angle) * mid_radius, sin(mid_angle) * mid_radius, 0.01)
	sprite.position = pos
	
	# Rotation korrigieren, damit Icon nicht auf dem Kopf steht
	# Wir rotieren das Icon um seine Z-Achse entgegengesetzt zum Winkel + 90 Grad Korrektur
	sprite.rotation.z = mid_angle - (PI/2) 
	
	parent.add_child(sprite)

# --- INPUT & LOGIK ---

func update_input(joystick_vector: Vector2):
	# Deadzone
	if joystick_vector.length() < 0.2:
		selected_index = -1
		_update_selection_visuals()
		return
		
	# Winkel berechnen
	var angle = joystick_vector.angle()
	if angle < 0: angle += TAU
	
	var count = option_ids.size()
	if count == 0: return
	
	var angle_per_slice = TAU / count
	selected_index = int(angle / angle_per_slice) % count
	
	_update_selection_visuals()

func _update_selection_visuals():
	for i in range(slices.size()):
		var mat = slices[i].material_override
		if i == selected_index:
			mat.albedo_color = color_hover
			slices[i].scale = Vector3(1.1, 1.1, 1.1)
		else:
			mat.albedo_color = color_normal
			slices[i].scale = Vector3(1.0, 1.0, 1.0)

func confirm_selection():
	if selected_index >= 0 and selected_index < option_ids.size():
		emit_signal("option_selected", option_ids[selected_index])
		# Optional: Menü sofort ausblenden?
		# visible = false
