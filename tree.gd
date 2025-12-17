extends MeshInstance3D

func _ready() -> void:
	# Safely find the Area3D node
	print("ok it's working")
	var area := $Area3D
	if area:
		area.body_entered.connect(_on_body_entered)
	else:
		push_warning("No Area3D child found under tree!")

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_finish_game()

func _finish_game() -> void:
	print("Player reached the tree! Game finished.")
	get_tree().paused = true
