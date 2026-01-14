extends Node
#
#@export var is_enabled: bool = true
#@export var menu_scene: PackedScene 
#@export var activation_button: String = "primary_click" 
#@export var menu_offset: Vector3 = Vector3(0, 0.2, 0) 
#@export var shortcut_action: String = "Rotate"
#@export var selection_button: String = "trigger_click" 
#
#var _selection_btn_was_pressed: bool = false # Damit wir nicht dauerfeuern
#var manager: XRInteractionManager
#var left_hand: XRController3D
#var camera: Camera3D
#
#var menu_instance: Node3D
#var is_menu_open: bool = false
#var _btn_was_pressed: bool = false # Hilfsvariable für sauberes Klicken
#
#func setup(_manager, _fp, _right_controller, _raycast):
	#manager = _manager
	#
	## 1. Linke Hand holen
	#left_hand = manager.left_controller
	#if not left_hand:
		#printerr("ERROR: Radial Menu needs Left Controller!")
		#is_enabled = false
		#return
	#
	#
	#camera = manager.get_parent().get_node("XROrigin3D").get_node("XRCamera3D")
#
	#if camera:
		#print("RadialMenu: XRCamera3D gefunden -> ", camera.name)
	#else:
		#printerr("CRITICAL ERROR: XRCamera3D nicht gefunden! Prüfe Namen im Szenenbaum.")
	## 3. Menü instanziieren
	#if menu_scene:
		#menu_instance = menu_scene.instantiate()
		#manager.add_child(menu_instance)
		#menu_instance.visible = false
		#
		#if menu_instance.has_signal("option_selected"):
			#menu_instance.option_selected.connect(_on_menu_option)
#
#func _process(delta):
	#if not is_enabled or not left_hand or not menu_instance:
		#return
		#
	## 1. MENÜ ÖFFNEN / SCHLIESSEN (Toggle mit X-Taste)
	#var is_act_pressed = left_hand.is_button_pressed(activation_button)
	#if is_act_pressed and not _btn_was_pressed:
		#if is_menu_open:
			## Optional: Menü nur schließen ohne Auswahl? 
			## Oder auch hier auswählen? Das hängt von deinem Geschmack ab.
			#_close_and_select() 
		#else:
			#force_open_menu()
	#_btn_was_pressed = is_act_pressed
#
	## 2. UPDATE & SELEKTION (Nur wenn Menü offen)
	#if is_menu_open:
		#_update_menu_transform()
		#_handle_thumbstick()
		#
		## --- NEU: BESTÄTIGEN MIT TRIGGER ---
		#var is_sel_pressed = left_hand.is_button_pressed(selection_button)
		#
		## Wir reagieren nur auf den frischen Klick (Flanke)
		#if is_sel_pressed and not _selection_btn_was_pressed:
			#print("Selection Button pressed -> Confirming!")
			#_close_and_select()
			#
		#_selection_btn_was_pressed = is_sel_pressed
## Öffentliche Funktion (kann auch vom Manager aufgerufen werden)
#func force_open_menu():
	#if not is_enabled or not menu_instance: return
	#
	#is_menu_open = true
	#menu_instance.visible = true
	#
	## Sofort einmal positionieren, damit es nicht kurz woanders aufblitzt
	#_update_menu_transform()
#
#func _close_and_select():
	#is_menu_open = false
	#menu_instance.visible = false
	#
	## Hier ist die neue Logik:
	## Wir greifen auf die Variable 'selected_index' im RadialMenu3D Skript zu.
	## -1 bedeutet: Der Stick ist in der Mitte (nichts ausgewählt).
	#
	#if menu_instance.selected_index != -1:
		## Fall A: Der Spieler hat etwas mit dem Stick ausgewählt
		#menu_instance.confirm_selection()
	#else:
		## Fall B: Nichts ausgewählt -> Wir erzwingen "Move" (Dein Test-Wunsch)
		#print("Keine Auswahl am Stick -> Nutze Shortcut: ", shortcut_action)
		#if manager.has_method("execute_menu_action"):
			#manager.execute_menu_action(shortcut_action)
#
#func _update_menu_transform():
	#if not left_hand or not camera: return
#
	## 1. POSITION: Relativ zur Hand (wie bisher)
	## Wir nutzen global_transform der Hand, damit der Offset sich mitdreht
	#var target_pos = left_hand.global_position + (left_hand.global_transform.basis * menu_offset)
	#menu_instance.global_position = target_pos
	#
	## 2. ROTATION: Anschauen der Kamera (Billboard-Effekt)
	## Wir nutzen look_at, damit die -Z Achse zur Kamera zeigt
	#menu_instance.look_at(camera.global_position, Vector3.UP)
	#
	## 3. KORREKTUR (Der wichtige Teil!)
	## Da look_at die Rückseite (-Z) ausrichtet, und unser Mesh wahrscheinlich vorne (+Z) ist,
	## müssen wir es einmal um 180 Grad (PI) um die Y-Achse drehen.
	#menu_instance.rotate_object_local(Vector3.UP, PI)
	#
	#
#func _handle_thumbstick():
	#if not left_hand: 
		#print("ERROR: Linke Hand fehlt!")
		#return
#
	## Wir holen den Input primary_2d_axis
	#var thumbstick = left_hand.get_vector2("primary")
	#
	## DEBUG: Wir spammen kurz die Konsole voll, um zu sehen, ob Zahlen ankommen
	#if thumbstick.length() > 0.01:
		#print("INPUT DETECTED: ", thumbstick)
	#else:
		## Optional: Um zu sehen, ob es NULL ist oder (0,0)
		#pass 
#
	## Weitergabe an das Menü
	#if menu_instance and menu_instance.has_method("update_input"):
		#menu_instance.update_input(thumbstick)
#
#func _on_menu_option(option_name: String):
	#print("MENU SELECTED: ", option_name)
	## Befehl an Manager weiterleiten
	#if manager.has_method("execute_menu_action"):
		#manager.execute_menu_action(option_name)
