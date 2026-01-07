extends Node3D
class_name XRInteractionManager

# --- EXPORTS ---
@export var fp: Node3D           # FunctionPointer (Rechts)
@export var controller: XRController3D 
@export var left_controller: XRController3D 

# --- PUBLIC STATE ---
var held_object: Node3D = null
var raycast: RayCast3D
var vent: bool = false
# --- SIGNALS ---
signal object_picked_up(obj)
signal object_dropped(obj)

func _ready():
	print("DEBUG: XRInteractionManager gestartet")
	
	if fp and fp.has_node("RayCast"):
		raycast = fp.get_node("RayCast")
	else:
		printerr("CRITICAL ERROR: RayCast im FunctionPointer nicht gefunden!")
		return

	# Input kommt weiterhin von der RECHTEN Hand (Button click)
	if controller:
		if not controller.button_pressed.is_connected(_on_button_pressed):
			controller.button_pressed.connect(_on_button_pressed)
	
	# Safety Check 
	if not left_controller:
		printerr("WARNUNG: Linker Controller im InteractionManager nicht zugewiesen!")

	# Features initialisieren
	for child in get_children():
		if child.has_method("setup"):
			child.setup(self, fp, controller, raycast)

func _on_button_pressed(action_name: String):
	if action_name == fp.active_button_action:
		if held_object:
			_drop()
		else:
			_try_pickup()

func _try_pickup():
	var target = fp.last_target
	if target and is_instance_valid(target):
		held_object = target
		raycast.add_exception(held_object)
		
		if held_object is RigidBody3D:
			held_object.freeze = true
			
		print("MANAGER: Picked up ", held_object.name)
		emit_signal("object_picked_up", held_object)

func _drop():
	if held_object:
		print("MANAGER: Dropped ", held_object.name)
		raycast.remove_exception(held_object)
		
		if held_object is RigidBody3D:
			held_object.freeze = false
			held_object.linear_velocity = Vector3.ZERO
		
		var obj_ref = held_object
		held_object = null
		emit_signal("object_dropped", obj_ref)
		
		
		
func venti():
	vent = true
