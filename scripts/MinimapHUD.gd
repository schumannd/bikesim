extends Panel

const MAP_INSET := 5.0
const MAP_SIZE := 120.0
const MAP_CENTER := Vector2(MAP_INSET + MAP_SIZE * 0.5, MAP_INSET + MAP_SIZE * 0.5)
const VIEW_RADIUS_METERS := 95.0
const MARKER_SIZE := 8.0

var _poi_layer: Control
var _player_marker: ColorRect
var _legend: Label
var _poi_defs: Array[Dictionary] = []
var _poi_nodes: Dictionary = {}

func _ready() -> void:
	_build_nodes()

func set_points_of_interest(pois: Array) -> void:
	_poi_defs.clear()
	for entry in pois:
		if entry is Dictionary and entry.has("id") and entry.has("world_position"):
			_poi_defs.append(entry)
	_rebuild_poi_nodes()

func update_for_player(player_world: Vector3) -> void:
	if _player_marker:
		_player_marker.position = MAP_CENTER - Vector2(MARKER_SIZE * 0.5, MARKER_SIZE * 0.5)

	var scale: float = (MAP_SIZE * 0.5) / VIEW_RADIUS_METERS
	for poi_def: Dictionary in _poi_defs:
		var id: String = str(poi_def["id"])
		var marker: ColorRect = _poi_nodes.get(id)
		if marker == null:
			continue
		var world_pos: Vector3 = poi_def["world_position"]
		var offset := Vector2(world_pos.x - player_world.x, world_pos.z - player_world.z)
		var map_pos: Vector2 = MAP_CENTER + offset * scale
		map_pos = _clamp_to_map(map_pos)
		marker.position = map_pos - Vector2(MARKER_SIZE * 0.5, MARKER_SIZE * 0.5)
		marker.visible = offset.length() > 1.5

func _build_nodes() -> void:
	var bg := get_node_or_null("MapBackground")
	if bg == null:
		var background := ColorRect.new()
		background.name = "MapBackground"
		background.offset_left = MAP_INSET
		background.offset_top = MAP_INSET
		background.offset_right = MAP_INSET + MAP_SIZE
		background.offset_bottom = MAP_INSET + MAP_SIZE
		background.color = Color(0.08, 0.1, 0.11, 0.85)
		add_child(background)

	_poi_layer = Control.new()
	_poi_layer.name = "POILayer"
	_poi_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_poi_layer)

	_player_marker = ColorRect.new()
	_player_marker.name = "PlayerMarker"
	_player_marker.size = Vector2(MARKER_SIZE, MARKER_SIZE)
	_player_marker.color = Color(0.25, 0.85, 1.0, 1.0)
	add_child(_player_marker)

	_legend = Label.new()
	_legend.name = "Legend"
	_legend.offset_left = MAP_INSET + 4.0
	_legend.offset_top = MAP_INSET + MAP_SIZE - 36.0
	_legend.offset_right = MAP_INSET + MAP_SIZE - 4.0
	_legend.offset_bottom = MAP_INSET + MAP_SIZE - 4.0
	_legend.add_theme_font_size_override("font_size", 10)
	_legend.text = "You (center)\nOrange = Garage\nCyan = Checkpoint"
	add_child(_legend)

func _rebuild_poi_nodes() -> void:
	if _poi_layer == null:
		return
	for child in _poi_layer.get_children():
		child.queue_free()
	_poi_nodes.clear()

	for poi_def: Dictionary in _poi_defs:
		var marker := ColorRect.new()
		marker.name = "POI_%s" % str(poi_def["id"])
		marker.size = Vector2(MARKER_SIZE, MARKER_SIZE)
		marker.color = poi_def.get("color", Color.WHITE)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_poi_layer.add_child(marker)
		_poi_nodes[str(poi_def["id"])] = marker

func _clamp_to_map(map_pos: Vector2) -> Vector2:
	var min_pos := Vector2(MAP_INSET + MARKER_SIZE * 0.5, MAP_INSET + MARKER_SIZE * 0.5)
	var max_pos := Vector2(MAP_INSET + MAP_SIZE - MARKER_SIZE * 0.5, MAP_INSET + MAP_SIZE - MARKER_SIZE * 0.5)
	return Vector2(
		clampf(map_pos.x, min_pos.x, max_pos.x),
		clampf(map_pos.y, min_pos.y, max_pos.y)
	)
