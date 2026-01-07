extends Node

@export var is_enabled: bool = true
@export var menu_scene: PackedScene 
# "primary_click" ist oft der Stick-Klick. 
# Besser wäre "ax_button" (X-Taste) oder "by_button" (Y-Taste), probiere es aus!
@export var activation_button: String = "primary_click" 
@export var menu_offset: Vector3 = Vector3(0, 0.2, 0) # 20cm über der Hand

var manager: XRInteractionManager
var left_hand: XRController3D
var camera: XRCamera3D

var menu_instance: Node3D
var is_menu_open: bool = false
var _btn_was_pressed: bool = false # Hilfsvariable für sauberes Klicken

func setup(_manager, _fp, _right_controller, _raycast):
	manager = _manager
	
	# 1. Linke Hand holen
	left_hand = manager.left_controller
	if not left_hand:
		printerr("ERROR: Radial Menu needs Left Controller!")
		is_enabled = false
		return
	
	# 2. Kamera finden (für "Look At")
	var origin = manager.get_parent().get_parent() 
	if origin:
		
		camera = origin.get_node_or_null("XRCamera3D")
		printerr(camera)
	
	# 3. Menü instanziieren
	if menu_scene:
		menu_instance = menu_scene.instantiate()
		manager.add_child(menu_instance)
		menu_instance.visible = false
		
		if menu_instance.has_signal("option_selected"):
			menu_instance.option_selected.connect(_on_menu_option)

func _process(delta):
	if not is_enabled or not left_hand or not menu_instance:
		return
		
	# --- 1. BUTTON TOGGLE LOGIK (AN / AUS) ---
	# Wir prüfen, ob der Knopf gedrückt ist (z.B. Stick rein drücken)
	var is_pressed = left_hand.is_button_pressed(activation_button)
	
	# Logik: Nur reagieren, wenn der Knopf FRISCH gedrückt wurde (nicht gehalten)
	if is_pressed and not _btn_was_pressed:
		if is_menu_open:
			_close_and_select()
		else:
			force_open_menu()
	
	_btn_was_pressed = is_pressed # Zustand merken für nächsten Frame

	# --- 2. UPDATE LOOP (WICHTIG!) ---
	if is_menu_open:
		# Hier updaten wir JEDEN Frame die Position
		_update_menu_transform()
		_handle_thumbstick()

# Öffentliche Funktion (kann auch vom Manager aufgerufen werden)
func force_open_menu():
	if not is_enabled or not menu_instance: return
	
	is_menu_open = true
	menu_instance.visible = true
	
	# Sofort einmal positionieren, damit es nicht kurz woanders aufblitzt
	_update_menu_transform()

func _close_and_select():
	is_menu_open = false
	menu_instance.visible = false
	
	# Befehl ausführen
	if menu_instance.has_method("confirm_selection"):
		menu_instance.confirm_selection()

func _update_menu_transform():
	# 1. Position relativ zur linken Hand setzen
	# Wir nehmen die Rotation der Hand (basis) mal den Offset, damit "oben" auch "oben auf der Hand" ist
	var target_pos = left_hand.global_position + (left_hand.global_transform.basis * menu_offset)
	
	# Wir nutzen 'lerp' für eine weiche Bewegung, oder setzen es direkt
	# Direkt setzen ist besser, damit es nicht hinterherhinkt:
	menu_instance.global_position = target_pos
	
	# 2. Das Menü soll zum Spieler schauen
	if camera:
		printerr('camera found')
		menu_instance.look_at(camera.global_position, Vector3.UP)
		# Falls das Menü falsch herum ist (Rückseite), hier einkommentieren:
		# menu_instance.rotate_object_local(Vector3.UP, PI) 

func _handle_thumbstick():
	# Stick-Eingabe an das Visual-Skript weitergeben
	var thumbstick = left_hand.get_vector2("primary_2d_axis")
	if menu_instance.has_method("update_input"):
		menu_instance.update_input(thumbstick)

func _on_menu_option(option_name: String):
	print("MENU SELECTED: ", option_name)
	# Befehl an Manager weiterleiten
	if manager.has_method("execute_menu_action"):
		manager.execute_menu_action(option_name)
