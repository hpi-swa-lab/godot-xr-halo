extends Node

@export var is_enabled: bool = true
@export var menu_scene: PackedScene 
@export var activation_button: String = "trigger_click"

var manager: XRInteractionManager
var raycast: RayCast3D
var controller: XRController3D

var menu_instance: Node3D 
var current_hovered_button: Area3D = null
var _btn_was_pressed = false

func _ready():
	print("DEBUG_HALO: Feature Script geladen.")

func setup(_manager, _fp, _controller, _raycast):
	print("DEBUG_HALO: Setup gestartet...")
	manager = _manager
	raycast = _raycast
	controller = _controller
	
	if menu_scene:
		menu_instance = menu_scene.instantiate()
		manager.get_parent().add_child(menu_instance)
		menu_instance.visible = false
		print("DEBUG_HALO: Menu Scene erfolgreich instanziiert.")
	else:
		printerr("ERROR_HALO: Keine 'Menu Scene' im Inspector zugewiesen!")
		return

	if not manager.object_picked_up.is_connected(_on_object_selected):
		manager.object_picked_up.connect(_on_object_selected)
		print("DEBUG_HALO: Signal 'object_picked_up' verbunden.")
	
	if not manager.object_dropped.is_connected(_on_object_deselected):
		manager.object_dropped.connect(_on_object_deselected)

func _on_object_selected(obj):
	print("DEBUG_HALO: Signal empfangen! Objekt selektiert: ", obj.name)
	
	if not is_enabled: 
		print("DEBUG_HALO: Abbruch - Feature ist disabled.")
		return
	
	if not menu_instance:
		print("DEBUG_HALO: Abbruch - Menu Instance fehlt.")
		return
	
	var cam = manager.get_viewport().get_camera_3d()
	if not cam:
		print("DEBUG_HALO: WARNUNG - Keine Kamera gefunden!")
	
	if menu_instance.has_method("open_menu_at"):
		print("DEBUG_HALO: Öffne Menü am Objekt...")
		menu_instance.open_menu_at(obj, cam)
	else:
		printerr("ERROR_HALO: Menu Scene hat keine Funktion 'open_menu_at'!")

func _on_object_deselected(_obj):
	print("DEBUG_HALO: Objekt deselektiert/gedroppt.")
	if menu_instance and menu_instance.has_method("close_menu"):
		menu_instance.close_menu()

func _process(_delta):
	# Wir prüfen nur, ob das Menü sichtbar sein sollte
	if not is_enabled or not menu_instance:
		return

	if not menu_instance.visible:
		# Hier kein Print, sonst spammt es die Konsole voll
		return
		
	_handle_raycast_interaction()

func _handle_raycast_interaction():
	if not raycast: return

	raycast.force_raycast_update()
	var collider = raycast.get_collider()
	
	# DEBUG: Nur drucken, wenn wir tatsächlich ETWAS treffen, sonst Spam
	if collider:
		# print("DEBUG_HALO: Raycast trifft -> ", collider.name) 
		pass

	# Reset Hover
	if current_hovered_button and current_hovered_button != collider:
		print("DEBUG_HALO: Hover verlassen: ", current_hovered_button.name)
		if current_hovered_button.has_method("set_highlight"):
			current_hovered_button.set_highlight(false)
		current_hovered_button = null
	
	# Neuer Hover
	if collider and collider.has_method("set_highlight"):
		
		# Nur drucken wenn wir NEU auf den Button kommen
		if current_hovered_button != collider:
			print("DEBUG_HALO: Hover gestartet auf: ", collider.name)
			current_hovered_button = collider
			current_hovered_button.set_highlight(true)
		
		# Klick prüfen
		if controller.is_button_pressed(activation_button):
			if not _btn_was_pressed:
				print("DEBUG_HALO: Button gedrückt auf: ", collider.name)
				_execute_button_action(collider)
				_btn_was_pressed = true
		else:
			_btn_was_pressed = false
	
	elif collider:
		# Wir treffen etwas, aber es ist kein HaloButton
		# print("DEBUG_HALO: Treffe Objekt ohne 'set_highlight': ", collider.name)
		pass
	
	else:
		_btn_was_pressed = false

func _execute_button_action(btn):
	if "action_name" in btn:
		var action = btn.action_name 
		print("DEBUG_HALO: Führe Aktion aus -> ", action)
		
		if manager.has_method("execute_menu_action"):
			manager.execute_menu_action(action)
		else:
			printerr("ERROR_HALO: Manager hat keine 'execute_menu_action' Funktion!")
	else:
		printerr("ERROR_HALO: Button hat keine 'action_name' Variable!")
