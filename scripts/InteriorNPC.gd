extends Node3D

const RiderVisualBuilderScript := preload("res://scripts/RiderVisualBuilder.gd")
const CharacterConfigResource := preload("res://resources/CharacterConfig.gd")

var npc_name: String = "Neighbor"
var dialogue_lines: PackedStringArray = []
var _line_index: int = 0

func setup(rng: RandomNumberGenerator, display_name: String, lines: PackedStringArray) -> void:
	npc_name = display_name
	dialogue_lines = lines
	_line_index = 0
	_build_visual(rng)

func get_current_line() -> String:
	if dialogue_lines.is_empty():
		return "%s nods quietly." % npc_name
	return dialogue_lines[_line_index % dialogue_lines.size()]

func advance_dialogue() -> String:
	if dialogue_lines.is_empty():
		return get_current_line()
	_line_index = (_line_index + 1) % dialogue_lines.size()
	return get_current_line()

func _build_visual(rng: RandomNumberGenerator) -> void:
	var rider := Node3D.new()
	rider.name = "RiderVisual"
	rider.set_script(RiderVisualBuilderScript)
	add_child(rider)
	var cfg: Resource = CharacterConfigResource.new()
	var outfits := ["casual", "street", "race"]
	cfg.outfit_id = outfits[rng.randi_range(0, outfits.size() - 1)]
	cfg.hair_style = ["short", "long", "helmet"][rng.randi_range(0, 2)]
	cfg.skin_tone = Color.from_hsv(rng.randf(), 0.25, rng.randf_range(0.55, 0.85), 1.0)
	cfg.outfit_color = Color.from_hsv(rng.randf(), 0.45, rng.randf_range(0.45, 0.8), 1.0)
	rider.call("apply_config", cfg)
