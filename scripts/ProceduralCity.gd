extends Node3D

@export var bike_path: NodePath
@export var chunk_size: float = 120.0
@export var load_radius: int = 4
@export var unload_radius: int = 6
@export var look_ahead_seconds: float = 3.0

var _loaded_chunks: Dictionary = {}
var _bike: Node3D

func _ready() -> void:
	_bike = get_node_or_null(bike_path)
	_clear_legacy_static_layout()
	if not _loaded_chunks.has("0:0"):
		_create_chunk(Vector2i.ZERO, "0:0")
	_refresh_chunks(true)

func _process(_delta: float) -> void:
	_refresh_chunks(false)

func _refresh_chunks(force: bool) -> void:
	if _bike == null:
		_bike = get_node_or_null(bike_path)
	var center_chunk: Vector2i = Vector2i.ZERO
	var ahead_chunk: Vector2i = Vector2i.ZERO
	if _bike != null:
		center_chunk = _world_to_chunk(_bike.global_position)
		var vel: Vector3 = Vector3.ZERO
		if _bike is CharacterBody3D:
			vel = (_bike as CharacterBody3D).velocity
		var projected_pos: Vector3 = _bike.global_position + Vector3(vel.x, 0.0, vel.z) * look_ahead_seconds
		ahead_chunk = _world_to_chunk(projected_pos)
	else:
		ahead_chunk = center_chunk
	var target_keys: Dictionary = {}
	for x in range(center_chunk.x - load_radius, center_chunk.x + load_radius + 1):
		for z in range(center_chunk.y - load_radius, center_chunk.y + load_radius + 1):
			var key: String = "%d:%d" % [x, z]
			target_keys[key] = true
			if force or not _loaded_chunks.has(key):
				_create_chunk(Vector2i(x, z), key)
	for x in range(ahead_chunk.x - load_radius, ahead_chunk.x + load_radius + 1):
		for z in range(ahead_chunk.y - load_radius, ahead_chunk.y + load_radius + 1):
			var key: String = "%d:%d" % [x, z]
			target_keys[key] = true
			if force or not _loaded_chunks.has(key):
				_create_chunk(Vector2i(x, z), key)
	if _bike != null:
		_ensure_chunk(center_chunk)
		_ensure_chunk(ahead_chunk)
	for key: String in _loaded_chunks.keys():
		var split: PackedStringArray = key.split(":")
		var cx: int = int(split[0])
		var cz: int = int(split[1])
		var should_keep: bool = target_keys.has(key)
		if not should_keep:
			if abs(cx - center_chunk.x) <= unload_radius and abs(cz - center_chunk.y) <= unload_radius:
				should_keep = true
			if abs(cx - ahead_chunk.x) <= unload_radius and abs(cz - ahead_chunk.y) <= unload_radius:
				should_keep = true
		if not should_keep:
			var chunk_node: Node3D = _loaded_chunks[key]
			chunk_node.queue_free()
			_loaded_chunks.erase(key)

func _world_to_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / chunk_size)), int(floor(pos.z / chunk_size)))

func _create_chunk(chunk_coord: Vector2i, key: String) -> void:
	var chunk_node := Node3D.new()
	chunk_node.name = "Chunk_%s" % key.replace(":", "_")
	chunk_node.position = Vector3(chunk_coord.x * chunk_size, 0.0, chunk_coord.y * chunk_size)
	add_child(chunk_node)
	_loaded_chunks[key] = chunk_node

	_add_ground(chunk_node)
	_add_roads(chunk_node)
	_add_city_blocks(chunk_node, chunk_coord)

func _add_ground(parent: Node3D) -> void:
	var ground_body := StaticBody3D.new()
	parent.add_child(ground_body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(chunk_size, 1.0, chunk_size)
	shape.shape = box
	ground_body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(chunk_size, 1.0, chunk_size)
	mesh.mesh = ground_mesh
	mesh.position = Vector3(0.0, -0.5, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.19, 0.2, 1.0)
	mat.roughness = 1.0
	mesh.material_override = mat
	ground_body.add_child(mesh)

func _add_roads(parent: Node3D) -> void:
	_add_road(parent, Vector3.ZERO, false)
	_add_road(parent, Vector3.ZERO, true)

func _add_road(parent: Node3D, pos: Vector3, rotated: bool) -> void:
	var road := StaticBody3D.new()
	road.position = pos + Vector3(0.0, 0.06, 0.0)
	if rotated:
		road.rotation.y = PI * 0.5
	parent.add_child(road)

	var road_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16.0, 0.1, chunk_size)
	road_shape.shape = box
	road.add_child(road_shape)

	var road_mesh := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(16.0, 0.1, chunk_size)
	road_mesh.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.12, 1.0)
	mat.roughness = 0.95
	road_mesh.material_override = mat
	road.add_child(road_mesh)

func _add_city_blocks(parent: Node3D, chunk_coord: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_seed(chunk_coord)

	var slots := [
		Vector3(-36.0, 0.0, -36.0),
		Vector3(36.0, 0.0, -36.0),
		Vector3(-36.0, 0.0, 36.0),
		Vector3(36.0, 0.0, 36.0),
		Vector3(-50.0, 0.0, 0.0),
		Vector3(50.0, 0.0, 0.0),
		Vector3(0.0, 0.0, -50.0),
		Vector3(0.0, 0.0, 50.0)
	]

	for slot: Vector3 in slots:
		if rng.randf() < 0.25:
			continue
		var building := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		var width := rng.randf_range(10.0, 20.0)
		var depth := rng.randf_range(10.0, 20.0)
		var height := rng.randf_range(8.0, 34.0)
		mesh.size = Vector3(width, height, depth)
		building.mesh = mesh
		building.position = slot + Vector3(rng.randf_range(-4.0, 4.0), height * 0.5, rng.randf_range(-4.0, 4.0))
		var mat := StandardMaterial3D.new()
		var base := 0.35 + rng.randf_range(-0.08, 0.1)
		mat.albedo_color = Color(base, base + 0.03, base + 0.06, 1.0)
		mat.roughness = 0.9
		building.material_override = mat
		parent.add_child(building)

func _chunk_seed(chunk_coord: Vector2i) -> int:
	var base_seed: int = int(GameState.world_seed)
	var x_part: int = chunk_coord.x * 92821
	var z_part: int = chunk_coord.y * 68917
	return abs(base_seed + x_part + z_part)

func _clear_legacy_static_layout() -> void:
	var legacy_nodes := ["Ground", "Road", "RoadCross", "OffroadPatch", "Sidewalk", "CityBlocks"]
	for node_name: String in legacy_nodes:
		var node := get_node_or_null(node_name)
		if node:
			node.queue_free()

func _ensure_chunk(chunk_coord: Vector2i) -> void:
	var key: String = "%d:%d" % [chunk_coord.x, chunk_coord.y]
	if not _loaded_chunks.has(key):
		_create_chunk(chunk_coord, key)
