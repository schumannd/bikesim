extends Node

const BikeConfigResource := preload("res://resources/BikeConfig.gd")
const CharacterConfigResource := preload("res://resources/CharacterConfig.gd")

var bike_config: Resource = BikeConfigResource.new()
var character_config: Resource = CharacterConfigResource.new()

func _ready() -> void:
	var data: Dictionary = SaveSystem.load_game()
	if data.has("bike"):
		bike_config.from_dict(data["bike"])
	if data.has("character"):
		character_config.from_dict(data["character"])

func persist() -> void:
	SaveSystem.save_game({
		"bike": bike_config.to_dict(),
		"character": character_config.to_dict()
	})
