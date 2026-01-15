extends Node

# --- MODUS WAHL ---
enum MenuMode {
	HAND_THUMBSTICK,  # Radial Menu an der Hand
	OBJECT_RAYCAST    # Halo Menu am Objekt
}

@export_group("Settings")
@export var is_enabled: bool = true
@export var mode: MenuMode = MenuMode.HAND_THUMBSTICK # <--- Hier Mode umschalten

@export_group("Scenes")
# JETZT KANNST DU BEIDES ZUWEISEN:
@export var hand_menu_scene: PackedScene # Ziehe hier RadialMenu3D.tscn rein
@export var halo_menu_scene: PackedScene # Ziehe hier ObjectHaloMenu.tscn rein

@export_group("Input")
@export var activation_button: String = "primary_click" # Hand-Mode: Öffnen (X)
@export var selection_button: String = "trigger_click" # Beides: Bestätigen
@export var menu_offset: Vector3 = Vector3(0, 0.2, 0) 
@export var shortcut_action: String = "Rotate"

# Interne Variablen
var manager: XRInteractionManager
var left_hand: XRController3D
var right_hand: XRController3D 
var raycast: RayCast3D         
var camera: Camera3D

var menu_instance: Node3D
var is_menu_open: bool = false
var _btn_was_pressed: bool = false
var _selection_btn_was_pressed: bool = false

# Für Raycast Modus
var current_hovered_button: Area3D = null


func setup(_manager, _fp, _right_controller, _raycast):
	manager = _manager
	raycast = _raycast          
	right_hand = _right_controller 
	
	left_hand = manager.left_controller
	if not left_hand:
		printerr("ERROR: Radial Menu needs Left Controller!")
		is_enabled = false
		return
	
	# Kamera sicher finden
	camera = manager.get_viewport().get_camera_3d()
	if not camera:
		# Fallback Suche
		camera = manager.get_parent().get_node_or_null("XROrigin3D/XRCamera3D")

	# --- AUTO-SELECTION DER SZENE ---
	var scene_to_load: PackedScene = null
	
	match mode:
		MenuMode.HAND_THUMBSTICK:
			scene_to_load = hand_menu_scene
		MenuMode.OBJECT_RAYCAST:
			scene_to_load = halo_menu_scene
	
	if scene_to_load:
		menu_instance = scene_to_load.instantiate()
		manager.add_child(menu_instance)
		menu_instance.visible = false
		print("Feature Menu: Loaded Scene for Mode ", MenuMode.keys()[mode])
		
		# Verbindung für Hand-Menü Signale (optional)
		if menu_instance.has_signal("option_selected"):
			menu_instance.option_selected.connect(_on_menu_option)
	else:
		printerr("ERROR: Keine Szene für den gewählten Modus zugewiesen!")

	# Signale für Objekt-Modus verbinden
	if mode == MenuMode.OBJECT_RAYCAST:
		manager.object_picked_up.connect(_on_object_picked)
		manager.object_dropped.connect(_on_object_dropped)

func _process(delta):
	if not is_enabled or not menu_instance:
		return

	# --- WEICHE JE NACH MODUS ---
	match mode:
		MenuMode.HAND_THUMBSTICK:
			_process_hand_mode()
		MenuMode.OBJECT_RAYCAST:
			_process_object_mode()

# --- LOGIK A: HAND MENU ---
func _process_hand_mode():
	if not left_hand: return

	# 1. Öffnen/Schließen (X-Taste)
	var is_act_pressed = left_hand.is_button_pressed(activation_button)
	if is_act_pressed and not _btn_was_pressed:
		if is_menu_open:
			_close_and_select() 
		else:
			force_open_menu()
	_btn_was_pressed = is_act_pressed

	# 2. Update & Input
	if is_menu_open:
		_update_menu_transform()
		_handle_thumbstick()
		
		# Bestätigen mit Trigger
		var is_sel_pressed = left_hand.is_button_pressed(selection_button)
		if is_sel_pressed and not _selection_btn_was_pressed:
			_close_and_select()
		_selection_btn_was_pressed = is_sel_pressed

# --- LOGIK B: OBJEKT HALO ---
func _process_object_mode():
	if not is_menu_open: return
	
	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	
	# Hover
	if current_hovered_button and current_hovered_button != collider:
		if current_hovered_button.has_method("set_highlight"):
			current_hovered_button.set_highlight(false)
		current_hovered_button = null
	
	if collider and collider.has_method("set_highlight"):
		if current_hovered_button != collider:
			current_hovered_button = collider
			current_hovered_button.set_highlight(true)
		
		# Klick (Rechte Hand Trigger)
		var is_click = right_hand.is_button_pressed(selection_button)
		if is_click and not _selection_btn_was_pressed:
			_execute_raycast_button(collider)
		_selection_btn_was_pressed = is_click
	else:
		_selection_btn_was_pressed = false

# --- EVENTS ---
func _on_object_picked(obj):
	printerr("jojojojojoooo")
	if mode != MenuMode.OBJECT_RAYCAST: return
	is_menu_open = true
	menu_instance.visible = true
	
	if menu_instance.has_method("open_menu_at"): # Aufruf für ObjectHaloMenu.gd
		
		menu_instance.open_menu_at(obj, camera)
	elif menu_instance.has_method("open_menu"): # Falls du den Namen angepasst hast
		menu_instance.open_menu(obj, camera)

func _on_object_dropped(_obj):
	if mode != MenuMode.OBJECT_RAYCAST: return
	is_menu_open = false
	menu_instance.visible = false
	if menu_instance.has_method("close_menu"):
		menu_instance.close_menu()

# --- HELPER ---
func force_open_menu():
	is_menu_open = true
	menu_instance.visible = true
	_update_menu_transform()

func _close_and_select():
	is_menu_open = false
	menu_instance.visible = false
	
	# Zugriff auf Variable im RadialMenu3D Script
	if "selected_index" in menu_instance:
		if menu_instance.selected_index != -1:
			menu_instance.confirm_selection()
		else:
			print("Shortcut Action: ", shortcut_action)
			if manager.has_method("execute_menu_action"):
				manager.execute_menu_action(shortcut_action)

func _update_menu_transform():
	# Nur für Hand-Menu relevant
	var target_pos = left_hand.global_position + (left_hand.global_transform.basis * menu_offset)
	menu_instance.global_position = target_pos
	menu_instance.look_at(camera.global_position, Vector3.UP)
	menu_instance.rotate_object_local(Vector3.UP, PI)

func _handle_thumbstick():
	var thumbstick = left_hand.get_vector2("primary")
	if menu_instance.has_method("update_input"):
		menu_instance.update_input(thumbstick)

func _on_menu_option(option_name: String):
	if manager.has_method("execute_menu_action"):
		manager.execute_menu_action(option_name)

func _execute_raycast_button(btn):
	if "action_name" in btn:
		print("Halo Action: ", btn.action_name)
		if manager.has_method("execute_menu_action"):
			manager.execute_menu_action(btn.action_name)
