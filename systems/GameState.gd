extends Node

const BikeConfigResource := preload("res://resources/BikeConfig.gd")
const CharacterConfigResource := preload("res://resources/CharacterConfig.gd")
const BikeRigScript := preload("res://scripts/BikeRig.gd")

var bike_config: Resource = BikeConfigResource.new()
var character_config: Resource = CharacterConfigResource.new()
var world_seed: int = 13371337
var active_slot: int = -1
var pending_garage_exit: bool = false
var garage_exit_spawn: Vector3 = Vector3.ZERO
var pending_wizard_exit: bool = false
var wizard_exit_spawn: Vector3 = Vector3.ZERO
var wizard_tower_world_position: Vector3 = Vector3.ZERO
var pending_house_exit: bool = false
var house_exit_spawn: Vector3 = Vector3.ZERO
var house_exit_yaw: float = 0.0
var house_entrance_world: Vector3 = Vector3.ZERO
var current_house_seed: int = 0
var character_edit_context: String = "ride"
var is_new_game_setup: bool = false
var money: float = 0.2
var quest_active: bool = false
var quest_stage: int = 0
var quest_completed: bool = false

const STARTING_MONEY := 0.2

func queue_garage_exit() -> void:
	pending_garage_exit = true
	garage_exit_spawn = BikeRigScript.garage_exit_spawn()

func consume_garage_exit_spawn() -> Vector3:
	if not pending_garage_exit:
		return Vector3.INF
	pending_garage_exit = false
	var spawn := garage_exit_spawn
	garage_exit_spawn = Vector3.ZERO
	return spawn

func queue_wizard_exit(tower_world_pos: Vector3) -> void:
	pending_wizard_exit = true
	wizard_exit_spawn = BikeRigScript.wizard_exit_from_tower(tower_world_pos)

func consume_wizard_exit_spawn() -> Vector3:
	if not pending_wizard_exit:
		return Vector3.INF
	pending_wizard_exit = false
	var spawn := wizard_exit_spawn
	wizard_exit_spawn = Vector3.ZERO
	return spawn

func begin_house_visit(entrance_world: Vector3, exit_yaw: float, house_seed: int) -> void:
	house_entrance_world = entrance_world
	house_exit_yaw = exit_yaw
	current_house_seed = house_seed

func queue_house_exit() -> void:
	pending_house_exit = true
	house_exit_spawn = BikeRigScript.house_exit_spawn(house_entrance_world)

func consume_house_exit_spawn() -> Vector3:
	if not pending_house_exit:
		return Vector3.INF
	pending_house_exit = false
	var spawn := house_exit_spawn
	house_exit_spawn = Vector3.ZERO
	return spawn

func consume_house_exit_yaw() -> float:
	var yaw := house_exit_yaw
	house_exit_yaw = 0.0
	return yaw

func begin_character_edit(context: String) -> void:
	character_edit_context = context

func wizard_tower_chunk() -> Vector2i:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(world_seed) ^ 0x7A1E50F1
	var chunk := Vector2i(rng.randi_range(-8, 8), rng.randi_range(-8, 8))
	if chunk == Vector2i.ZERO:
		chunk = Vector2i(3, 2)
	return chunk

func wizard_tower_local_position() -> Vector3:
	return Vector3(42.0, 0.0, 36.0)

func wizard_tower_world_position_for_chunk(chunk_coord: Vector2i) -> Vector3:
	var local := wizard_tower_local_position()
	return Vector3(
		float(chunk_coord.x) * 120.0 + local.x,
		BikeRigScript.RIDE_SURFACE_Y,
		float(chunk_coord.y) * 120.0 + local.z
	)

func _ready() -> void:
	SaveSystem.sanitize_slots()
	reset_to_defaults()

func reset_to_defaults() -> void:
	bike_config = BikeConfigResource.new()
	character_config = CharacterConfigResource.new()
	world_seed = randi()
	money = STARTING_MONEY
	quest_active = false
	quest_stage = 0
	quest_completed = false

func add_money(amount: float) -> void:
	money += amount
	if money < 0.0:
		money = 0.0

func format_money() -> String:
	return "$%.2f" % money

func start_new_game(slot: int) -> void:
	active_slot = slot
	is_new_game_setup = true
	reset_to_defaults()

func abandon_new_game() -> void:
	if active_slot >= 0:
		SaveSystem.delete_slot(active_slot)
	active_slot = -1
	is_new_game_setup = false
	reset_to_defaults()

func load_slot(slot: int) -> bool:
	var data: Dictionary = SaveSystem.load_slot(slot)
	if not SaveSystem.is_playable_save(data):
		return false
	active_slot = slot
	is_new_game_setup = false
	if data.has("bike"):
		bike_config.from_dict(data["bike"])
	if data.has("character"):
		character_config.from_dict(data["character"])
	if data.has("world_seed"):
		world_seed = int(data["world_seed"])
	money = float(data.get("money", STARTING_MONEY))
	quest_active = bool(data.get("quest_active", false))
	quest_stage = int(data.get("quest_stage", 0))
	quest_completed = bool(data.get("quest_completed", false))
	return true

func first_empty_slot() -> int:
	for slot in range(SaveSystem.SLOT_COUNT):
		if not SaveSystem.has_slot(slot):
			return slot
	return 0

func slot_summary(slot: int) -> Dictionary:
	if not SaveSystem.has_slot(slot):
		return {"empty": true, "title": "Slot %d" % (slot + 1), "subtitle": "Empty"}
	var data: Dictionary = SaveSystem.load_slot(slot)
	var bike_data: Dictionary = data.get("bike", {})
	var frame_id: String = str(bike_data.get("frame_id", "bike"))
	return {
		"empty": false,
		"title": "Slot %d" % (slot + 1),
		"subtitle": frame_id.replace("_", " ").capitalize(),
		"data": data
	}

func preview_data_for_slot(slot: int) -> Dictionary:
	if not SaveSystem.has_slot(slot):
		return default_preview_data()
	var data: Dictionary = SaveSystem.load_slot(slot)
	return {
		"bike": data.get("bike", {}),
		"character": data.get("character", {})
	}

func default_preview_data() -> Dictionary:
	var bike: Resource = BikeConfigResource.new()
	var character: Resource = CharacterConfigResource.new()
	return {
		"bike": bike.to_dict(),
		"character": character.to_dict()
	}

func persist() -> void:
	if active_slot < 0:
		return
	SaveSystem.save_slot(active_slot, {
		"ready": not is_new_game_setup,
		"bike": bike_config.to_dict(),
		"character": character_config.to_dict(),
		"world_seed": world_seed,
		"money": money,
		"quest_active": quest_active,
		"quest_stage": quest_stage,
		"quest_completed": quest_completed
	})
