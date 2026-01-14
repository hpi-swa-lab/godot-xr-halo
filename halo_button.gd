extends Area3D

# Der Name der Aktion, die an den Manager gesendet wird (z.B. "Move", "Scale")
@export var action_name: String = "Move" 

@onready var sprite = $Sprite3D 
# Falls du auch Text hast: @onready var label = $Label3D

var original_scale: Vector3

func _ready():
	original_scale = scale

# Wird vom Feature-Skript aufgerufen, wenn der Raycast trifft
func set_highlight(active: bool):
	if active:
		# Hover-Effekt: Etwas größer und gelb
		scale = original_scale * 1.3
		if sprite: sprite.modulate = Color(1, 1, 0) # Gelb
	else:
		# Normalzustand
		scale = original_scale
		if sprite: sprite.modulate = Color(1, 1, 1) # Weiß
