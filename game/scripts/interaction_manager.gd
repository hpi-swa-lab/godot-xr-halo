extends Node3D
class_name XRInteractionManager

@export_group("References")
@export var fp: Node3D
@export var controller: XRController3D
@export var left_controller: XRController3D
@export var radial_menu_feature: Node

@export_group("Features")
@export var feature_moving: Node
@export var feature_scaling: Node
@export var feature_rotating: Node

var held_object: Node3D = null
var raycast: RayCast3D
var active_mode: String = "None"

signal object_picked_up(obj)
signal object_dropped(obj)

func _ready():
	if fp and fp.has_node("RayCast"):
		raycast = fp.get_node("RayCast")
	
	if controller and not controller.button_pressed.is_connected(_on_button_pressed):
		controller.button_pressed.connect(_on_button_pressed)
	
	for child in get_children():
		if child.has_method("setup"):
			child.setup(self, fp, controller, raycast)

func _on_button_pressed(action_name: String):
	if action_name != fp.active_button_action:
		return
	
	if active_mode != "None" and held_object:
		deselect_object()
		return
	
	var target = fp.last_target
	if target and is_instance_valid(target):
		select_object(target)
	elif held_object:
		deselect_object()

func select_object(target: Node3D):
	held_object = target
	if radial_menu_feature and radial_menu_feature.has_method("force_open_menu"):
		radial_menu_feature.force_open_menu()

func deselect_object():
	drop()
	held_object = null
	active_mode = "None"
	set_features_enabled(false, false, false)
	
	if radial_menu_feature and radial_menu_feature.has_method("close_completely"):
		radial_menu_feature.close_completely()

func execute_menu_action(action: String):
	active_mode = action
	
	match action:
		"Move":
			set_features_enabled(true, false, false)
			start_interaction()
		"Scale":
			set_features_enabled(false, true, false)
			start_interaction()
		"Rotate":
			set_features_enabled(false, false, true)
			start_interaction()
		"Reset":
			if held_object:
				held_object.scale = Vector3.ONE
			active_mode = "None"

func set_features_enabled(move: bool, scale: bool, rotate: bool):
	if feature_moving:
		feature_moving.is_enabled = move
	if feature_scaling:
		feature_scaling.is_enabled = scale
	if feature_rotating:
		feature_rotating.is_enabled = rotate

func start_interaction():
	if not held_object:
		return
	
	raycast.add_exception(held_object)
	
	if held_object is RigidBody3D:
		held_object.freeze = true
	
	emit_signal("object_picked_up", held_object)

func drop():
	if held_object:
		if raycast:
			raycast.remove_exception(held_object)
			raycast.force_raycast_update()
		
		if held_object is RigidBody3D:
			held_object.freeze = false
			held_object.linear_velocity = Vector3.ZERO
			held_object.angular_velocity = Vector3.ZERO
		
		var obj_ref = held_object
		emit_signal("object_dropped", obj_ref)

	if radial_menu_feature and radial_menu_feature.menu_instance:
		if radial_menu_feature.menu_instance.has_method("hide_active_feature_icon"):
			radial_menu_feature.menu_instance.hide_active_feature_icon()
