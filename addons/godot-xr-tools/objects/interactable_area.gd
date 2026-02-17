@tool
class_name XRToolsInteractableArea
extends Area3D


## Signal when pointer event occurs on area
signal pointer_event(event)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableArea"


func _on_pointer_entered(pointer):
	print("Pointer entered Player")

func _on_pointer_exited(pointer):
	print("Pointer exited Player")

func _on_pointer_pressed(pointer):
	print("Pointer pressed Player")

func _on_pointer_released(pointer):
	print("Pointer released Player")
