extends Node3D
class_name XRInteractionManager

# --- EXPORTS: REFERENZEN ---
@export_group("References")
@export var fp: Node3D           
@export var controller: XRController3D 
@export var left_controller: XRController3D 
@export var radial_menu_feature: Node 

# --- EXPORTS: FEATURES ---
# Hier ziehst du deine Feature-Nodes rein!
@export_group("Features")
@export var feature_moving: Node    # Z.B. dein Feature_Grabber
@export var feature_scaling: Node   # Dein Feature_Scaler
@export var feature_rotating: Node  # Dein Feature für Rotation

# --- PUBLIC STATE ---
var held_object: Node3D = null
var raycast: RayCast3D
var active_mode: String = "None" # Welcher Modus ist gerade aktiv?

# --- SIGNALS ---
signal object_picked_up(obj)
signal object_dropped(obj)
signal object_deleted 

func _ready():
	print("DEBUG: XRInteractionManager gestartet")
	
	if fp and fp.has_node("RayCast"):
		raycast = fp.get_node("RayCast")
	
	if controller:
		if not controller.button_pressed.is_connected(_on_button_pressed):
			controller.button_pressed.connect(_on_button_pressed)
	
	# Features initialisieren
	for child in get_children():
		if child.has_method("setup"):
			child.setup(self, fp, controller, raycast)

func _on_button_pressed(action_name: String):
	if action_name == fp.active_button_action:
		# Prüfen, ob wir ein Objekt treffen
		var target = fp.last_target
		
		if target and is_instance_valid(target):
			# Objekt merken + Menü öffnen
			_select_object_and_open_menu(target)
		else:
			# Klick ins Leere -> Alles abwählen
			if held_object:
				_deselect_object()

# --- SELEKTION ---
func _select_object_and_open_menu(target: Node3D):
	held_object = target
	print("MANAGER: Selected ", held_object.name)
	
	# --- HIER IST DER FIX ---
	# Wir müssen sofort Bescheid sagen, damit das Halo Menü aufgehen kann.
	emit_signal("object_picked_up", held_object) 
	# ------------------------
	
	# Menü öffnen
	if radial_menu_feature and radial_menu_feature.has_method("force_open_menu"):
		radial_menu_feature.force_open_menu()

func _deselect_object():
	_drop() # Sicherstellen, dass nichts mehr physikalisch gehalten wird
	held_object = null
	active_mode = "None"
	_set_features_enabled(false, false, false) # Alle aus

# --- MENÜ LOGIK (STATE MACHINE) ---
func execute_menu_action(action: String):
	print("MANAGER: Switching Mode -> ", action)
	active_mode = action
	
	match action:
		"Move":
			# Nur Moving an, andere aus
			_set_features_enabled(true, false, false)
			_start_interaction()
			
		"Scale":
			# Nur Scaling an (Objekt bleibt an Ort und Stelle, wir skalieren mit Geste)
			_set_features_enabled(false, true, false)
			_start_interaction()
			
		"Rotate":
			# Nur Rotating an
			_set_features_enabled(false, false, true)
			_start_interaction()
			
		"Delete":
			_delete_held_object()
			
		"Reset":
			if held_object: held_object.scale = Vector3.ONE
			
		_:
			printerr("Unbekannter Modus: ", action)

# --- HELPER: FEATURES UMSCHALTEN ---
func _set_features_enabled(move: bool, scale: bool, rotate: bool):
	if feature_moving: 
		feature_moving.is_enabled = move
		# Falls das Script gerade lief, stoppen wir es sauber, wenn es deaktiviert wird
		if not move and feature_moving.has_method("_on_dropped"):
			feature_moving._on_dropped(null)

	if feature_scaling: 
		feature_scaling.is_enabled = scale
		if not scale and feature_scaling.has_method("_on_dropped"):
			feature_scaling._on_dropped(null)

	if feature_rotating: 
		feature_rotating.is_enabled = rotate
		if not rotate and feature_rotating.has_method("_on_dropped"):
			feature_rotating._on_dropped(null)

# --- START DER AKTION ---
func _start_interaction():
	if not held_object: return
	
	# Raycast Exception hinzufügen, damit wir nicht durch das Objekt durch strahlen
	raycast.add_exception(held_object)
	
	if held_object is RigidBody3D:
		held_object.freeze = true
	
	# Signal senden: "Es geht los!"
	# Da die Features jetzt 'is_enabled' korrekt gesetzt haben,
	# reagiert nur das Feature, das true ist.
	emit_signal("object_picked_up", held_object)

# --- DROP / CLEANUP ---
func _drop():
	if held_object:
		raycast.remove_exception(held_object)
		if held_object is RigidBody3D:
			held_object.freeze = false
			held_object.linear_velocity = Vector3.ZERO
		
		var obj_ref = held_object
		# Signal senden zum Stoppen aller Features
		emit_signal("object_dropped", obj_ref)

func _delete_held_object():
	if held_object:
		var obj = held_object
		_drop()
		obj.queue_free()
		emit_signal("object_deleted")
