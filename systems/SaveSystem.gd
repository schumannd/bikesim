extends Node

const SLOT_COUNT := 3
const LEGACY_SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 2

func slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot

func save_slot(slot: int, data: Dictionary) -> void:
	var path := slot_path(slot)
	var payload := data.duplicate(true)
	payload["version"] = SAVE_VERSION
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save slot %d at %s" % [slot, path])
		return
	file.store_string(JSON.stringify(payload))

func load_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func is_playable_save(data: Dictionary) -> bool:
	if data.is_empty() or not data.has("bike"):
		return false
	return bool(data.get("ready", false))

func has_slot(slot: int) -> bool:
	return is_playable_save(load_slot(slot))

func delete_slot(slot: int) -> void:
	var path := slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func wipe_all_saves() -> void:
	for slot in range(SLOT_COUNT):
		delete_slot(slot)
	_delete_legacy_save()

func sanitize_slots() -> void:
	for slot in range(SLOT_COUNT):
		if not is_playable_save(load_slot(slot)):
			delete_slot(slot)
	_delete_legacy_save()

func _delete_legacy_save() -> void:
	if FileAccess.file_exists(LEGACY_SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH))

# Kept for compatibility with any external tooling.
func save_game(data: Dictionary) -> void:
	save_slot(0, data)

func load_game() -> Dictionary:
	return load_slot(0)
