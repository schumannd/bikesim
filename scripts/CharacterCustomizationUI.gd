extends Control

@onready var outfit_option: OptionButton = $MarginContainer/VBoxContainer/OutfitOption
@onready var hair_option: OptionButton = $MarginContainer/VBoxContainer/HairOption
@onready var skin_picker: ColorPickerButton = $MarginContainer/VBoxContainer/SkinTone
@onready var outfit_picker: ColorPickerButton = $MarginContainer/VBoxContainer/OutfitColor

func _ready() -> void:
	_populate_options()
	_apply_state_to_ui()

func _populate_options() -> void:
	outfit_option.add_item("Casual")
	outfit_option.add_item("Race")
	outfit_option.add_item("Street")
	hair_option.add_item("Short")
	hair_option.add_item("Long")
	hair_option.add_item("Helmet")

func _apply_state_to_ui() -> void:
	skin_picker.color = GameState.character_config.skin_tone
	outfit_picker.color = GameState.character_config.outfit_color
	_select_by_text(outfit_option, GameState.character_config.outfit_id)
	_select_by_text(hair_option, GameState.character_config.hair_style)

func _on_save_pressed() -> void:
	GameState.character_config.outfit_id = outfit_option.get_item_text(outfit_option.selected).to_lower()
	GameState.character_config.hair_style = hair_option.get_item_text(hair_option.selected).to_lower()
	GameState.character_config.skin_tone = skin_picker.color
	GameState.character_config.outfit_color = outfit_picker.color
	GameState.persist()
	get_tree().root.get_node("Main").show_ride_scene()

func _on_cancel_pressed() -> void:
	get_tree().root.get_node("Main").show_ride_scene()

func _select_by_text(option: OptionButton, value: String) -> void:
	for idx in range(option.item_count):
		if option.get_item_text(idx).to_lower() == value:
			option.select(idx)
			return
