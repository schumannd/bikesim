extends Control

@onready var fps_option: OptionButton = $Panel/Margin/VBox/FpsOption
@onready var quality_option: OptionButton = $Panel/Margin/VBox/QualityOption

func _ready() -> void:
	SoundEffects.wire_menu_buttons(self)
	SoundEffects.wire_option_button(fps_option)
	SoundEffects.wire_option_button(quality_option)
	_populate_options()
	_apply_state_to_ui()

func _populate_options() -> void:
	fps_option.clear()
	fps_option.add_item("60 FPS", 60)
	fps_option.add_item("120 FPS", 120)
	fps_option.add_item("Unlimited", 0)
	quality_option.clear()
	quality_option.add_item("High", 0)
	quality_option.add_item("Low", 1)

func _apply_state_to_ui() -> void:
	_select_fps(Settings.target_fps)
	_select_quality(Settings.quality_preset)

func _select_fps(value: int) -> void:
	for i in range(fps_option.item_count):
		if int(fps_option.get_item_id(i)) == value:
			fps_option.select(i)
			return
	fps_option.select(0)

func _select_quality(preset: String) -> void:
	quality_option.select(0 if preset == "high" else 1)

func _on_fps_changed(index: int) -> void:
	Settings.set_target_fps(int(fps_option.get_item_id(index)))

func _on_quality_changed(index: int) -> void:
	Settings.set_quality("high" if index == 0 else "low")

func _on_back_pressed() -> void:
	var main: Node = get_tree().current_scene
	if main and main.has_method("show_main_menu"):
		main.show_main_menu()
