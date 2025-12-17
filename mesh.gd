extends Node3D

@onready var meshe: MeshInstance3D = get_node_or_null("**/")

func _ready():
	meshe.material_override = meshe.mesh.surface_get_material(0).duplicate()

func _on_mouse_entered():
	meshe.material_override.albedo_color = Color(0.8, 1.0, 0.8) # green tint

func _on_mouse_exited():
	meshe.material_override.albedo_color = Color(1, 1, 1)
