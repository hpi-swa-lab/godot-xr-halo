extends RigidBody3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("player")
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#var input = Input.get_action_strength("ui_up")
	#apply_central_force(input * Vector3.FORWARD * 1200.0 * delta)
	var input := Vector3.ZERO
	input.x = Input.get_axis("move_left", "move_right")
	input.z = Input.get_axis("move_forward","move_back")
	
	apply_central_force(input * 1200.0 * delta)
		
	
func _on_body_entered(body: Node) -> void:
	if body.name == "tree":
		print("Player reached the tree! Game finished.")
		get_tree().paused = true
		
		
