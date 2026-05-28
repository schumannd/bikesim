extends Node

const SETTINGS_PATH := "user://settings.json"

var target_fps: int = 60
var quality_preset: String = "high"

func _ready() -> void:
	load_settings()
	_apply()

func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		target_fps = int(parsed.get("target_fps", target_fps))
		quality_preset = str(parsed.get("quality_preset", quality_preset))

func save_settings() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save settings at %s" % SETTINGS_PATH)
		return
	file.store_string(JSON.stringify({
		"target_fps": target_fps,
		"quality_preset": quality_preset
	}))

func set_target_fps(value: int) -> void:
	target_fps = value
	_apply()
	save_settings()

func set_quality(new_quality: String) -> void:
	quality_preset = new_quality
	_apply()
	save_settings()

func _apply() -> void:
	Engine.max_fps = target_fps if target_fps > 0 else 0
