extends Node3D
signal garage_zone_created(zone: Area3D)
signal wizard_tower_zone_created(zone: Area3D)
signal house_entrance_created(zone: Area3D)

@export var bike_path: NodePath
@export var chunk_size: float = 120.0
@export var load_radius: int = 5

const GARAGE_LOT_MIN := Vector3(-40.0, 0.0, -40.0)
const GARAGE_LOT_MAX := Vector3(-6.0, 0.0, -4.0)
const GARAGE_POSITION := Vector3(-18.0, 0.0, -16.0)
const ROAD_THICKNESS := 0.12
const TERRAIN_GRID := 20

const WorldPropBuilderScript := preload("res://scripts/WorldPropBuilder.gd")
const WorldNPCScript := preload("res://scripts/WorldNPC.gd")
const BikeRigScript := preload("res://scripts/BikeRig.gd")
const CityTerrainScript := preload("res://scripts/CityTerrain.gd")
const WorldLandmarksScript := preload("res://scripts/WorldLandmarks.gd")

var _loaded_chunks: Dictionary = {}
var _bike: Node3D
var _road_material: StandardMaterial3D
var _highway_material: StandardMaterial3D

func _ready() -> void:
	_bike = get_node_or_null(bike_path)
	_clear_legacy_static_layout()
	_road_material = StandardMaterial3D.new()
	_road_material.albedo_color = Color(0.1, 0.1, 0.12, 1.0)
	_road_material.roughness = 0.95
	_highway_material = StandardMaterial3D.new()
	_highway_material.albedo_color = Color(0.08, 0.08, 0.09, 1.0)
	_highway_material.roughness = 0.92
	if not _loaded_chunks.has("0:0"):
		_create_chunk(Vector2i.ZERO, "0:0", Vector2i.ZERO)
	_refresh_chunks(true)

func _process(_delta: float) -> void:
	_refresh_chunks(false)

func _refresh_chunks(force: bool) -> void:
	if _bike == null:
		_bike = get_node_or_null(bike_path)
	if _bike == null:
		return
	var center_chunk: Vector2i = _world_to_chunk(_bike.global_position)
	var target_keys: Dictionary = {}
	for x in range(center_chunk.x - load_radius, center_chunk.x + load_radius + 1):
		for z in range(center_chunk.y - load_radius, center_chunk.y + load_radius + 1):
			var key: String = "%d:%d" % [x, z]
			target_keys[key] = true
			if force or not _loaded_chunks.has(key):
				_create_chunk(Vector2i(x, z), key, center_chunk)

	for key: String in _loaded_chunks.keys():
		if not target_keys.has(key):
			var chunk_node: Node3D = _loaded_chunks[key]
			chunk_node.queue_free()
			_loaded_chunks.erase(key)

func _world_to_chunk(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / chunk_size)), int(floor(pos.z / chunk_size)))

func _create_chunk(chunk_coord: Vector2i, key: String, center_chunk: Vector2i) -> void:
	var chunk_node := Node3D.new()
	chunk_node.name = "Chunk_%s" % key.replace(":", "_")
	chunk_node.position = Vector3(chunk_coord.x * chunk_size, 0.0, chunk_coord.y * chunk_size)
	add_child(chunk_node)
	_loaded_chunks[key] = chunk_node

	var rng := RandomNumberGenerator.new()
	rng.seed = _chunk_seed(chunk_coord)

	var center_wx := (float(chunk_coord.x) + 0.5) * chunk_size
	var center_wz := (float(chunk_coord.y) + 0.5) * chunk_size
	var zone: CityTerrainScript.Zone = CityTerrainScript.get_zone(center_wx, center_wz)

	_add_height_terrain(chunk_node, chunk_coord, zone)
	_add_roads(chunk_node, chunk_coord, zone)
	WorldLandmarksScript.add_train_tracks(chunk_node, chunk_coord, chunk_size)

	var local_center := Vector3(chunk_size * 0.5, 0.0, chunk_size * 0.5)
	match zone:
		CityTerrainScript.Zone.SCHOOL:
			WorldLandmarksScript.add_school(chunk_node, local_center, chunk_coord, chunk_size)
		CityTerrainScript.Zone.STADIUM:
			WorldLandmarksScript.add_stadium(chunk_node, local_center, chunk_coord, chunk_size)
		CityTerrainScript.Zone.TRAIN_STATION:
			WorldLandmarksScript.add_train_station(chunk_node, local_center, chunk_coord, chunk_size)
		CityTerrainScript.Zone.PARK:
			_add_park_trees(chunk_node, chunk_coord, rng)

	if chunk_coord == Vector2i.ZERO:
		_add_garage(chunk_node, chunk_coord)
	if chunk_coord == GameState.wizard_tower_chunk():
		_add_wizard_tower(chunk_node, chunk_coord)
	if CityTerrainScript.zone_allows_buildings(zone):
		_add_city_blocks(chunk_node, chunk_coord, rng)
	WorldPropBuilderScript.populate_chunk(chunk_node, rng, chunk_coord, zone)
	_add_chunk_npcs(chunk_node, chunk_coord, center_chunk, rng)

func _add_height_terrain(parent: Node3D, chunk_coord: Vector2i, zone: CityTerrainScript.Zone) -> void:
	var cell := chunk_size / float(TERRAIN_GRID)
	var ox := float(chunk_coord.x) * chunk_size
	var oz := float(chunk_coord.y) * chunk_size
	var vert_count := (TERRAIN_GRID + 1) * (TERRAIN_GRID + 1)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	verts.resize(vert_count)
	normals.resize(vert_count)
	uvs.resize(vert_count)

	var vi := 0
	for gz in TERRAIN_GRID + 1:
		for gx in TERRAIN_GRID + 1:
			var wx := ox + float(gx) * cell
			var wz := oz + float(gz) * cell
			var h := CityTerrainScript.sample_height(wx, wz)
			verts[vi] = Vector3(float(gx) * cell, h, float(gz) * cell)
			normals[vi] = CityTerrainScript.sample_normal(wx, wz)
			uvs[vi] = Vector2(float(gx) / TERRAIN_GRID, float(gz) / TERRAIN_GRID)
			vi += 1

	for gz in TERRAIN_GRID:
		for gx in TERRAIN_GRID:
			var i := gz * (TERRAIN_GRID + 1) + gx
			indices.append_array([i, i + TERRAIN_GRID + 1, i + 1, i + 1, i + TERRAIN_GRID + 1, i + TERRAIN_GRID + 2])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = CityTerrainScript.zone_ground_color(zone)
	ground_mat.roughness = 1.0

	var mesh_inst := MeshInstance3D.new()
	mesh_inst.name = "TerrainMesh"
	mesh_inst.mesh = array_mesh
	mesh_inst.material_override = ground_mat
	parent.add_child(mesh_inst)

	var body := StaticBody3D.new()
	body.name = "RideSurface"
	parent.add_child(body)
	var shape_node := CollisionShape3D.new()
	# Trimesh matches the visual mesh. HeightMapShape3D + non-uniform scale breaks physics.
	shape_node.shape = array_mesh.create_trimesh_shape()
	body.add_child(shape_node)

func _add_roads(parent: Node3D, chunk_coord: Vector2i, zone: CityTerrainScript.Zone) -> void:
	var road_body := StaticBody3D.new()
	road_body.name = "RoadNetwork"
	parent.add_child(road_body)

	var road_w := CityTerrainScript.road_width_for_zone(zone)
	var half_chunk := chunk_size * 0.5
	var half_road := road_w * 0.5
	var arm_length := maxf(half_chunk - half_road, 8.0)
	var mat := _highway_material if zone == CityTerrainScript.Zone.HIGHWAY else _road_material

	if zone == CityTerrainScript.Zone.PARK:
		_add_road_segment(road_body, chunk_coord, Vector3(half_chunk, 0.0, half_chunk * 0.5), Vector3(4.0, ROAD_THICKNESS, half_chunk), mat)
		_add_road_segment(road_body, chunk_coord, Vector3(half_chunk * 0.5, 0.0, half_chunk), Vector3(half_chunk, ROAD_THICKNESS, 4.0), mat)
		return

	_add_road_segment(road_body, chunk_coord, Vector3(half_chunk, 0.0, half_chunk), Vector3(road_w, ROAD_THICKNESS, road_w), mat)
	_add_road_segment(road_body, chunk_coord, Vector3(half_chunk, 0.0, half_road + arm_length * 0.5), Vector3(road_w, ROAD_THICKNESS, arm_length), mat)
	_add_road_segment(road_body, chunk_coord, Vector3(half_chunk, 0.0, half_chunk - (half_road + arm_length * 0.5)), Vector3(road_w, ROAD_THICKNESS, arm_length), mat)
	_add_road_segment(road_body, chunk_coord, Vector3(half_road + arm_length * 0.5, 0.0, half_chunk), Vector3(arm_length, ROAD_THICKNESS, road_w), mat)
	_add_road_segment(road_body, chunk_coord, Vector3(half_chunk - (half_road + arm_length * 0.5), 0.0, half_chunk), Vector3(arm_length, ROAD_THICKNESS, road_w), mat)

	if zone == CityTerrainScript.Zone.SUBURB or zone == CityTerrainScript.Zone.SMALL_STREET:
		var lane := 22.0
		_add_road_segment(road_body, chunk_coord, Vector3(lane, 0.0, half_chunk), Vector3(6.0, ROAD_THICKNESS, arm_length * 0.85), mat)
		_add_road_segment(road_body, chunk_coord, Vector3(chunk_size - lane, 0.0, half_chunk), Vector3(6.0, ROAD_THICKNESS, arm_length * 0.85), mat)

func _add_road_segment(road_body: StaticBody3D, chunk_coord: Vector2i, local_pos: Vector3, size: Vector3, mat: Material) -> void:
	var wx := chunk_coord.x * chunk_size + local_pos.x
	var wz := chunk_coord.y * chunk_size + local_pos.z
	var hy := CityTerrainScript.sample_height(wx, wz)
	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	mesh_inst.position = Vector3(local_pos.x, hy + ROAD_THICKNESS * 0.5, local_pos.z)
	mesh_inst.material_override = mat
	road_body.add_child(mesh_inst)

func _add_park_trees(parent: Node3D, chunk_coord: Vector2i, rng: RandomNumberGenerator) -> void:
	for i in 18:
		var lx := rng.randf_range(8.0, chunk_size - 8.0)
		var lz := rng.randf_range(8.0, chunk_size - 8.0)
		var wx := chunk_coord.x * chunk_size + lx
		var wz := chunk_coord.y * chunk_size + lz
		var hy := CityTerrainScript.sample_height(wx, wz)
		WorldPropBuilderScript.add_tree_at(parent, Vector3(lx, hy, lz), rng)

func _add_chunk_npcs(parent: Node3D, chunk_coord: Vector2i, center_chunk: Vector2i, rng: RandomNumberGenerator) -> void:
	var dist: int = maxi(absi(chunk_coord.x - center_chunk.x), absi(chunk_coord.y - center_chunk.y))
	if dist > 3:
		return
	var npc_count := 1 if dist > 2 else rng.randi_range(2, 4)
	var npc_root := Node3D.new()
	npc_root.name = "NPCs"
	parent.add_child(npc_root)
	for i in npc_count:
		var spawn := _pick_npc_spawn(rng, chunk_coord)
		if spawn == Vector3.INF:
			continue
		var npc := Node3D.new()
		npc.name = "NPC_%d" % i
		npc.set_script(WorldNPCScript)
		npc_root.add_child(npc)
		npc.call("setup_from_rng", rng, spawn)

func _pick_npc_spawn(rng: RandomNumberGenerator, chunk_coord: Vector2i) -> Vector3:
	for _attempt in 12:
		var lx := rng.randf_range(12.0, chunk_size - 12.0)
		var lz := rng.randf_range(12.0, chunk_size - 12.0)
		if chunk_coord == Vector2i.ZERO and Vector3(lx, 0.0, lz).distance_to(GARAGE_POSITION) < 20.0:
			continue
		var wx := chunk_coord.x * chunk_size + lx
		var wz := chunk_coord.y * chunk_size + lz
		var hy := CityTerrainScript.sample_height(wx, wz)
		return Vector3(wx, hy, wz)
	return Vector3.INF

func _add_city_blocks(parent: Node3D, chunk_coord: Vector2i, rng: RandomNumberGenerator) -> void:
	var slots := [
		Vector3(-36.0, 0.0, -36.0), Vector3(36.0, 0.0, -36.0),
		Vector3(-36.0, 0.0, 36.0), Vector3(36.0, 0.0, 36.0),
		Vector3(-50.0, 0.0, 0.0), Vector3(50.0, 0.0, 0.0),
		Vector3(0.0, 0.0, -50.0), Vector3(0.0, 0.0, 50.0)
	]
	var enterable_added := false
	for slot: Vector3 in slots:
		if rng.randf() < 0.25:
			continue
		var building := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		var mesh := BoxMesh.new()
		var width := rng.randf_range(10.0, 20.0)
		var depth := rng.randf_range(10.0, 20.0)
		var height := rng.randf_range(8.0, 34.0)
		mesh.size = Vector3(width, height, depth)
		shape.size = mesh.size
		collision.shape = shape
		var pos := slot + Vector3(rng.randf_range(-4.0, 4.0), 0.0, rng.randf_range(-4.0, 4.0))
		if chunk_coord == Vector2i.ZERO and _overlaps_garage_lot(pos, mesh.size):
			building.queue_free()
			continue
		var wx := chunk_coord.x * chunk_size + pos.x
		var wz := chunk_coord.y * chunk_size + pos.z
		var ground_y := CityTerrainScript.sample_height(wx, wz)
		building.position = Vector3(pos.x, ground_y, pos.z)
		building.add_child(collision)
		var building_mesh := MeshInstance3D.new()
		building_mesh.mesh = mesh
		building_mesh.position = Vector3(0.0, height * 0.5, 0.0)
		var mat := StandardMaterial3D.new()
		var base := 0.35 + rng.randf_range(-0.08, 0.1)
		mat.albedo_color = Color(base, base + 0.03, base + 0.06, 1.0)
		mat.roughness = 0.9
		building_mesh.material_override = mat
		building.add_child(building_mesh)
		WorldPropBuilderScript.add_building_windows(building, mesh.size, rng)
		parent.add_child(building)
		if not enterable_added:
			_add_building_entrance(parent, building, mesh.size, chunk_coord)
			enterable_added = true

func _add_building_entrance(parent: Node3D, building: StaticBody3D, size: Vector3, chunk_coord: Vector2i) -> void:
	var zone := Area3D.new()
	zone.name = "HouseEntrance"
	var toward_center := Vector3(-building.position.x, 0.0, -building.position.z)
	if toward_center.length_squared() < 0.01:
		toward_center = Vector3(0.0, 0.0, 1.0)
	toward_center = toward_center.normalized()
	var door_offset := toward_center * (size.z * 0.5 + 2.4)
	zone.position = building.position + door_offset + Vector3(0.0, 1.2, 0.0)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.4, 2.8, 3.4)
	shape.shape = box
	zone.add_child(shape)
	zone.set_meta("is_house_entrance", true)
	var seed := _chunk_seed(chunk_coord) ^ int(building.position.x * 19.0 + building.position.z * 37.0)
	zone.set_meta("house_seed", seed)
	zone.monitoring = true
	parent.add_child(zone)
	_add_entrance_marker(parent, zone.position)
	house_entrance_created.emit(zone)

func _add_entrance_marker(chunk_parent: Node3D, door_pos: Vector3) -> void:
	var marker := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.6, 2.4, 0.15)
	marker.mesh = mesh
	marker.position = door_pos + Vector3(0.0, 1.3, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.75, 0.35, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.85, 0.4, 1.0)
	mat.emission_energy_multiplier = 0.6
	marker.material_override = mat
	chunk_parent.add_child(marker)

func _overlaps_garage_lot(building_pos: Vector3, building_size: Vector3) -> bool:
	var half := Vector3(building_size.x * 0.5, 0.0, building_size.z * 0.5)
	var bmin := building_pos - half
	var bmax := building_pos + Vector3(half.x, building_size.y, half.z)
	return not (bmax.x < GARAGE_LOT_MIN.x or bmin.x > GARAGE_LOT_MAX.x or bmax.z < GARAGE_LOT_MIN.z or bmin.z > GARAGE_LOT_MAX.z)

func _chunk_seed(chunk_coord: Vector2i) -> int:
	var base_seed: int = int(GameState.world_seed)
	return abs(base_seed + chunk_coord.x * 92821 + chunk_coord.y * 68917)

func _clear_legacy_static_layout() -> void:
	var legacy_nodes := ["Ground", "Road", "RoadCross", "OffroadPatch", "Sidewalk", "CityBlocks", "GlobalTerrain"]
	for node_name: String in legacy_nodes:
		var node := get_node_or_null(node_name)
		if node:
			remove_child(node)
			node.free()

func _add_garage(parent: Node3D, chunk_coord: Vector2i) -> void:
	var garage := Node3D.new()
	garage.name = "GarageBuilding"
	garage.position = GARAGE_POSITION
	parent.add_child(garage)
	var wall_mat := _garage_material(Color(1.0, 0.55, 0.08, 1.0), 0.35)
	var trim_mat := _garage_material(Color(1.0, 0.95, 0.2, 1.0), 1.0)
	var interior_mat := _garage_material(Color(0.15, 0.35, 0.9, 1.0), 0.8)
	var pad_mat := _garage_material(Color(1.0, 0.95, 0.2, 1.0), 1.2)
	var width := 14.0
	var depth := 10.0
	var height := 7.0
	var wall_t := 1.1
	var door_w := 5.2
	var door_h := 4.2
	_add_garage_box(garage, "ApproachPad", Vector3(0.0, 0.03, 7.2), Vector3(door_w + 2.4, 0.06, 5.0), pad_mat, false)
	var floor_thickness := 0.12
	var garage_ground_y := CityTerrainScript.sample_height(
		chunk_coord.x * chunk_size + GARAGE_POSITION.x,
		chunk_coord.y * chunk_size + GARAGE_POSITION.z
	)
	_add_garage_box(garage, "Floor", Vector3(0.0, garage_ground_y - floor_thickness * 0.5, 0.0), Vector3(width, floor_thickness, depth), pad_mat, true)
	_add_garage_box(garage, "BackWall", Vector3(0.0, height * 0.5, -depth * 0.5 + wall_t * 0.5), Vector3(width, height, wall_t), wall_mat, true)
	_add_garage_box(garage, "LeftWall", Vector3(-width * 0.5 + wall_t * 0.5, height * 0.5, 0.0), Vector3(wall_t, height, depth), wall_mat, true)
	_add_garage_box(garage, "RightWall", Vector3(width * 0.5 - wall_t * 0.5, height * 0.5, 0.0), Vector3(wall_t, height, depth), wall_mat, true)
	var side_span := (width - door_w) * 0.5
	_add_garage_box(garage, "FrontLeftPillar", Vector3(-door_w * 0.5 - side_span * 0.5, height * 0.5, depth * 0.5 - wall_t * 0.5), Vector3(side_span, height, wall_t), wall_mat, true)
	_add_garage_box(garage, "FrontRightPillar", Vector3(door_w * 0.5 + side_span * 0.5, height * 0.5, depth * 0.5 - wall_t * 0.5), Vector3(side_span, height, wall_t), wall_mat, true)
	_add_garage_box(garage, "DoorLintel", Vector3(0.0, height - (height - door_h) * 0.5, depth * 0.5 - wall_t * 0.5), Vector3(door_w, height - door_h, wall_t), wall_mat, true)
	_add_garage_box(garage, "DoorInterior", Vector3(0.0, door_h * 0.5, depth * 0.5 - 1.2), Vector3(door_w - 0.4, door_h - 0.2, 1.6), interior_mat, false)
	_add_garage_box(garage, "DoorFrameL", Vector3(-door_w * 0.5 - 0.12, door_h * 0.5, depth * 0.5 + 0.1), Vector3(0.2, door_h, 0.25), trim_mat, false)
	_add_garage_box(garage, "DoorFrameR", Vector3(door_w * 0.5 + 0.12, door_h * 0.5, depth * 0.5 + 0.1), Vector3(0.2, door_h, 0.25), trim_mat, false)
	_add_garage_box(garage, "DoorRamp", Vector3(0.0, 0.12, depth * 0.5 + 2.0), Vector3(door_w, 0.24, 2.8), trim_mat, false)
	var sign := MeshInstance3D.new()
	sign.name = "GarageSign"
	var sign_mesh := BoxMesh.new()
	sign_mesh.size = Vector3(6.0, 1.4, 0.3)
	sign.mesh = sign_mesh
	sign.position = Vector3(0.0, height + 0.5, depth * 0.5 + 0.2)
	sign.material_override = trim_mat
	garage.add_child(sign)
	var beacon := OmniLight3D.new()
	beacon.name = "GarageBeacon"
	beacon.position = Vector3(0.0, 4.5, depth * 0.5 + 2.5)
	beacon.light_color = Color(1.0, 0.6, 0.1, 1.0)
	beacon.light_energy = 2.8
	beacon.omni_range = 18.0
	garage.add_child(beacon)
	var zone := Area3D.new()
	zone.name = "GarageEntranceZone"
	zone.monitoring = true
	zone.position = Vector3(0.0, 2.0, depth * 0.5 + 5.5)
	zone.set_meta("is_garage_zone", true)
	garage.add_child(zone)
	var zone_shape_node := CollisionShape3D.new()
	var zone_shape := BoxShape3D.new()
	zone_shape.size = Vector3(door_w + 6.0, 5.0, 12.0)
	zone_shape_node.shape = zone_shape
	zone.add_child(zone_shape_node)
	garage_zone_created.emit(zone)

func _add_wizard_tower(parent: Node3D, chunk_coord: Vector2i) -> void:
	var tower := Node3D.new()
	tower.name = "WizardTower"
	tower.position = GameState.wizard_tower_local_position()
	parent.add_child(tower)
	GameState.wizard_tower_world_position = GameState.wizard_tower_world_position_for_chunk(chunk_coord)
	var stone := _wizard_material(Color(0.42, 0.18, 0.72, 1.0), 0.9, 1.4)
	var stone_dark := _wizard_material(Color(0.28, 0.1, 0.5, 1.0), 0.95, 0.8)
	var glow := _wizard_material(Color(0.75, 0.45, 1.0, 1.0), 0.2, 2.2)
	var roof := _wizard_material(Color(0.22, 0.08, 0.38, 1.0), 0.85, 0.5)
	_add_garage_box(tower, "Foundation", Vector3(0.0, 0.2, 0.0), Vector3(9.0, 0.4, 9.0), stone_dark, true)
	_add_garage_box(tower, "TowerBase", Vector3(0.0, 2.5, 0.0), Vector3(6.0, 5.0, 6.0), stone, true)
	_add_garage_box(tower, "TowerMid", Vector3(0.0, 6.8, 0.0), Vector3(4.8, 4.2, 4.8), stone, true)
	_add_garage_box(tower, "TowerTop", Vector3(0.0, 10.2, 0.0), Vector3(3.6, 3.0, 3.6), stone_dark, true)
	_add_garage_box(tower, "Roof", Vector3(0.0, 12.8, 0.0), Vector3(4.4, 1.6, 4.4), roof, false)
	_add_garage_box(tower, "Spire", Vector3(0.0, 14.6, 0.0), Vector3(0.5, 2.4, 0.5), glow, false)
	_add_garage_box(tower, "DoorGlow", Vector3(0.0, 1.4, 3.15), Vector3(2.2, 2.6, 0.2), glow, false)
	var zone := Area3D.new()
	zone.name = "WizardTowerEntrance"
	zone.monitoring = true
	zone.position = Vector3(0.0, 1.5, 4.2)
	zone.set_meta("is_wizard_tower_zone", true)
	tower.add_child(zone)
	var zone_shape_node := CollisionShape3D.new()
	var zone_shape := BoxShape3D.new()
	zone_shape.size = Vector3(5.0, 4.0, 5.0)
	zone_shape_node.shape = zone_shape
	zone.add_child(zone_shape_node)
	wizard_tower_zone_created.emit(zone)

func _wizard_material(color: Color, roughness: float, emission_energy: float) -> StandardMaterial3D:
	var mat := _garage_material(color, emission_energy)
	mat.roughness = roughness
	return mat

func _garage_material(color: Color, emission_energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	if emission_energy > 0.5:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission_energy
	return mat

func _add_garage_box(parent: Node3D, box_name: String, pos: Vector3, size: Vector3, mat: Material, with_collision: bool) -> void:
	var body := StaticBody3D.new()
	body.name = box_name
	body.position = pos
	parent.add_child(body)
	if with_collision:
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
	var mesh_node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_node.mesh = mesh
	mesh_node.material_override = mat
	body.add_child(mesh_node)
