extends Control

@onready var color_picker: ColorPickerButton = $MarginContainer/VBoxContainer/PaintColor
@onready var frame_option: OptionButton = $MarginContainer/VBoxContainer/FrameOption
@onready var wheel_option: OptionButton = $MarginContainer/VBoxContainer/WheelOption
@onready var handlebar_option: OptionButton = $MarginContainer/VBoxContainer/HandlebarOption

func _ready() -> void:
	_populate_options()
	_apply_state_to_ui()

func _populate_options() -> void:
	_add_option(frame_option, "trail", "Trail Frame")
	_add_option(frame_option, "enduro", "Enduro Frame")
	_add_option(frame_option, "downhill", "Downhill Frame")
	frame_option.select(0)
	_add_option(wheel_option, "mtb_29", "29in Wheelset")
	_add_option(wheel_option, "mtb_27_5", "27.5in Wheelset")
	_add_option(wheel_option, "mtb_plus", "Plus Tire Wheelset")
	wheel_option.select(0)
	_add_option(handlebar_option, "riser", "Riser Bar")
	_add_option(handlebar_option, "flat", "Flat Bar")
	_add_option(handlebar_option, "dh_bar", "DH Bar")
	handlebar_option.select(0)

func _apply_state_to_ui() -> void:
	color_picker.color = GameState.bike_config.paint_color
	_select_by_text(frame_option, GameState.bike_config.frame_id)
	_select_by_text(wheel_option, GameState.bike_config.wheel_id)
	_select_by_text(handlebar_option, GameState.bike_config.handlebar_id)

func _on_save_pressed() -> void:
	GameState.bike_config.paint_color = color_picker.color
	GameState.bike_config.frame_id = _selected_id(frame_option)
	GameState.bike_config.wheel_id = _selected_id(wheel_option)
	GameState.bike_config.handlebar_id = _selected_id(handlebar_option)
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
		if str(option.get_item_metadata(idx)) == value:
			option.select(idx)
			return

func _selected_id(option: OptionButton) -> String:
	var index: int = option.selected
	if index < 0:
		return ""
	return str(option.get_item_metadata(index))

func _add_option(option: OptionButton, id: String, label: String) -> void:
	option.add_item(label)
	option.set_item_metadata(option.item_count - 1, id)
