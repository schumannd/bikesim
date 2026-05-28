extends Node

var target_fps: int = 60
var quality_preset: String = "high"

func _ready() -> void:
	Engine.max_fps = target_fps

func set_quality(new_quality: String) -> void:
	quality_preset = new_quality
