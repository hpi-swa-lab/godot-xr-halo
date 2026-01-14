extends Node

@export var is_enabled: bool = true
@export var rotation_speed: float = 3.0 # Wie schnell soll es sich drehen?

var manager: XRInteractionManager
var rotate_hand: XRController3D # Linke Hand
# Raycast wird hier eigentlich nicht mehr gebraucht, außer für Validierung

func setup(_manager, _fp, _controller, _raycast):
	manager = _manager
	# controller = _controller # Brauchen wir für Joystick-Rotation gerade nicht zwingend
	
	rotate_hand = manager.left_controller
	
	if not rotate_hand:
		printerr("WARNUNG: Feature_Rotating hat keine Linke Hand gefunden!")
	
	# Signale verbinden
	if not manager.object_picked_up.is_connected(_on_picked):
		manager.object_picked_up.connect(_on_picked)
	
	if not manager.object_dropped.is_connected(_on_dropped):
		manager.object_dropped.connect(_on_dropped)
		
	set_process(false)

func _on_picked(obj):
	if not is_enabled: return
	
	# Wir brauchen keinen Offset mehr, da wir nicht die Hand-Rotation kopieren,
	# sondern aktiv per Stick steuern.
	
	set_process(true)

func _on_dropped(_obj):
	set_process(false)

func _process(delta):
	# 1. Sicherheits-Checks
	if not is_enabled or not manager or not rotate_hand: 
		set_process(false)
		return

	var obj = manager.held_object
	if not obj: return

	# 2. INPUT HOLEN (Linker Stick)
	# "primary" ist der Standard-Name für den Thumbstick in OpenXR
	var joystick = rotate_hand.get_vector2("primary")
	
	# Deadzone (damit es nicht zittert, wenn der Stick leicht locker ist)
	if joystick.length() < 0.1:
		return

	# 3. ROTATION ANWENDEN
	
	# A) Stick Links/Rechts (X) -> Dreht das Objekt um die Welt-Achse Y (wie ein Plattenteller)
	# Das fühlt sich meistens am natürlichsten an, damit das Objekt "aufrecht" bleibt.
	# Minus-Vorzeichen ggf. entfernen, je nach gewünschter Richtung.
	obj.rotate_y(-joystick.x * rotation_speed * delta)
	
	# B) Stick Hoch/Runter (Y) -> Kippt das Objekt (lokale X-Achse)
	# Wir nutzen 'rotate_object_local', damit es sich "zu dir hin" oder "weg" kippt, 
	# egal wie es gerade im Raum steht.
	obj.rotate_object_local(Vector3.RIGHT, -joystick.y * rotation_speed * delta)
