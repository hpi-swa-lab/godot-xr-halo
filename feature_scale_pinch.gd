extends Node

@export var is_enabled: bool = true
@export var min_scale: float = 0.01
@export var max_scale: float = 10.0

var manager: XRInteractionManager
var right_hand: XRController3D
var left_hand: XRController3D

# State
var is_pinching: bool = false
var start_hand_distance: float = 0.0
var start_object_scale: Vector3

func setup(_manager, _fp, _right_controller, _raycast):
	manager = _manager
	right_hand = _right_controller
	
	# Wir holen die linke Hand vom Manager
	left_hand = manager.left_controller
	
	if not left_hand:
		printerr("ERROR: Feature_TwoHandScaler benötigt linken Controller im Manager!")
		is_enabled = false
		return
	
	# Wir verbinden uns direkt mit dem Input-Signal der LINKEN Hand
	if not left_hand.button_pressed.is_connected(_on_left_button_pressed):
		left_hand.button_pressed.connect(_on_left_button_pressed)
		left_hand.button_released.connect(_on_left_button_released)
		
	# Auch auf Drop hören, um Pinch abzubrechen falls Objekt verloren geht
	manager.object_dropped.connect(_on_dropped)

func _on_left_button_pressed(action_name: String):
	
	if not is_enabled or not manager.held_object:
		return
	print("its workiiiiiiing")
	if action_name == "trigger_click":
		start_pinching()

func _on_left_button_released(action_name: String):
	if action_name == "trigger_click":
		stop_pinching()

func _on_dropped(_obj):
	stop_pinching()

func start_pinching():
	is_pinching = true
	# 1. Start-Abstand zwischen Händen merken
	start_hand_distance = left_hand.global_position.distance_to(right_hand.global_position)
	# 2. Start-Scale des Objekts merken
	start_object_scale = manager.held_object.scale
	print("DEBUG: Two-Hand Scale gestartet. Abstand: ", start_hand_distance)

func stop_pinching():
	is_pinching = false

func _process(_delta):
	# Nur ausführen wenn wir aktiv "pinchen" und ein Objekt halten
	if not is_pinching or not manager.held_object:
		return
		
	var obj = manager.held_object
	
	# 1. Aktuellen Abstand messen
	var current_distance = left_hand.global_position.distance_to(right_hand.global_position)
	
	# 2. Sicherheit: Division durch Null verhindern
	if start_hand_distance < 0.001:
		return
		
	# 3. Faktor berechnen (Ratio)
	# Beispiel: Start war 10cm, Jetzt 20cm -> Faktor 2.0 (Verdoppeln)
	var scale_factor = current_distance / start_hand_distance
	
	# 4. Neue Skalierung anwenden (Multiplikativ zur Start-Skalierung)
	var new_scale = start_object_scale * scale_factor
	
	# Clamp (Grenzen einhalten)
	new_scale = new_scale.clamp(Vector3(min_scale, min_scale, min_scale), Vector3(max_scale, max_scale, max_scale))
	
	obj.scale = new_scale
