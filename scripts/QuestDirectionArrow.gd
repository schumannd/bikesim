extends Node3D

const ARROW_COLOR := Color(1.0, 0.88, 0.15, 1.0)

var _target: Vector3 = Vector3.INF
var _bob: float = 0.0

func _ready() -> void:
	_build_arrow_mesh()
	position = Vector3(0.0, 7.5, 0.0)

func _build_arrow_mesh() -> void:
	var shaft := MeshInstance3D.new()
	var shaft_mesh := BoxMesh.new()
	shaft_mesh.size = Vector3(0.35, 2.8, 0.35)
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0.0, -1.6, 0.0)
	shaft.material_override = _arrow_material()
	add_child(shaft)

	var head := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.9
	head_mesh.height = 1.6
	head_mesh.radial_segments = 4
	head.mesh = head_mesh
	head.position = Vector3(0.0, -0.2, 0.0)
	head.rotation.x = PI
	head.material_override = _arrow_material()
	add_child(head)

func _arrow_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ARROW_COLOR
	mat.emission_enabled = true
	mat.emission = ARROW_COLOR
	mat.emission_energy_multiplier = 1.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func set_target_world_position(target: Vector3) -> void:
	_target = target

func _process(delta: float) -> void:
	if _target == Vector3.INF:
		visible = false
		return
	visible = true
	_bob += delta * 2.2
	position.y = 7.5 + sin(_bob) * 0.35
	var flat_target := Vector3(_target.x, global_position.y, _target.z)
	look_at(flat_target, Vector3.UP)
