extends Node3D
class_name XRInteractionManager

# --- EXPORTS ---
@export var fp: Node3D           # FunctionPointer (Rechts)
@export var controller: XRController3D 
@export var left_controller: XRController3D 

# NEU: Referenz zum RadialMenu Feature (damit wir es öffnen können)
# ZIEHE HIER DEIN 'Feature_RadialMenu' Node im Inspector rein!
@export var radial_menu_feature: Node 

# --- PUBLIC STATE ---
var held_object: Node3D = null
var raycast: RayCast3D
var vent: bool = false

# --- SIGNALS ---
signal object_picked_up(obj)
signal object_dropped(obj)
signal object_deleted 

func _ready():
	print("DEBUG: XRInteractionManager gestartet")
	
	if fp and fp.has_node("RayCast"):
		raycast = fp.get_node("RayCast")
	else:
		printerr("CRITICAL ERROR: RayCast im FunctionPointer nicht gefunden!")
		return

	if controller:
		if not controller.button_pressed.is_connected(_on_button_pressed):
			controller.button_pressed.connect(_on_button_pressed)
	
	if not left_controller:
		printerr("WARNUNG: Linker Controller im InteractionManager nicht zugewiesen!")

	# Features initialisieren
	for child in get_children():
		if child.has_method("setup"):
			child.setup(self, fp, controller, raycast)

func _on_button_pressed(action_name: String):
	if action_name == fp.active_button_action:
		# LOGIK GEÄNDERT: Klick = Selektieren & Menü öffnen
		
		# 1. Prüfen, ob wir ein Objekt anvisieren
		var target = fp.last_target
		
		if target and is_instance_valid(target):
			# Wenn wir ein neues Objekt treffen -> Selektieren & Menü auf
			_select_object_and_open_menu(target)
		else:
			# Klick ins Leere -> Aktuelles Objekt abwählen (falls gewünscht)
			if held_object:
				_deselect_object()

# --- NEUE LOGIK: SELEKTIEREN ---
func _select_object_and_open_menu(target: Node3D):
	# Wir merken uns das Objekt, ABER wir starten noch keine Physik/Grabber
	held_object = target
	print("MANAGER: Object selected (Waiting for Menu): ", held_object.name)
	
	# Menü auf der linken Hand öffnen
	if radial_menu_feature and radial_menu_feature.has_method("force_open_menu"):
		radial_menu_feature.force_open_menu()
	else:
		printerr("WARNUNG: RadialMenuFeature nicht zugewiesen oder force_open_menu fehlt!")

func _deselect_object():
	# Einfach Auswahl löschen
	print("MANAGER: Deselected object")
	held_object = null

# --- MENÜ BEFEHLE (Wird vom Feature_RadialMenu aufgerufen) ---
func execute_menu_action(action: String):
	print("MANAGER: Menu Action -> ", action)
	
	match action:
		"Move":
			# JETZT starten wir das eigentliche Greifen
			if held_object:
				_start_physical_grab(held_object)
		"Delete":
			_delete_held_object()
		"Reset":
			_reset_held_object_scale()
		"Drop":
			_drop()
		_:
			printerr("Unbekannte Menu-Aktion: ", action)

# --- INTERNE LOGIK (Physik & Features) ---

func _start_physical_grab(obj):
	# Das ist deine alte "_try_pickup" Logik
	# Wird jetzt erst ausgeführt, wenn man "Move" klickt
	raycast.add_exception(obj)
	
	if obj is RigidBody3D:
		obj.freeze = true
		
	print("MANAGER: Physical Grab started for ", obj.name)
	# Dieses Signal weckt den 'Feature_Grabber' auf
	emit_signal("object_picked_up", obj)

func _drop():
	if held_object:
		print("MANAGER: Dropped ", held_object.name)
		raycast.remove_exception(held_object)
		
		if held_object is RigidBody3D:
			held_object.freeze = false
			held_object.linear_velocity = Vector3.ZERO
		
		var obj_ref = held_object
		held_object = null
		
		# Dieses Signal stoppt den 'Feature_Grabber'
		emit_signal("object_dropped", obj_ref)

func _delete_held_object():
	if held_object:
		var obj = held_object
		# Erst sauber droppen (damit Raycast Exception weg ist)
		if raycast: raycast.remove_exception(obj)
		held_object = null
		emit_signal("object_dropped", obj) # Features stoppen
		
		# Dann löschen
		obj.queue_free()
		emit_signal("object_deleted")

func _reset_held_object_scale():
	if held_object:
		held_object.scale = Vector3.ONE

func venti():
	vent = true
