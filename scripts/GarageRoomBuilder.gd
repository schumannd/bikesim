extends Node3D

const FLOOR_SIZE := Vector3(14.0, 0.2, 10.0)
const WALL_HEIGHT := 4.2

func _ready() -> void:
	_build_room()

func _build_room() -> void:
	var floor_mat := _mat(Color(0.14, 0.14, 0.15, 1.0), 0.95)
	var wall_mat := _mat(Color(0.22, 0.23, 0.25, 1.0), 0.9)
	var trim_mat := _mat(Color(0.32, 0.34, 0.36, 1.0), 0.75)
	var ceiling_mat := _mat(Color(0.1, 0.1, 0.11, 1.0), 1.0)

	_add_ambient_environment()
	_add_box("Floor", Vector3(0.0, -0.1, 0.0), FLOOR_SIZE, floor_mat)
	_add_box("Ceiling", Vector3(0.0, WALL_HEIGHT + 0.1, 0.0), Vector3(FLOOR_SIZE.x, 0.2, FLOOR_SIZE.z), ceiling_mat)

	var half_x := FLOOR_SIZE.x * 0.5
	var half_z := FLOOR_SIZE.z * 0.5
	var wall_thickness := 0.25
	var wall_y := WALL_HEIGHT * 0.5

	_add_box("WallBack", Vector3(0.0, wall_y, -half_z), Vector3(FLOOR_SIZE.x, WALL_HEIGHT, wall_thickness), wall_mat)
	_add_box("WallFront", Vector3(0.0, wall_y, half_z), Vector3(FLOOR_SIZE.x, WALL_HEIGHT, wall_thickness), wall_mat)
	_add_box("WallLeft", Vector3(-half_x, wall_y, 0.0), Vector3(wall_thickness, WALL_HEIGHT, FLOOR_SIZE.z), wall_mat)
	_add_box("WallRight", Vector3(half_x, wall_y, 0.0), Vector3(wall_thickness, WALL_HEIGHT, FLOOR_SIZE.z), wall_mat)

	_add_box("TrimBack", Vector3(0.0, 0.12, -half_z + 0.12), Vector3(FLOOR_SIZE.x - 0.4, 0.08, 0.5), trim_mat)
	_add_box("ToolBench", Vector3(-4.8, 0.55, 3.2), Vector3(2.4, 1.1, 0.7), trim_mat)
	_add_box("PartsShelf", Vector3(4.7, 1.2, 3.0), Vector3(1.8, 2.4, 0.45), trim_mat)

	_add_back_wall_graffiti(half_z)
	_add_lighting(half_x, half_z)

func _add_ambient_environment() -> void:
	var world_env := WorldEnvironment.new()
	world_env.name = "GarageEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.11, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.52, 0.54, 0.58, 1.0)
	env.ambient_light_energy = 1.05
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.2
	world_env.environment = env
	add_child(world_env)

func _add_lighting(half_x: float, half_z: float) -> void:
	# Ceiling workshop fluorescents
	for x in [-4.0, 0.0, 4.0]:
		_add_ceiling_fixture(Vector3(x, WALL_HEIGHT - 0.22, 0.5))
	_add_ceiling_fixture(Vector3(3.0, WALL_HEIGHT - 0.22, -2.5))

	# Bright fill over the bike display
	_add_omni_light(Vector3(3.2, 3.4, 1.2), 3.2, 16.0, Color(1.0, 0.96, 0.9, 1.0))
	_add_omni_light(Vector3(1.0, 2.6, -1.5), 2.2, 14.0, Color(0.92, 0.94, 1.0, 1.0))
	_add_omni_light(Vector3(-3.5, 2.4, 2.0), 1.9, 12.0, Color(1.0, 0.92, 0.82, 1.0))

	# Spot on bike from front-left
	_add_spot_light(
		Vector3(-1.5, 3.8, 2.5),
		Vector3(-0.9, -0.35, -0.2),
		2.8,
		18.0,
		Color(1.0, 0.98, 0.95, 1.0)
	)
	# Back-wall wash so graffiti reads clearly
	_add_spot_light(
		Vector3(0.0, 2.8, 3.8),
		Vector3(-0.2, -0.45, -0.85),
		2.0,
		20.0,
		Color(0.85, 0.9, 1.0, 1.0)
	)
	# Corner fill near shelves
	_add_omni_light(Vector3(half_x - 1.0, 2.0, half_z - 1.5), 1.6, 10.0, Color(1.0, 0.88, 0.7, 1.0))

func _add_ceiling_fixture(pos: Vector3) -> void:
	var housing := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.2, 0.12, 0.55)
	housing.mesh = mesh
	housing.position = pos
	var housing_mat := _mat(Color(0.28, 0.29, 0.3, 1.0), 0.6)
	housing.material_override = housing_mat
	add_child(housing)

	var bulb := MeshInstance3D.new()
	var bulb_mesh := BoxMesh.new()
	bulb_mesh.size = Vector3(1.8, 0.04, 0.38)
	bulb.mesh = bulb_mesh
	bulb.position = pos + Vector3(0.0, -0.05, 0.0)
	var bulb_mat := _mat(Color(0.95, 0.93, 0.85, 1.0), 0.15)
	bulb_mat.emission_enabled = true
	bulb_mat.emission = Color(1.0, 0.95, 0.82, 1.0)
	bulb_mat.emission_energy_multiplier = 1.8
	bulb.material_override = bulb_mat
	add_child(bulb)

	var light := OmniLight3D.new()
	light.position = pos + Vector3(0.0, -0.35, 0.0)
	light.light_color = Color(1.0, 0.95, 0.85, 1.0)
	light.light_energy = 1.4
	light.omni_range = 11.0
	light.shadow_enabled = false
	add_child(light)

func _add_omni_light(pos: Vector3, energy: float, range: float, color: Color) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range
	light.shadow_enabled = false
	add_child(light)

func _add_spot_light(pos: Vector3, look_dir: Vector3, energy: float, range: float, color: Color) -> void:
	var light := SpotLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.spot_range = range
	light.spot_angle = 42.0
	light.shadow_enabled = false
	add_child(light)
	light.look_at(pos + look_dir.normalized(), Vector3.UP)

func _add_back_wall_graffiti(half_z: float) -> void:
	var wall_z := -half_z + 0.14
	var root := Node3D.new()
	root.name = "BackWallGraffiti"
	add_child(root)

	# Large central tag
	_add_graffiti_panel(root, Vector3(-2.4, 2.1, wall_z), Vector3(2.8, 1.4, 0.04), Color(0.95, 0.2, 0.55, 1.0))
	_add_graffiti_panel(root, Vector3(0.2, 2.0, wall_z), Vector3(2.2, 1.6, 0.04), Color(0.15, 0.85, 0.95, 1.0))
	_add_graffiti_panel(root, Vector3(2.8, 2.2, wall_z), Vector3(1.6, 1.1, 0.04), Color(0.98, 0.88, 0.12, 1.0))

	# Outline drips and throw-ups
	_add_graffiti_panel(root, Vector3(-3.8, 1.2, wall_z), Vector3(1.1, 2.4, 0.03), Color(0.55, 0.95, 0.35, 1.0))
	_add_graffiti_panel(root, Vector3(3.6, 1.4, wall_z), Vector3(0.9, 2.0, 0.03), Color(0.75, 0.35, 0.95, 1.0))
	_add_graffiti_panel(root, Vector3(-0.5, 3.1, wall_z), Vector3(4.5, 0.35, 0.03), Color(0.12, 0.12, 0.14, 1.0))

	# "RIDE" letter blocks
	_add_graffiti_panel(root, Vector3(-3.2, 2.55, wall_z), Vector3(0.55, 0.9, 0.035), Color(1.0, 0.45, 0.1, 1.0))
	_add_graffiti_panel(root, Vector3(-2.4, 2.55, wall_z), Vector3(0.35, 0.9, 0.035), Color(1.0, 0.95, 0.2, 1.0))
	_add_graffiti_panel(root, Vector3(-1.5, 2.55, wall_z), Vector3(0.5, 0.9, 0.035), Color(0.2, 0.9, 1.0, 1.0))
	_add_graffiti_panel(root, Vector3(-0.6, 2.55, wall_z), Vector3(0.45, 0.9, 0.035), Color(0.95, 0.25, 0.75, 1.0))

	# Stars and spray dots
	for i in 6:
		var px := randf_range(-5.5, 5.5)
		var py := randf_range(0.9, 3.5)
		var sz := randf_range(0.15, 0.45)
		var hue := randf()
		_add_graffiti_panel(
			root,
			Vector3(px, py, wall_z),
			Vector3(sz, sz, 0.02),
			Color.from_hsv(hue, 0.85, 0.95, 1.0)
		)

func _add_graffiti_panel(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> void:
	var panel := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	panel.mesh = mesh
	panel.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.92
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.35
	panel.material_override = mat
	parent.add_child(panel)

func _add_box(name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = mat
	add_child(mesh)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat
