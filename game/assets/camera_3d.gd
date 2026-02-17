extends Camera3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var move_speed := 5.0
	var rotate_speed := 1.5  

	# --- movement ---
	var input_camera := Vector3.ZERO
	input_camera.x = Input.get_axis("move_left", "move_right")
	input_camera.z = Input.get_axis("move_forward", "move_back")
	input_camera.y = Input.get_axis("move_down", "move_up")

	var dir := (transform.basis.x * input_camera.x) + (transform.basis.y * input_camera.y) + (transform.basis.z * input_camera.z)
	global_position += dir.normalized() * move_speed * delta

	# --- rotation ---
	var rotate_input := Input.get_axis("rotate_left", "rotate_right")
	rotation.y -= rotate_input * rotate_speed * delta
