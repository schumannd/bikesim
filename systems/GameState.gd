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

func _ready() -> void:
	SaveSystem.migrate_legacy_save()
	reset_to_defaults()

func reset_to_defaults() -> void:
	bike_config = BikeConfigResource.new()
	character_config = CharacterConfigResource.new()
	world_seed = randi()

func start_new_game(slot: int) -> void:
	active_slot = slot
	reset_to_defaults()
	persist()

func load_slot(slot: int) -> bool:
	var data: Dictionary = SaveSystem.load_slot(slot)
	if data.is_empty() or not data.has("bike"):
		return false
	active_slot = slot
	if data.has("bike"):
		bike_config.from_dict(data["bike"])
	if data.has("character"):
		character_config.from_dict(data["character"])
	if data.has("world_seed"):
		world_seed = int(data["world_seed"])
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
		"bike": bike_config.to_dict(),
		"character": character_config.to_dict(),
		"world_seed": world_seed
	})
