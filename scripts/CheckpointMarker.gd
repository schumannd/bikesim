extends Area3D

signal reached

const MIST_BLUE := Color(0.25, 0.72, 1.0, 0.38)
const MIST_CORE := Color(0.45, 0.88, 1.0, 0.55)

const QuestDirectionArrowScript := preload("res://scripts/QuestDirectionArrow.gd")

var _style: String = "blue"
var _pulse: float = 0.0
var _reached: bool = false
var _visual_root: Node3D
var _mist_layers: Array[MeshInstance3D] = []
var _lights: Array[OmniLight3D] = []
var _direction_arrow: Node3D

func configure(style: String, show_arrow: bool) -> void:
	_style = style
	_build_column_visuals()
	if show_arrow:
		_direction_arrow = Node3D.new()
		_direction_arrow.name = "DirectionArrow"
		_direction_arrow.set_script(QuestDirectionArrowScript)
		add_child(_direction_arrow)
	elif _direction_arrow != null:
		_direction_arrow.queue_free()
		_direction_arrow = null

func set_arrow_target(world_position: Vector3) -> void:
	if _direction_arrow == null or not is_instance_valid(_direction_arrow):
		return
	if _direction_arrow.has_method("set_target_world_position"):
		_direction_arrow.call("set_target_world_position", world_position)

func _ready() -> void:
	monitoring = true
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _reached or _visual_root == null:
		return
	_pulse += delta * 1.6
	var breathe := 1.0 + sin(_pulse) * 0.06
	_visual_root.scale = Vector3(breathe, 1.0 + sin(_pulse * 0.8) * 0.04, breathe)
	for i in range(_mist_layers.size()):
		var layer: MeshInstance3D = _mist_layers[i]
		layer.rotation.y = sin(_pulse * 1.2 + float(i) * 0.9) * 0.04

func _on_body_entered(body: Node3D) -> void:
	if _reached or body == null or body.name != "Bike":
		return
	reached.emit()

func _build_column_visuals() -> void:
	if _visual_root != null:
		_visual_root.queue_free()
	_mist_layers.clear()
	_lights.clear()

	_visual_root = Node3D.new()
	_visual_root.name = "CheckpointColumn"
	add_child(_visual_root)

	match _style:
		"checkered":
			_build_checkered_column()
		_:
			_build_blue_column()

func _build_blue_column() -> void:
	_add_disc(Vector3(0.0, 0.05, 0.0), 2.4, 0.12, MIST_BLUE.lightened(0.2), MIST_BLUE, 0.5, 2.0)
	var heights := [1.6, 3.2, 4.8, 6.2]
	var radii_top := [1.0, 0.85, 0.7, 0.55]
	var radii_bottom := [1.25, 1.05, 0.9, 0.72]
	for i in range(heights.size()):
		var layer := _add_cylinder(
			Vector3(0.0, heights[i] * 0.5, 0.0),
			radii_bottom[i],
			radii_top[i],
			heights[i],
			MIST_BLUE,
			0.28 + float(i) * 0.04,
			1.6
		)
		_mist_layers.append(layer)
	_add_cylinder(Vector3(0.0, 3.2, 0.0), 0.35, 0.25, 6.4, MIST_CORE, 0.65, 2.8)
	_add_light(Color(0.35, 0.8, 1.0), Vector3(0.0, 1.2, 0.0), 2.4, 14.0)
	_add_light(Color(0.5, 0.9, 1.0), Vector3(0.0, 6.0, 0.0), 1.2, 8.0)

func _build_checkered_column() -> void:
	var heights := [1.4, 1.4, 1.4, 1.4, 1.4, 1.4]
	var y := 0.7
	for i in range(heights.size()):
		var is_white := i % 2 == 0
		var color := Color(0.95, 0.95, 0.96, 0.9) if is_white else Color(0.08, 0.08, 0.09, 0.92)
		var layer := _add_cylinder(Vector3(0.0, y, 0.0), 1.05, 1.05, heights[i], color, 0.95, 0.4)
		_mist_layers.append(layer)
		y += heights[i]
	_add_disc(Vector3(0.0, 0.05, 0.0), 2.6, 0.12, Color(0.9, 0.9, 0.92, 1.0), Color(0.9, 0.9, 0.92, 1.0), 1.0, 0.5)
	_add_light(Color(1.0, 1.0, 1.0), Vector3(0.0, 2.5, 0.0), 1.8, 12.0)

func _add_cylinder(
	pos: Vector3,
	bottom_r: float,
	top_r: float,
	height: float,
	color: Color,
	alpha: float,
	emission: float
) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = 24
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = _mist_material(color, alpha, emission)
	_visual_root.add_child(mesh_inst)
	return mesh_inst

func _add_disc(
	pos: Vector3,
	radius: float,
	height: float,
	color: Color,
	emission_color: Color,
	alpha: float,
	emission: float
) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 32
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = _mist_material(color, alpha, emission)
	_visual_root.add_child(mesh_inst)
	return mesh_inst

func _add_light(color: Color, pos: Vector3, energy: float, range: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range
	_visual_root.add_child(light)
	_lights.append(light)

func _mist_material(color: Color, alpha: float, emission: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.emission_enabled = emission > 0.05
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = emission
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	mat.roughness = 0.92
	return mat

func mark_reached() -> void:
	if _reached:
		return
	_reached = true
	if _visual_root:
		_visual_root.visible = false
	if _direction_arrow:
		_direction_arrow.visible = false
	for light: OmniLight3D in _lights:
		light.visible = false
