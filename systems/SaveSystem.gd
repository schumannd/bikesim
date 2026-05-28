extends Node

const SLOT_COUNT := 3
const LEGACY_SAVE_PATH := "user://savegame.json"

func slot_path(slot: int) -> String:
	return "user://save_slot_%d.json" % slot

func save_slot(slot: int, data: Dictionary) -> void:
	var path := slot_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Unable to save slot %d at %s" % [slot, path])
		return
	file.store_string(JSON.stringify(data))

func load_slot(slot: int) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return parsed if parsed is Dictionary else {}

func has_slot(slot: int) -> bool:
	var data := load_slot(slot)
	return not data.is_empty() and data.has("bike")

func delete_slot(slot: int) -> void:
	var path := slot_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func migrate_legacy_save() -> void:
	if not FileAccess.file_exists(LEGACY_SAVE_PATH):
		return
	if has_slot(0):
		return
	var file := FileAccess.open(LEGACY_SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary and not (parsed as Dictionary).is_empty():
		save_slot(0, parsed)

# Kept for compatibility with any external tooling.
func save_game(data: Dictionary) -> void:
	save_slot(0, data)

func load_game() -> Dictionary:
	return load_slot(0)
