extends Node

@export var is_enabled: bool = true
@export var menu_scene: PackedScene # Drag RadialMenu.tscn here
@export var activation_button: String = "ax_button" # 'ax_button' is usually 'X' or 'Menu' on Quest
@export var menu_offset: Vector3 = Vector3(0, 0.15, 0) # Floats 15cm above hand

var manager: XRInteractionManager
var left_hand: XRController3D
var camera: XRCamera3D

var menu_instance: Node3D
var is_menu_open: bool = false

func setup(_manager, _fp, _right_controller, _raycast):
	manager = _manager
	
	# 1. Get Left Hand
	left_hand = manager.left_controller
	if not left_hand:
		printerr("ERROR: Radial Menu needs Left Controller!")
		is_enabled = false
		return
	
	# 2. Get Camera (to look at)
	# We look up the tree to find the XROrigin, then find the Camera
	var origin = manager.get_parent().get_parent() # Assuming Hierarchy: Origin -> Hand -> Manager
	if origin:
		camera = origin.get_node_or_null("XRCamera3D")
	
	# 3. Instantiate the Menu Visuals
	if menu_scene:
		menu_instance = menu_scene.instantiate()
		manager.add_child(menu_instance) # Add to world/manager, not hand (smoother)
		menu_instance.visible = false
		
		# Connect the signal from the visual script
		if menu_instance.has_signal("option_selected"):
			menu_instance.option_selected.connect(_on_menu_option)

func _process(delta):
	if not is_enabled or not left_hand or not menu_instance:
		return
		
	# --- 1. HANDLE TOGGLE (Open/Close) ---
	# We check if button is currently HELD down
	var button_pressed = left_hand.is_button_pressed(activation_button)
	if button_pressed:
		printerr("it was pressed!")
	if button_pressed and not is_menu_open:
		_open_menu()
	elif not button_pressed and is_menu_open:
		_close_and_select()
		
	# --- 2. UPDATE WHILE OPEN ---
	if is_menu_open:
		_update_menu_transform()
		_handle_thumbstick()

func _open_menu():
	is_menu_open = true
	menu_instance.visible = true
	
	# Initial position snap
	_update_menu_transform()

func _close_and_select():
	is_menu_open = false
	menu_instance.visible = false
	
	# Tell the menu to execute the currently selected item
	if menu_instance.has_method("confirm_selection"):
		menu_instance.confirm_selection()

func _update_menu_transform():
	# 1. Follow Hand Position (with offset)
	menu_instance.global_position = left_hand.global_position + (left_hand.global_transform.basis * menu_offset)
	
	# 2. Look at Face (Billboard)
	if camera:
		# look_at points the -Z axis at the target. 
		menu_instance.look_at(camera.global_position, Vector3.UP)
		
		# FIX: If the menu appears flipped/backwards, uncomment this line:
		# menu_instance.rotate_object_local(Vector3.UP, PI) 

func _handle_thumbstick():
	# Get Joystick Value (Vector2)
	var thumbstick = left_hand.get_vector2("primary_2d_axis")
	
	# Pass it to the visual script
	if menu_instance.has_method("update_input"):
		menu_instance.update_input(thumbstick)

func _on_menu_option(option_name: String):
	# Wir leiten den Befehl einfach an den Manager weiter!
	if manager.has_method("execute_menu_action"):
		manager.execute_menu_action(option_name)
	print("MENU SELECTED: ", option_name)
	
	# Execute logic based on name
	match option_name:
		"Reset":
			if manager.held_object:
				manager.held_object.scale = Vector3.ONE
		"Delete":
			if manager.held_object:
				# Use manager's drop logic first to clean up
				manager._drop() 
				# Then delete
				# Note: You might need to store a ref before dropping if _drop clears held_object
				pass
