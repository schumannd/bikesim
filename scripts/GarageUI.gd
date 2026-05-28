extends Control

@onready var color_picker: ColorPickerButton = $MarginContainer/VBoxContainer/PaintColor
@onready var frame_option: OptionButton = $MarginContainer/VBoxContainer/FrameOption
@onready var wheel_option: OptionButton = $MarginContainer/VBoxContainer/WheelOption
@onready var handlebar_option: OptionButton = $MarginContainer/VBoxContainer/HandlebarOption

func _ready() -> void:
	_populate_options()
	_apply_state_to_ui()

func _populate_options() -> void:
	frame_option.add_item("Street")
	frame_option.add_item("BMX")
	frame_option.add_item("Road")
	frame_option.select(0)
	wheel_option.add_item("Sport")
	wheel_option.add_item("Offroad")
	wheel_option.select(0)
	handlebar_option.add_item("Flat")
	handlebar_option.add_item("Drop")
	handlebar_option.select(0)

func _apply_state_to_ui() -> void:
	color_picker.color = GameState.bike_config.paint_color
	_select_by_text(frame_option, GameState.bike_config.frame_id)
	_select_by_text(wheel_option, GameState.bike_config.wheel_id)
	_select_by_text(handlebar_option, GameState.bike_config.handlebar_id)

func _on_save_pressed() -> void:
	GameState.bike_config.paint_color = color_picker.color
	GameState.bike_config.frame_id = frame_option.get_item_text(frame_option.selected).to_lower()
	GameState.bike_config.wheel_id = wheel_option.get_item_text(wheel_option.selected).to_lower()
	GameState.bike_config.handlebar_id = handlebar_option.get_item_text(handlebar_option.selected).to_lower()
	GameState.persist()
	var main: Node = get_tree().current_scene
	if main and main.has_method("show_ride_scene"):
		main.show_ride_scene()

func _on_cancel_pressed() -> void:
	var main: Node = get_tree().current_scene
	if main and main.has_method("show_ride_scene"):
		main.show_ride_scene()

func _select_by_text(option: OptionButton, value: String) -> void:
	for idx in range(option.item_count):
		if option.get_item_text(idx).to_lower() == value:
			option.select(idx)
			return
