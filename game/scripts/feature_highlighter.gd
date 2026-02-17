extends Node

@export var is_enabled: bool = true

var manager: XRInteractionManager
var fp: Node3D

var current_mesh: MeshInstance3D
var overlay_backup: Material
var highlight_mat := StandardMaterial3D.new()
var name_label: Label3D

func setup(_manager, _fp, _controller, _raycast):
	manager = _manager
	fp = _fp
	init_visuals()

func init_visuals():
	highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	highlight_mat.albedo_color = Color(0.949, 0.0, 0.0, 0.718)	
	
	name_label = Label3D.new()
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.visible = false
	name_label.font_size = 32
	manager.add_child(name_label)

func _process(_delta):
	if not manager:
		return
	
	# Skip highlighting when holding object
	if manager.held_object != null:
		clear_highlight()
		return

	# Highlight object under raycast
	var hit = fp.last_target
	if hit and hit is Node3D:
		var mesh := find_first_mesh(hit)
		if mesh and mesh != current_mesh:
			clear_highlight()
			current_mesh = mesh
			overlay_backup = current_mesh.material_overlay
			current_mesh.material_overlay = highlight_mat
			
			name_label.text = mesh.name
			name_label.global_position = mesh.global_position + Vector3(0.0, 1.0, 0.0)
			name_label.visible = true
	else:
		clear_highlight()

func find_first_mesh(n: Object) -> MeshInstance3D:
	if n is MeshInstance3D:
		return n
	if n is Node:
		for c in n.get_children():
			var m := find_first_mesh(c)
			if m:
				return m
	return null

func clear_highlight():
	if current_mesh and is_instance_valid(current_mesh):
		current_mesh.material_overlay = overlay_backup
	current_mesh = null
	overlay_backup = null
	name_label.visible = false
