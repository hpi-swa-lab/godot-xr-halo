extends Node

enum MenuMode {
	HAND_THUMBSTICK
}

@export_group("Settings")
@export var is_enabled: bool = true
@export var mode: MenuMode = MenuMode.HAND_THUMBSTICK

@export_group("Scenes")
@export var hand_menu_scene: PackedScene

@export_group("Input")
@export var activation_button: String = "grip_click"
@export var selection_button: String = "trigger_click"
@export var menu_offset: Vector3 = Vector3(0, 0.2, 0)

var manager: XRInteractionManager
var left_hand: XRController3D
var right_hand: XRController3D
var raycast: RayCast3D
var camera: Camera3D

var menu_instance: Node3D
var is_menu_open: bool = false
var _activation_btn_pressed: bool = false
var _selection_btn_pressed: bool = false
var _last_valid_thumbstick: Vector2 = Vector2.ZERO

func setup(_manager, _fp, _right_controller, _raycast):
	manager = _manager
	raycast = _raycast
	right_hand = _right_controller
	
	left_hand = manager.left_controller
	if not left_hand:
		printerr("ERROR: Feature_RadialMenu - Left Controller missing!")
		is_enabled = false
		return
	
	camera = manager.get_parent().get_node_or_null("XROrigin3D/XRCamera3D")
	
	if hand_menu_scene:
		menu_instance = hand_menu_scene.instantiate()
		manager.add_child(menu_instance)
		menu_instance.visible = false
		
		if menu_instance.has_signal("option_selected"):
			menu_instance.option_selected.connect(_on_menu_option)
	else:
		printerr("ERROR: Hand menu scene not assigned!")

func _process(_delta):
	if not is_enabled or not menu_instance or not left_hand:
		return
	
	process_hand_mode()

func process_hand_mode():
	var is_activation_pressed = left_hand.is_button_pressed(activation_button)
	
	if is_activation_pressed and not _activation_btn_pressed:
		_activation_btn_pressed = true
		
		if is_menu_open:
			confirm_selection()
		else:
			force_open_menu()
		return
	
	_activation_btn_pressed = is_activation_pressed
	
	# Keep menu position updated when open or showing active feature icon
	if is_menu_open or (menu_instance and menu_instance.has_method("is_icon_visible") and menu_instance.is_icon_visible()):
		update_menu_transform()

	# Handle menu input when open
	if is_menu_open:
		handle_thumbstick_input()
		
		var is_selection_pressed = left_hand.is_button_pressed(selection_button)
		if is_selection_pressed and not _selection_btn_pressed:
			confirm_selection()
		_selection_btn_pressed = is_selection_pressed

func update_menu_transform():
	if menu_instance and camera:
		var target_pos = left_hand.global_position + (left_hand.global_transform.basis * menu_offset)
		menu_instance.global_position = target_pos
		menu_instance.look_at(camera.global_position, Vector3.UP)
		menu_instance.rotate_object_local(Vector3.UP, PI)

func handle_thumbstick_input():
	var thumbstick = left_hand.get_vector2("primary")
	
	# Only update when thumbstick is beyond deadzone
	if thumbstick.length() > 0.25:
		_last_valid_thumbstick = thumbstick
	
	# Use last valid input for sticky selection
	if menu_instance.has_method("update_input"):
		menu_instance.update_input(_last_valid_thumbstick)

func confirm_selection():
	if menu_instance.has_method("confirm_selection"):
		menu_instance.confirm_selection()
	close_menu_slices_show_icon()

func close_menu_slices_show_icon():
	is_menu_open = false
	if menu_instance and menu_instance.has_method("hide_menu_slices"):
		menu_instance.hide_menu_slices()

func _on_menu_option(option_name: String):
	if menu_instance.has_method("show_active_feature_icon"):
		menu_instance.show_active_feature_icon(option_name)

	if manager.has_method("execute_menu_action"):
		manager.execute_menu_action(option_name)

func force_open_menu():
	if not is_enabled or not menu_instance:
		return
	
	is_menu_open = true
	menu_instance.visible = true
	_last_valid_thumbstick = Vector2.ZERO
	
	if menu_instance.has_method("show_menu_view"):
		menu_instance.show_menu_view()
	if menu_instance.has_method("reset_selection"):
		menu_instance.reset_selection()
	
	update_menu_transform()

func close_completely():
	is_menu_open = false
	if menu_instance:
		menu_instance.visible = false
	if menu_instance and menu_instance.has_method("hide_active_feature_icon"):
		menu_instance.hide_active_feature_icon()
		menu_instance.hide_active_feature_icon()
