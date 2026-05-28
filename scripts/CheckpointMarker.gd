extends Area3D

const MIST_BLUE := Color(0.25, 0.72, 1.0, 0.38)
const MIST_CORE := Color(0.45, 0.88, 1.0, 0.55)

var _pulse: float = 0.0
var _reached: bool = false
var _visual_root: Node3D
var _mist_layers: Array[MeshInstance3D] = []
var _lights: Array[OmniLight3D] = []

func _ready() -> void:
	_build_column_visuals()

func _process(delta: float) -> void:
	if _reached or _visual_root == null:
		return
	_pulse += delta * 1.6
	var breathe := 1.0 + sin(_pulse) * 0.06
	_visual_root.scale = Vector3(breathe, 1.0 + sin(_pulse * 0.8) * 0.04, breathe)
	for i in range(_mist_layers.size()):
		var layer: MeshInstance3D = _mist_layers[i]
		var wobble := sin(_pulse * 1.2 + float(i) * 0.9) * 0.04
		layer.rotation.y = wobble

func _build_column_visuals() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "CheckpointColumn"
	add_child(_visual_root)

	var base_ring := _add_mist_disc(Vector3(0.0, 0.05, 0.0), 2.4, 0.12, MIST_BLUE.lightened(0.2))
	base_ring.material_override = _mist_material(MIST_BLUE, 0.5, 2.0)

	var heights := [1.6, 3.2, 4.8, 6.2]
	var radii_top := [1.0, 0.85, 0.7, 0.55]
	var radii_bottom := [1.25, 1.05, 0.9, 0.72]
	for i in range(heights.size()):
		var layer := _add_mist_cylinder(
			Vector3(0.0, heights[i] * 0.5, 0.0),
			radii_bottom[i],
			radii_top[i],
			heights[i],
			0.28 + float(i) * 0.04
		)
		_mist_layers.append(layer)

	var core := _add_mist_cylinder(Vector3(0.0, 3.2, 0.0), 0.35, 0.25, 6.4, 0.65)
	core.material_override = _mist_material(MIST_CORE, 0.7, 2.8)

	var base_light := OmniLight3D.new()
	base_light.position = Vector3(0.0, 1.2, 0.0)
	base_light.light_color = Color(0.35, 0.8, 1.0, 1.0)
	base_light.light_energy = 2.4
	base_light.omni_range = 14.0
	_visual_root.add_child(base_light)
	_lights.append(base_light)

	var top_light := OmniLight3D.new()
	top_light.position = Vector3(0.0, 6.0, 0.0)
	top_light.light_color = Color(0.5, 0.9, 1.0, 1.0)
	top_light.light_energy = 1.2
	top_light.omni_range = 8.0
	_visual_root.add_child(top_light)
	_lights.append(top_light)

func _add_mist_cylinder(pos: Vector3, bottom_r: float, top_r: float, height: float, alpha: float) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = 24
	mesh.rings = 1
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = _mist_material(MIST_BLUE, alpha, 1.6)
	_visual_root.add_child(mesh_inst)
	return mesh_inst

func _add_mist_disc(pos: Vector3, radius: float, height: float, color: Color) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = _mist_material(color, color.a, 1.8)
	_visual_root.add_child(mesh_inst)
	return mesh_inst

func _mist_material(color: Color, alpha: float, emission: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = emission
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 0.92
	mat.metallic = 0.0
	return mat

func mark_reached() -> void:
	if _reached:
		return
	_reached = true
	if _visual_root:
		_visual_root.visible = false
	for light: OmniLight3D in _lights:
		light.visible = false
