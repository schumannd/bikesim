extends Node3D

const CheckpointMarkerScript := preload("res://scripts/CheckpointMarker.gd")
const QuestGiverMarkerScript := preload("res://scripts/QuestGiverMarker.gd")
const BikeRigScript := preload("res://scripts/BikeRig.gd")

const QUEST_GIVER_POSITION := Vector3(12.0, 0.0, 10.0)
const QUEST_REWARD := 2.0

signal quest_state_changed

@export var bike_path: NodePath
@export var world_path: NodePath

var _bike: Node3D
var _world: Node3D
var _quest_giver: Area3D
var _active_checkpoint: Area3D
var _route: Array[Vector3] = []

func _ready() -> void:
	_bike = get_node_or_null(bike_path) as Node3D
	_world = get_node_or_null(world_path) as Node3D
	_spawn_quest_giver()
	_apply_saved_quest_state()

func _quest_parent() -> Node3D:
	if _world != null:
		return _world
	return self

func _process(_delta: float) -> void:
	if _active_checkpoint != null and is_instance_valid(_active_checkpoint):
		var next_target := _next_checkpoint_position()
		if _active_checkpoint.has_method("set_arrow_target"):
			_active_checkpoint.call("set_arrow_target", next_target)

func get_active_quest_position() -> Vector3:
	if _active_checkpoint != null and is_instance_valid(_active_checkpoint):
		return _active_checkpoint.global_position
	if _quest_giver != null and is_instance_valid(_quest_giver) and not GameState.quest_completed:
		return _quest_giver.global_position
	return Vector3.INF

func can_interact_with_giver() -> bool:
	if GameState.quest_completed or GameState.quest_active:
		return false
	if _quest_giver == null or not is_instance_valid(_quest_giver):
		return false
	return bool(_quest_giver.get("player_in_range"))

func try_interact() -> bool:
	if not can_interact_with_giver():
		return false
	_start_quest()
	return true

func _spawn_quest_giver() -> void:
	_quest_giver = Area3D.new()
	_quest_giver.name = "QuestGiver"
	_quest_giver.position = QUEST_GIVER_POSITION
	_quest_giver.set_script(QuestGiverMarkerScript)
	_quest_parent().add_child(_quest_giver)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 3.2
	shape.shape = sphere
	shape.position = Vector3(0.0, 2.0, 0.0)
	_quest_giver.add_child(shape)

	if _quest_giver.has_signal("interact_requested"):
		_quest_giver.interact_requested.connect(_start_quest)

func _apply_saved_quest_state() -> void:
	if GameState.quest_completed:
		if _quest_giver != null:
			_quest_giver.call("hide_giver")
		return
	if GameState.quest_active:
		_route = _build_route(QUEST_GIVER_POSITION)
		_spawn_checkpoint(GameState.quest_stage)
		if _quest_giver != null:
			_quest_giver.call("hide_giver")

func _start_quest() -> void:
	if GameState.quest_active or GameState.quest_completed:
		return
	GameState.quest_active = true
	GameState.quest_stage = 0
	GameState.persist()
	_route = _build_route(QUEST_GIVER_POSITION)
	if _quest_giver != null:
		_quest_giver.call("hide_giver")
	_spawn_checkpoint(0)
	quest_state_changed.emit()

func _build_route(origin: Vector3) -> Array[Vector3]:
	return [
		origin + Vector3(14.0, 0.0, 6.0),
		origin + Vector3(34.0, 0.0, -10.0),
		origin + Vector3(10.0, 0.0, -28.0),
		origin + Vector3(-6.0, 0.0, -14.0)
	]

func _spawn_checkpoint(index: int) -> void:
	if _active_checkpoint != null and is_instance_valid(_active_checkpoint):
		_active_checkpoint.queue_free()
		_active_checkpoint = null
	if index < 0 or index >= _route.size():
		return

	var is_finish := index == _route.size() - 1
	var checkpoint := Area3D.new()
	checkpoint.name = "QuestCheckpoint_%d" % index
	checkpoint.position = BikeRigScript.ride_spawn_position(_route[index])
	checkpoint.set_script(CheckpointMarkerScript)
	var style := "checkered" if is_finish else "blue"
	checkpoint.call("configure", style, not is_finish)
	_quest_parent().add_child(checkpoint)

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 2.8
	shape.shape = sphere
	shape.position = Vector3(0.0, 3.0, 0.0)
	checkpoint.add_child(shape)

	if checkpoint.has_signal("reached"):
		checkpoint.reached.connect(_on_checkpoint_reached.bind(index))

	_active_checkpoint = checkpoint
	var next_pos := _next_checkpoint_position()
	checkpoint.call("set_arrow_target", next_pos)
	quest_state_changed.emit()

func _next_checkpoint_position() -> Vector3:
	var next_index := GameState.quest_stage + 1
	if next_index >= _route.size():
		return Vector3.INF
	return _route[next_index]

func _on_checkpoint_reached(index: int) -> void:
	if not GameState.quest_active or index != GameState.quest_stage:
		return
	if _bike != null:
		_bike.call("set_reset_position", BikeRigScript.ride_spawn_position(_bike.global_position))

	if _active_checkpoint != null and is_instance_valid(_active_checkpoint):
		_active_checkpoint.call("mark_reached")
		_active_checkpoint = null

	GameState.quest_stage += 1
	if GameState.quest_stage >= _route.size():
		_complete_quest()
	else:
		GameState.persist()
		_spawn_checkpoint(GameState.quest_stage)

func _complete_quest() -> void:
	GameState.quest_active = false
	GameState.quest_completed = true
	GameState.add_money(QUEST_REWARD)
	GameState.persist()
	quest_state_changed.emit()

func get_quest_status_text() -> String:
	if GameState.quest_completed:
		return "Quest complete — ride free!"
	if GameState.quest_active:
		return "Quest: checkpoint %d / %d" % [GameState.quest_stage + 1, _route.size()]
	if can_interact_with_giver():
		return "Quest giver nearby — press E to start"
	return "Find the golden quest marker — press E"
