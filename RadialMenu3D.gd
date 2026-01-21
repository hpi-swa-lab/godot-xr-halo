@tool
extends Node3D

signal option_selected(option_name)

# --- KONFIGURATION (Daten) ---
@export var option_ids: Array[String] = ["Move", "Scale", "Rotate", "Reset"]
@export var option_icons: Array[Texture2D]

# --- KONFIGURATION (Optik) ---
@export_group("Visuals")
@export var outer_radius: float = 0.15
@export var inner_radius: float = 0.05
@export var color_normal: Color = Color(0.1, 0.1, 0.1, 0.5) 
@export var color_hover: Color = Color(1.0, 0.2, 0.2, 0.9) 
@export_range(0.00001, 0.01, 0.00001, "or_greater") var icon_scale: float = 0.0005
@export var icon_rotation_offset: Vector3 = Vector3(-90, 0, 0) # Standard flachliegend
# --- KONFIGURATION (Audio) ---
@export_group("Audio")
@export var sound_error: AudioStream # <--- ZIEHE HIER DEINEN SOUND REIN



# --- INTERNE VARIABLEN ---
var slices: Array[MeshInstance3D] = []
var selected_index: int = -1
var audio_player: AudioStreamPlayer3D
var center_sprite: Sprite3D

func _ready():
	# 1. Audio Player erstellen (wie vorher)
	audio_player = AudioStreamPlayer3D.new()
	add_child(audio_player)
	
	# 2. NEU: Center Icon erstellen
	center_sprite = Sprite3D.new()
	center_sprite.pixel_size = icon_scale * 1.5 # Etwas größer als die normalen Icons
	center_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED # Flach auf der Hand
	center_sprite.no_depth_test = true # Immer sichtbar
	center_sprite.render_priority = 2 # Über allem anderen
	center_sprite.visible = false # Erstmal verstecken
	# Rotation korrigieren (damit es flach liegt)
	center_sprite.rotation_degrees.x = -90 
	add_child(center_sprite)
	
	generate_menu()

func _process(_delta):
	if Engine.is_editor_hint():
		pass

# --- GENERIERUNG ---
func generate_menu():
	for s in slices: 
		if is_instance_valid(s): s.queue_free()
	slices.clear()
	
	var count = option_ids.size()
	if count == 0: return
	
	var angle_per_slice = TAU / count
	
	for i in range(count):
		var start_angle = i * angle_per_slice
		var end_angle = (i + 1) * angle_per_slice
		
		# 1. Mesh
		var slice_mesh = _create_slice_mesh(start_angle, end_angle)
		
		# 2. Node
		var slice_obj = MeshInstance3D.new()
		slice_obj.mesh = slice_mesh
		slice_obj.name = "Slice_" + option_ids[i]
		
		# 3. Material (Unshaded)
		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color_normal
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		slice_obj.material_override = mat
		
		add_child(slice_obj)
		slices.append(slice_obj)
		
		# 4. Icon
		if i < option_icons.size() and option_icons[i] != null:
			_add_icon(slice_obj, start_angle, end_angle, option_icons[i])

func _create_slice_mesh(start_angle, end_angle) -> ArrayMesh:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps = 32 
	for s in range(steps):
		var t1 = float(s) / steps
		var t2 = float(s + 1) / steps
		var a1 = lerp(start_angle, end_angle, t1)
		var a2 = lerp(start_angle, end_angle, t2)
		
		var v_in_1 = Vector3(cos(a1) * inner_radius, sin(a1) * inner_radius, 0)
		var v_out_1 = Vector3(cos(a1) * outer_radius, sin(a1) * outer_radius, 0)
		var v_in_2 = Vector3(cos(a2) * inner_radius, sin(a2) * inner_radius, 0)
		var v_out_2 = Vector3(cos(a2) * outer_radius, sin(a2) * outer_radius, 0)
		
		st.set_normal(Vector3(0, 0, 1))
		st.add_vertex(v_in_1); st.add_vertex(v_out_1); st.add_vertex(v_in_2)
		st.add_vertex(v_out_1); st.add_vertex(v_out_2); st.add_vertex(v_in_2)
	return st.commit()

func _add_icon(parent, start, end, texture):
	var mid_angle = (start + end) / 2.0
	var mid_radius = (inner_radius + outer_radius) / 2.0
	var sprite = Sprite3D.new()
	sprite.texture = texture
	sprite.pixel_size = icon_scale
	sprite.render_priority = 1
	sprite.no_depth_test = true
	sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	
	var pos = Vector3(cos(mid_angle) * mid_radius, sin(mid_angle) * mid_radius, 0.002)
	sprite.position = pos
	sprite.rotation.z = mid_angle - (PI/2) 
	sprite.modulate = Color(1, 1, 1, 1)
	parent.add_child(sprite)

# --- INPUT & LOGIK ---
func update_input(joystick_vector: Vector2):
	if joystick_vector.length() < 0.2:
		if selected_index != -1:
			selected_index = -1
			_update_selection_visuals()
		return
	var angle = joystick_vector.angle()
	if angle < 0: angle += TAU
	var count = option_ids.size()
	if count == 0: return
	var angle_per_slice = TAU / count
	var raw_index = int(angle / angle_per_slice) % count
	if selected_index != raw_index:
		selected_index = raw_index
		_update_selection_visuals()

func _update_selection_visuals():
	for i in range(slices.size()):
		var slice = slices[i]
		var mat = slice.material_override
		if i == selected_index:
			mat.albedo_color = color_hover
			slice.scale = Vector3(1.1, 1.1, 1.1)
			slice.position.z = 0.001
		else:
			mat.albedo_color = color_normal
			slice.scale = Vector3(1.0, 1.0, 1.0)
			slice.position.z = 0.0

func confirm_selection():
	if selected_index >= 0 and selected_index < option_ids.size():
		var selected_name = option_ids[selected_index]
		
		# --- SOUND CHECK ---
		if selected_name == "Reset":
			if sound_error:
				audio_player.stream = sound_error
				audio_player.play()
			else:
				print("WARNUNG: Kein Error-Sound im Inspector zugewiesen!")
		
		# Signal senden
		emit_signal("option_selected", selected_name)
		
func show_menu_view():
	center_sprite.visible = false
	for s in slices:
		s.visible = true

# Rufe dies auf, um nur das aktive Icon anzuzeigen
func show_active_icon_view(icon_name: String):
	# 1. Icon finden
	var idx = option_ids.find(icon_name)
	if idx != -1 and idx < option_icons.size():
		center_sprite.texture = option_icons[idx]
		
		# Rotation anwenden (aus dem Inspector)
		center_sprite.rotation_degrees = icon_rotation_offset
		
		## Optional: Einfärben
		#match icon_name:
			#"Move": center_sprite.modulate = Color(0,1,0)
			#"Scale": center_sprite.modulate = Color(0,0.5,1)
			#"Rotate": center_sprite.modulate = Color(1,1,0)
			#"Delete": center_sprite.modulate = Color(1,0,0)
			#_: center_sprite.modulate = Color(1,1,1)
			
		center_sprite.visible = true
		
		# Slices verstecken
		for s in slices:
			s.visible = false
	else:
		show_menu_view()
