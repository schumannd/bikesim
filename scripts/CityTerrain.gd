extends Object
class_name CityTerrain

enum Zone {
	SUBURB,
	BIG_STREET,
	SMALL_STREET,
	HIGHWAY,
	PARK,
	SCHOOL,
	STADIUM,
	TRAIN_STATION,
}

const CHUNK_SIZE := 120.0
const HEIGHT_SCALE := 5.5
const TRAIN_SPACING := 280.0
const TRAIN_HALF_WIDTH := 3.2

static func sample_height(world_x: float, world_z: float) -> float:
	var seed_f := float(GameState.world_seed % 10000) * 0.001
	var x := world_x * 0.011 + seed_f * 2.3
	var z := world_z * 0.013 + seed_f * 1.7
	var h := sin(x) * cos(z * 0.9) + sin(x * 2.4 + z * 1.8) * 0.45
	h += cos(x * 0.55 - z * 0.7) * 0.35
	var hills := h * HEIGHT_SCALE
	# Flatten spawn / garage neighborhood.
	var flat_r := 36.0
	var d := Vector2(world_x + 14.0, world_z + 10.0).length()
	if d < flat_r:
		hills *= d / flat_r
	return hills

static func sample_normal(world_x: float, world_z: float) -> Vector3:
	var e := 1.25
	var h := sample_height(world_x, world_z)
	var hx := sample_height(world_x + e, world_z) - h
	var hz := sample_height(world_x, world_z + e) - h
	return Vector3(-hx, e, -hz).normalized()

static func get_zone(world_x: float, world_z: float) -> Zone:
	if _is_highway_corridor(world_x, world_z):
		return Zone.HIGHWAY
	var chunk := world_to_chunk(world_x, world_z)
	var landmark := _landmark_zone(chunk)
	if landmark != Zone.SUBURB:
		return landmark
	var local := Vector2(
	 fposmod(world_x, CHUNK_SIZE) / CHUNK_SIZE,
	 fposmod(world_z, CHUNK_SIZE) / CHUNK_SIZE
	)
	var n := _hash_noise(chunk.x, chunk.y)
	if local.x < 0.22 or local.x > 0.78 or local.y < 0.22 or local.y > 0.78:
		return Zone.BIG_STREET
	match int(n * 7.0) % 5:
		0:
			return Zone.PARK
		1:
			return Zone.SUBURB
		2:
			return Zone.SMALL_STREET
		3:
			return Zone.SUBURB
		_:
			return Zone.BIG_STREET

static func world_to_chunk(world_x: float, world_z: float) -> Vector2i:
	return Vector2i(int(floor(world_x / CHUNK_SIZE)), int(floor(world_z / CHUNK_SIZE)))

static func is_train_corridor(world_x: float, world_z: float) -> bool:
	var seed_off := float(GameState.world_seed % 97)
	var band := world_x - world_z + seed_off * 0.35
	var dist := absf(fposmod(band + TRAIN_SPACING * 0.5, TRAIN_SPACING) - TRAIN_SPACING * 0.5)
	return dist < TRAIN_HALF_WIDTH + 1.8

static func train_track_distance(world_x: float, world_z: float) -> float:
	var seed_off := float(GameState.world_seed % 97)
	var band := world_x - world_z + seed_off * 0.35
	return absf(fposmod(band + TRAIN_SPACING * 0.5, TRAIN_SPACING) - TRAIN_SPACING * 0.5)

static func road_width_for_zone(zone: Zone) -> float:
	match zone:
		Zone.HIGHWAY:
			return 26.0
		Zone.BIG_STREET:
			return 18.0
		Zone.SMALL_STREET, Zone.SUBURB:
			return 10.0
		Zone.TRAIN_STATION:
			return 12.0
		_:
			return 8.0

static func zone_allows_buildings(zone: Zone) -> bool:
	return zone not in [Zone.PARK, Zone.STADIUM, Zone.SCHOOL, Zone.HIGHWAY]

static func zone_ground_color(zone: Zone) -> Color:
	match zone:
		Zone.PARK:
			return Color(0.22, 0.42, 0.2, 1.0)
		Zone.HIGHWAY:
			return Color(0.12, 0.12, 0.13, 1.0)
		Zone.SCHOOL:
			return Color(0.35, 0.38, 0.4, 1.0)
		Zone.STADIUM:
			return Color(0.18, 0.32, 0.22, 1.0)
		Zone.TRAIN_STATION:
			return Color(0.28, 0.27, 0.26, 1.0)
		Zone.SUBURB:
			return Color(0.3, 0.32, 0.28, 1.0)
		_:
			return Color(0.2, 0.21, 0.22, 1.0)

static func _is_highway_corridor(world_x: float, world_z: float) -> bool:
	return absf(world_x) < 18.0 or absf(world_z) < 18.0

static func _landmark_zone(chunk: Vector2i) -> Zone:
	var h := _chunk_hash(chunk)
	if h % 17 == 0:
		return Zone.SCHOOL
	if h % 19 == 3:
		return Zone.STADIUM
	if h % 13 == 1:
		return Zone.TRAIN_STATION
	return Zone.SUBURB

static func _chunk_hash(chunk: Vector2i) -> int:
	return abs(int(GameState.world_seed) + chunk.x * 92821 + chunk.y * 68917)

static func _hash_noise(cx: int, cz: int) -> float:
	var h := int(GameState.world_seed) + cx * 92821 + cz * 68917
	return float(abs(h % 10007)) / 10007.0
