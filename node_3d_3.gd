extends Node3D
#
## --- REFERENCES ---
#@onready var fp := $"../XROrigin3D/right/FunctionPointer"
#var raycast: RayCast3D
#var controller: XRController3D
#
## --- VIS	UAL VARIABLES ---
#var current_mesh: MeshInstance3D
#var overlay_backup: Material
#var highlight_mat := StandardMaterial3D.new()
#var name_label: Label3D
#
## --- STATE VARIABLES ---
#var held_object: Node3D = null
#var rotation_offset: Basis 
#
## --- SCALING VARIABLES (NEW) ---
#var initial_hand_height: float = 0.0
## How fast it scales. 1.0 = Moderate, 2.0 = Fast
#var scaling_sensitivity: float = 1.5 
## Deadzone: Hand must move at least 5cm up/down to start scaling (prevents jitter)
#var scaling_deadzone: float = 0.05 
#
#func _ready():
	#print("DEBUG: --- Script Start ---")
	#
	## 1. Setup Highlight Material
	#highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	#highlight_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	#highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	#highlight_mat.albedo_color = Color(0.949, 0.0, 0.0, 0.718)	
	#
	#name_label = Label3D.new()
	#name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	#name_label.visible = false
	#name_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	#name_label.font_size = 32
	#add_child(name_label)
#
	## 2. Get the RayCast
	#if fp and fp.has_node("RayCast"):
		#raycast = fp.get_node("RayCast")
	#else:
		#printerr("CRITICAL ERROR: FunctionPointer or RayCast not found!")
		#return
#
	## 3. Get Controller
	#controller = fp.get_parent() 
	#if controller and controller is XRController3D:
		#controller.button_pressed.connect(_on_controller_button_pressed)
	#else:
		#printerr("ERROR: Could not find XRController3D parent!")
#
#func _process(delta):
	## We pass 'delta' (time since last frame) to our logic functions
	## so scaling happens smoothly per second.
	#if held_object:
		#_process_holding_movement(delta)
	#else:
		#_process_highlighting_visuals()
#
## --- INPUT LOGIC ---
#func _on_controller_button_pressed(action_name: String) -> void:
	#if action_name == fp.active_button_action:
		#if held_object:
			#_drop_object()
		#else:
			#_try_pickup_object()
#
## --- MOVEMENT, ROTATION & SCALING LOGIC ---
#func _process_holding_movement_fixed(delta: float):
	## 1. POSITION
	#if raycast.is_colliding():
		#var target_pos = raycast.get_collision_point()
		#held_object.global_position = target_pos
	#else:
		#var controller_forward = -raycast.global_transform.basis.z
		#held_object.global_position = raycast.global_position + (controller_forward * 2.0)
#
	## 2. ROTATION
	#held_object.global_transform.basis = controller.global_transform.basis * rotation_offset
#
	## 3. DYNAMIC SCALING (NEW)
	#_process_dynamic_scaling(delta)
#
#func _process_dynamic_scaling_fixed(delta: float):
	## Get current height (Y axis is Up/Down in Godot)
	#var current_hand_y = controller.global_position.y
	#
	## Calculate difference from the height where we picked it up
	#var diff = current_hand_y - initial_hand_height
	#
	## Deadzone Check: Only scale if we moved hand significantly (e.g. > 5cm)
	#if abs(diff) > scaling_deadzone:
		#
		## Calculate factor: 
		## If hand is 0.5m up, diff is 0.5. 
		## We multiply by sensitivity and delta to get "Percent per second"
		#var scale_change_percent = diff * scaling_sensitivity * delta
		#
		## Apply scaling
		## We add this percentage to the current scale
		#var new_scale = held_object.scale + (held_object.scale * scale_change_percent)
		#
		## Clamp: Prevent object from becoming negative (inverted) or too huge
		## Min size: 0.01 (1cm), Max size: 10.0 (10x)
		#new_scale = new_scale.clamp(Vector3(0.01, 0.01, 0.01), Vector3(10.0, 10.0, 10.0))
		#
		#held_object.scale = new_scale
#
## --- Dynamic ---
#
#
#
#
#
#
## --- MOVEMENT, ROTATION & SCALING LOGIC ---
#func _process_holding_movement(delta: float):
	## 1. POSITION
	#if raycast.is_colliding():
		#var target_pos = raycast.get_collision_point()
		#held_object.global_position = target_pos
	#else:
		#var controller_forward = -raycast.global_transform.basis.z
		#held_object.global_position = raycast.global_position + (controller_forward * 2.0)
#
	## 2. ROTATION (THE FIX IS HERE)
	## Capture the scale *before* we overwrite the basis with rotation
	#var current_scale = held_object.scale
	#
	## Apply rotation (This resets scale to 1.0 or initial pickup scale)
	#held_object.global_transform.basis = controller.global_transform.basis * rotation_offset
	#
	## Re-apply the scale we saved
	#held_object.scale = current_scale
#
	## 3. DYNAMIC SCALING
	## Now we can change the scale, and it won't be lost in the next frame
	#_process_dynamic_scaling(delta)
#
#
#func _process_dynamic_scaling(delta: float):
	## Get current height (Y axis is Up/Down in Godot)
	#var current_hand_y = controller.global_position.y
	#
	## Calculate difference from the height where we picked it up
	#var diff = current_hand_y - initial_hand_height
	#
	## Deadzone Check: Only scale if we moved hand significantly (e.g. > 5cm)
	#if abs(diff) > scaling_deadzone:
		#
		## Calculate factor: 
		## If hand is 0.5m up, diff is 0.5. 
		## We multiply by sensitivity and delta to get "Percent per second"
		#var scale_change_percent = diff * scaling_sensitivity * delta
		#
		## Apply scaling
		## We use the current scale so it grows exponentially (smoothly)
		#var new_scale = held_object.scale + (held_object.scale * scale_change_percent)
		#
		## Clamp: Prevent object from becoming negative (inverted) or too huge
		## Min size: 0.01 (1cm), Max size: 10.0 (10x)
		#new_scale = new_scale.clamp(Vector3(0.01, 0.01, 0.01), Vector3(10.0, 10.0, 10.0))
		#
		#held_object.scale = new_scale
#
#
#
#
## --- PICKUP LOGIC ---
#func _try_pickup_object():
	#var target = fp.last_target
	#
	#if target and is_instance_valid(target):
		#held_object = target
		#print("DEBUG: Picked up ", held_object.name)
		#
		#_clear_highlight()
		#raycast.add_exception(held_object)
		#
		#if held_object is RigidBody3D:
			#held_object.freeze = true
			#
		## Rotation Setup
		#rotation_offset = controller.global_transform.basis.inverse() * held_object.global_transform.basis
		#
		## SCALING SETUP (NEW)
		## Record the exact height of the hand when clicking the button
		#initial_hand_height = controller.global_position.y
		#print("DEBUG: Reference Height set to: ", initial_hand_height)
#
## --- DROP LOGIC ---
#func _drop_object():
	#if held_object:
		#print("DEBUG: Dropped ", held_object.name)
		#raycast.remove_exception(held_object)
		#if held_object is RigidBody3D:
			#held_object.freeze = false
			#held_object.linear_velocity = Vector3.ZERO
		#held_object = null
#
## --- HIGHLIGHTING LOGIC ---
#func _process_highlighting_visuals():
	#var hit = fp.last_target
	#if hit and hit is Node3D:
		#var mesh := _find_first_mesh(hit)
		#if mesh and mesh != current_mesh:
			#_clear_highlight()
			#current_mesh = mesh
			#overlay_backup = current_mesh.material_overlay
			#current_mesh.material_overlay = highlight_mat
			#name_label.text = mesh.name
			#name_label.global_position = mesh.global_position + Vector3(0.0, 1.0, 0.0)
			#name_label.visible = true
	#else:
		#_clear_highlight()
#
#func _find_first_mesh(n: Object) -> MeshInstance3D:
	#if n is MeshInstance3D: return n
	#if n is Node:
		#for c in n.get_children():
			#var m := _find_first_mesh(c)
			#if m: return m
	#return null
#
#func _clear_highlight():
	#if current_mesh and is_instance_valid(current_mesh):
		#current_mesh.material_overlay = overlay_backup
	#current_mesh = null
	#overlay_backup = null
	#name_label.visible = false
