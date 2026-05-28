extends Node

const BikeConfigResource := preload("res://resources/BikeConfig.gd")
const CharacterConfigResource := preload("res://resources/CharacterConfig.gd")

const BikeRigScript := preload("res://scripts/BikeRig.gd")

var bike_config: Resource = BikeConfigResource.new()
var character_config: Resource = CharacterConfigResource.new()
var world_seed: int = 13371337
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
	var data: Dictionary = SaveSystem.load_game()
	if data.has("bike"):
		bike_config.from_dict(data["bike"])
	if data.has("character"):
		character_config.from_dict(data["character"])
	if data.has("world_seed"):
		world_seed = int(data["world_seed"])
	else:
		world_seed = randi()
		persist()

func persist() -> void:
	SaveSystem.save_game({
		"bike": bike_config.to_dict(),
		"character": character_config.to_dict(),
		"world_seed": world_seed
	})
