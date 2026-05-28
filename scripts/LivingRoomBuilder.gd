extends Node3D

const InteriorNPCScript := preload("res://scripts/InteriorNPC.gd")

const FLOOR_SIZE := Vector3(11.0, 0.2, 9.0)
const WALL_HEIGHT := 3.2

var _npcs: Array[Node3D] = []

func _ready() -> void:
	_build_room()

func get_npcs() -> Array[Node3D]:
	return _npcs

func get_npc_count() -> int:
	return _npcs.size()

func _build_room() -> void:
	var floor_mat := _mat(Color(0.32, 0.26, 0.2, 1.0), 0.95)
	var wall_mat := _mat(Color(0.78, 0.74, 0.68, 1.0), 0.92)
	var fabric_mat := _mat(Color(0.22, 0.35, 0.52, 1.0), 1.0)
	var wood_mat := _mat(Color(0.45, 0.3, 0.18, 1.0), 0.85)

	_add_environment()
	_add_box("Floor", Vector3(0.0, -0.08, 0.0), FLOOR_SIZE, floor_mat)
	_add_box("Rug", Vector3(0.0, 0.01, 0.4), Vector3(5.5, 0.02, 4.0), _mat(Color(0.55, 0.2, 0.18, 1.0), 1.0))

	var half_x := FLOOR_SIZE.x * 0.5
	var half_z := FLOOR_SIZE.z * 0.5
	var wall_t := 0.2
	var wall_y := WALL_HEIGHT * 0.5
	_add_box("WallBack", Vector3(0.0, wall_y, -half_z), Vector3(FLOOR_SIZE.x, WALL_HEIGHT, wall_t), wall_mat)
	_add_box("WallFront", Vector3(0.0, wall_y, half_z * 0.85), Vector3(FLOOR_SIZE.x, WALL_HEIGHT, wall_t), wall_mat)
	_add_box("WallLeft", Vector3(-half_x, wall_y, 0.0), Vector3(wall_t, WALL_HEIGHT, FLOOR_SIZE.z), wall_mat)
	_add_box("WallRight", Vector3(half_x, wall_y, 0.0), Vector3(wall_t, WALL_HEIGHT, FLOOR_SIZE.z), wall_mat)

	_add_box("SofaBase", Vector3(-2.8, 0.35, -2.0), Vector3(2.6, 0.5, 1.1), fabric_mat)
	_add_box("SofaBack", Vector3(-2.8, 0.75, -2.45), Vector3(2.6, 0.7, 0.25), fabric_mat)
	_add_box("CoffeeTable", Vector3(0.2, 0.28, 0.6), Vector3(1.4, 0.08, 0.9), wood_mat)
	_add_box("TvStand", Vector3(3.2, 0.45, -2.6), Vector3(1.6, 0.5, 0.45), wood_mat)
	_add_box("TvScreen", Vector3(3.2, 1.05, -2.55), Vector3(1.5, 0.85, 0.08), _mat(Color(0.05, 0.06, 0.08, 1.0), 0.4))

	_add_phone_on_table()
	_add_lighting()
	_spawn_npcs()

func _spawn_npcs() -> void:
	var seed: int = int(GameState.current_house_seed)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var spots := [
		Vector3(2.6, 0.0, 1.8),
		Vector3(-0.8, 0.0, 2.4),
		Vector3(3.4, 0.0, -0.6),
	]
	var names := ["Alex", "Jordan", "Sam"]
	var line_sets: Array = [
		PackedStringArray(["Nice weather for a ride.", "Did you try the garage paint booth?", "I heard there's a wizard tower somewhere."]),
		PackedStringArray(["Want to play the stone game on my phone?", "I keep losing that sliding puzzle.", "The card trick is all about gentle pushes."]),
		PackedStringArray(["This city feels endless.", "I saw golden mist by the road earlier.", "Be careful near the tall buildings."]),
	]
	var count := rng.randi_range(2, 3)
	for i in range(count):
		var npc := Node3D.new()
		npc.name = "InteriorNPC_%d" % i
		npc.position = spots[i]
		npc.rotation.y = rng.randf_range(-0.5, 0.5)
		npc.set_script(InteriorNPCScript)
		add_child(npc)
		npc.call("setup", rng, names[i], line_sets[i])
		_npcs.append(npc)

func _add_phone_on_table() -> void:
	var phone_root := Node3D.new()
	phone_root.name = "PhoneProp"
	phone_root.position = Vector3(0.2, 0.38, 0.6)
	add_child(phone_root)

	var body := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.14, 0.02, 0.24)
	body.mesh = mesh
	body.material_override = _mat(Color(0.08, 0.08, 0.1, 1.0), 0.5)
	phone_root.add_child(body)

	var screen := MeshInstance3D.new()
	var screen_mesh := BoxMesh.new()
	screen_mesh.size = Vector3(0.12, 0.005, 0.2)
	screen.mesh = screen_mesh
	screen.position = Vector3(0.0, 0.014, 0.0)
	var screen_mat := _mat(Color(0.15, 0.18, 0.22, 1.0), 0.3)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.35, 0.45, 0.55, 1.0)
	screen_mat.emission_energy_multiplier = 0.4
	screen.material_override = screen_mat
	phone_root.add_child(screen)

	var zone := Area3D.new()
	zone.name = "PhoneZone"
	zone.position = Vector3(0.0, 0.08, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.35, 0.25, 0.45)
	shape.shape = box
	zone.add_child(shape)
	zone.set_meta("is_phone_zone", true)
	phone_root.add_child(zone)

func _add_environment() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.12, 0.1, 0.09, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.88, 0.78, 1.0)
	env.ambient_light_energy = 0.9
	world_env.environment = env
	add_child(world_env)

func _add_lighting() -> void:
	_add_omni(Vector3(0.0, 2.8, 0.5), 1.4, 14.0, Color(1.0, 0.92, 0.82, 1.0))
	_add_omni(Vector3(-3.0, 2.0, -1.0), 0.8, 10.0, Color(0.9, 0.95, 1.0, 1.0))
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(3.5, 2.2, 1.5)
	lamp.light_color = Color(1.0, 0.85, 0.6, 1.0)
	lamp.light_energy = 1.1
	lamp.omni_range = 8.0
	add_child(lamp)

func _add_omni(pos: Vector3, energy: float, range: float, color: Color) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range
	add_child(light)

func _add_box(name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = mat
	add_child(mesh_inst)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat
