extends Node3D

const BikeConfigResource := preload("res://resources/BikeConfig.gd")
const CharacterConfigResource := preload("res://resources/CharacterConfig.gd")
const BikeRigScript := preload("res://scripts/BikeRig.gd")
const BikeVisualBuilderScript := preload("res://scripts/BikeVisualBuilder.gd")
const RiderVisualBuilderScript := preload("res://scripts/RiderVisualBuilder.gd")

enum Behavior { IDLE, WALK, CYCLE }

var behavior: Behavior = Behavior.IDLE
var _speed: float = 2.0
var _phase: float = 0.0
var _path_progress: float = 0.0
var _path_from: Vector3 = Vector3.ZERO
var _path_to: Vector3 = Vector3.ZERO
var _path_dir: float = 1.0
var _idle_yaw: float = 0.0
var _bike_root: Node3D
var _bike_visual: Node3D
var _rider_visual: Node3D
var _walk_bob: Node3D

func setup_from_rng(rng: RandomNumberGenerator, start_pos: Vector3) -> void:
	position = start_pos
	var roll := rng.randf()
	if roll < 0.38:
		behavior = Behavior.CYCLE
	elif roll < 0.72:
		behavior = Behavior.WALK
	else:
		behavior = Behavior.IDLE

	_speed = rng.randf_range(1.8, 4.5)
	_phase = rng.randf_range(0.0, TAU)
	_idle_yaw = rng.randf_range(0.0, TAU)
	_build_path(rng, start_pos)

	var bike_cfg := _random_bike_config(rng)
	var char_cfg := _random_character_config(rng)

	match behavior:
		Behavior.CYCLE:
			_build_cyclist(bike_cfg, char_cfg)
		Behavior.WALK:
			_build_pedestrian(char_cfg)
		Behavior.IDLE:
			_build_pedestrian(char_cfg)
			rotation.y = _idle_yaw

func _build_path(rng: RandomNumberGenerator, start_pos: Vector3) -> void:
	var along_x := absf(start_pos.x) > absf(start_pos.z)
	var span := rng.randf_range(14.0, 36.0)
	if along_x:
		_path_from = start_pos + Vector3(-span * 0.5, 0.0, 0.0)
		_path_to = start_pos + Vector3(span * 0.5, 0.0, 0.0)
	else:
		_path_from = start_pos + Vector3(0.0, 0.0, -span * 0.5)
		_path_to = start_pos + Vector3(0.0, 0.0, span * 0.5)
	_path_progress = rng.randf()
	_path_dir = 1.0 if rng.randf() > 0.5 else -1.0

func _build_cyclist(bike_cfg: Resource, char_cfg: Resource) -> void:
	_bike_root = Node3D.new()
	_bike_root.name = "BikeRoot"
	add_child(_bike_root)

	_bike_visual = Node3D.new()
	_bike_visual.name = "BikeVisual"
	_bike_visual.set_script(BikeVisualBuilderScript)
	_bike_root.add_child(_bike_visual)

	_rider_visual = Node3D.new()
	_rider_visual.name = "RiderVisual"
	_rider_visual.set_script(RiderVisualBuilderScript)
	_bike_root.add_child(_rider_visual)

	_bike_visual.call("apply_config", bike_cfg)
	_rider_visual.call("apply_config", char_cfg)
	_bike_visual.call("mount_rider", _rider_visual)

func _build_pedestrian(char_cfg: Resource) -> void:
	_walk_bob = Node3D.new()
	_walk_bob.name = "Pedestrian"
	add_child(_walk_bob)

	_rider_visual = Node3D.new()
	_rider_visual.name = "RiderVisual"
	_rider_visual.set_script(RiderVisualBuilderScript)
	_walk_bob.add_child(_rider_visual)
	_rider_visual.call("apply_config", char_cfg)

func _process(delta: float) -> void:
	match behavior:
		Behavior.IDLE:
			_tick_idle(delta)
		Behavior.WALK:
			_tick_walk(delta)
		Behavior.CYCLE:
			_tick_cycle(delta)

func _tick_idle(delta: float) -> void:
	_phase += delta
	if _rider_visual:
		_rider_visual.call("animate_idle", _phase)

func _tick_walk(delta: float) -> void:
	var path_len := _path_from.distance_to(_path_to)
	if path_len < 0.5:
		return
	_path_progress += delta * _speed / path_len * _path_dir
	if _path_progress > 1.0:
		_path_progress = 1.0
		_path_dir = -1.0
	elif _path_progress < 0.0:
		_path_progress = 0.0
		_path_dir = 1.0

	var t := _path_progress
	var pos := _path_from.lerp(_path_to, t)
	var move_dir := (_path_to - _path_from).normalized() * _path_dir
	position = pos
	rotation.y = atan2(move_dir.x, move_dir.z)

	_phase += delta * _speed * 2.4
	if _walk_bob:
		_walk_bob.position.y = absf(sin(_phase * 2.0)) * 0.04
	if _rider_visual:
		_rider_visual.call("animate_walk", _phase, clampf(_speed / 4.0, 0.35, 1.0))

func _tick_cycle(delta: float) -> void:
	var path_len := _path_from.distance_to(_path_to)
	if path_len < 0.5 or _bike_root == null:
		return
	_path_progress += delta * _speed / path_len * _path_dir
	if _path_progress > 1.0:
		_path_progress = 1.0
		_path_dir = -1.0
	elif _path_progress < 0.0:
		_path_progress = 0.0
		_path_dir = 1.0

	var t := _path_progress
	var pos := _path_from.lerp(_path_to, t)
	var move_dir := (_path_to - _path_from).normalized() * _path_dir
	position = pos
	rotation.y = atan2(move_dir.x, move_dir.z)
	if _bike_root != null:
		_bike_root.position = Vector3.ZERO
		_bike_root.rotation = Vector3.ZERO

	_phase += delta * _speed * 1.8
	if _bike_visual:
		_bike_visual.call("animate_drive", _speed * _path_dir, delta)
	if _rider_visual:
		_rider_visual.call("animate_pedaling", _phase, clampf(_speed / 5.0, 0.4, 1.0))

func _random_bike_config(rng: RandomNumberGenerator) -> Resource:
	var cfg: Resource = BikeConfigResource.new()
	var frames: Array[String] = ["trail", "enduro", "downhill", "xc"]
	var wheels: Array[String] = ["mtb_29", "mtb_27_5", "mtb_plus", "gravel_700"]
	var forks: Array[String] = ["trail_susp", "dh_susp", "rigid_carbon", "rigid_steel"]
	cfg.frame_id = frames[rng.randi_range(0, frames.size() - 1)]
	cfg.wheel_id = wheels[rng.randi_range(0, wheels.size() - 1)]
	cfg.fork_id = forks[rng.randi_range(0, forks.size() - 1)]
	cfg.handlebar_id = ["riser", "flat", "dh_bar"][rng.randi_range(0, 2)]
	cfg.seat_id = ["trail", "comfort", "slim"][rng.randi_range(0, 2)]
	cfg.pedal_id = ["platform", "clipless"][rng.randi_range(0, 1)]
	var hue := rng.randf()
	cfg.frame_paint_color = Color.from_hsv(hue, 0.55, 0.85, 1.0)
	cfg.fork_paint_color = cfg.frame_paint_color.darkened(0.12)
	cfg.rim_paint_color = Color(0.3 + rng.randf() * 0.1, 0.32, 0.34, 1.0)
	cfg.handlebar_paint_color = cfg.frame_paint_color
	cfg.seat_paint_color = cfg.frame_paint_color.darkened(0.2)
	cfg.frame_paint_finish = ["gloss", "matte", "metallic"][rng.randi_range(0, 2)]
	cfg.fork_paint_finish = cfg.frame_paint_finish
	cfg.rim_paint_finish = "metallic"
	cfg.handlebar_paint_finish = "gloss"
	cfg.seat_paint_finish = "matte"
	cfg.sync_legacy_paint_color()
	return cfg

func _random_character_config(rng: RandomNumberGenerator) -> Resource:
	var cfg: Resource = CharacterConfigResource.new()
	cfg.hair_style = ["short", "long", "helmet"][rng.randi_range(0, 2)]
	cfg.outfit_id = ["casual", "race", "street"][rng.randi_range(0, 2)]
	cfg.skin_tone = Color(0.75 + rng.randf() * 0.15, 0.55 + rng.randf() * 0.12, 0.4 + rng.randf() * 0.1, 1.0)
	cfg.outfit_color = Color.from_hsv(rng.randf(), 0.35 + rng.randf() * 0.25, 0.35 + rng.randf() * 0.25, 1.0)
	return cfg
