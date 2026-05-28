extends Control

const CharacterConfigResource := preload("res://resources/CharacterConfig.gd")
const RiderVisualBuilderScript := preload("res://scripts/RiderVisualBuilder.gd")
const BikeRigScript := preload("res://scripts/BikeRig.gd")

const PREVIEW_CENTER_X := 3.2

@onready var title_label: Label = $MenuPanel/Margin/VBox/Title
@onready var subtitle_label: Label = $MenuPanel/Margin/VBox/Subtitle
@onready var outfit_option: OptionButton = $MenuPanel/Margin/VBox/Options/OutfitOption
@onready var hair_option: OptionButton = $MenuPanel/Margin/VBox/Options/HairOption
@onready var skin_picker: ColorPickerButton = $MenuPanel/Margin/VBox/Options/SkinRow/SkinTone
@onready var outfit_picker: ColorPickerButton = $MenuPanel/Margin/VBox/Options/OutfitRow/OutfitColor
@onready var confirm_button: Button = $MenuPanel/Margin/VBox/ConfirmButton
@onready var cancel_button: Button = $MenuPanel/Margin/VBox/ButtonRow/CancelButton
@onready var rider_visual: Node3D = $PreviewPanel/SubViewportContainer/SubViewport/World/RiderPivot/RiderVisual
@onready var rider_pivot: Node3D = $PreviewPanel/SubViewportContainer/SubViewport/World/RiderPivot
@onready var preview_camera: Camera3D = $PreviewPanel/SubViewportContainer/SubViewport/World/Camera3D
@onready var viewport_container: SubViewportContainer = $PreviewPanel/SubViewportContainer

var _preview_spin: float = 0.0
var _nav_fields: Array[String] = ["outfit", "hair", "skin", "outfit_color", "confirm", "cancel"]
var _nav_index: int = 0

func _ready() -> void:
	SoundEffects.wire_menu_buttons(self)
	SoundEffects.wire_option_button(outfit_option)
	SoundEffects.wire_option_button(hair_option)
	_style_panels()
	_setup_preview_camera()
	_populate_options()
	_apply_state_to_ui()
	_apply_context_ui()
	_refresh_preview()
	outfit_option.item_selected.connect(func(_i: int) -> void: _refresh_preview())
	hair_option.item_selected.connect(func(_i: int) -> void: _refresh_preview())
	skin_picker.color_changed.connect(func(_c: Color) -> void: _refresh_preview())
	outfit_picker.color_changed.connect(func(_c: Color) -> void: _refresh_preview())
	resized.connect(_on_resized)
	_disable_control_focus()
	focus_mode = Control.FOCUS_ALL
	grab_focus()
	set_process(true)
	set_process_input(true)
	_apply_nav_selection()

func _disable_control_focus() -> void:
	for control: Control in [outfit_option, hair_option, skin_picker, outfit_picker, confirm_button, cancel_button]:
		control.focus_mode = Control.FOCUS_NONE

func _process(delta: float) -> void:
	_preview_spin += delta * 0.35
	if rider_pivot:
		rider_pivot.rotation.y = _preview_spin

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var key_event := event as InputEventKey
	var handled := true
	match key_event.keycode:
		KEY_W, KEY_UP:
			_nav_index = posmod(_nav_index - 1, _nav_fields.size())
			SoundEffects.play_menu_move()
			_apply_nav_selection()
		KEY_S, KEY_DOWN:
			_nav_index = posmod(_nav_index + 1, _nav_fields.size())
			SoundEffects.play_menu_move()
			_apply_nav_selection()
		KEY_A, KEY_LEFT:
			_step_field(-1)
		KEY_D, KEY_RIGHT:
			_step_field(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			_activate_selection()
		KEY_ESCAPE:
			_on_cancel_pressed()
		_:
			handled = false
	if handled:
		get_viewport().set_input_as_handled()

func _activate_selection() -> void:
	SoundEffects.play_menu_confirm()
	if _nav_fields[_nav_index] == "cancel":
		_on_cancel_pressed()
	else:
		_on_confirm_pressed()

func _step_field(direction: int) -> void:
	var field: String = _nav_fields[_nav_index]
	match field:
		"outfit":
			_cycle_option(outfit_option, direction)
		"hair":
			_cycle_option(hair_option, direction)
		"skin":
			skin_picker.color = _nudge_color(skin_picker.color, direction)
		"outfit_color":
			outfit_picker.color = _nudge_color(outfit_picker.color, direction)
		_:
			return
	SoundEffects.play_menu_move()
	_refresh_preview()

func _cycle_option(option: OptionButton, direction: int) -> void:
	if option.item_count == 0:
		return
	option.select(posmod(option.selected + direction, option.item_count))

func _nudge_color(color: Color, direction: int) -> Color:
	var step := 0.06 * float(direction)
	return Color(
		clampf(color.r + step, 0.0, 1.0),
		clampf(color.g + step, 0.0, 1.0),
		clampf(color.b + step, 0.0, 1.0),
		color.a
	)

func _apply_nav_selection() -> void:
	_reset_field_styles()
	var field: String = _nav_fields[_nav_index]
	match field:
		"outfit":
			_style_selected(outfit_option)
		"hair":
			_style_selected(hair_option)
		"skin":
			_style_selected(skin_picker)
		"outfit_color":
			_style_selected(outfit_picker)
		"confirm":
			_style_selected(confirm_button)
		"cancel":
			_style_selected(cancel_button)

func _reset_field_styles() -> void:
	_style_normal(outfit_option)
	_style_normal(hair_option)
	_style_normal(skin_picker)
	_style_normal(outfit_picker)
	_style_normal(confirm_button)
	_style_normal(cancel_button)

func _style_normal(control: Control) -> void:
	control.remove_theme_color_override("font_color")
	control.remove_theme_color_override("font_outline_color")
	if control is Button:
		control.add_theme_font_size_override("font_size", 18 if control != confirm_button else 22)

func _style_selected(control: Control) -> void:
	control.add_theme_color_override("font_color", Color(1.0, 0.72, 0.28, 1.0))
	if control is Button:
		control.add_theme_font_size_override("font_size", 22 if control == confirm_button else 20)

func _style_panels() -> void:
	var menu_style := StyleBoxFlat.new()
	menu_style.bg_color = Color(0.07, 0.08, 0.1, 1.0)
	$MenuPanel.add_theme_stylebox_override("panel", menu_style)
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(0.05, 0.06, 0.07, 1.0)
	$PreviewPanel.add_theme_stylebox_override("panel", preview_style)
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = Color(0.55, 0.22, 0.92, 1.0)
	confirm_style.corner_radius_top_left = 6
	confirm_style.corner_radius_top_right = 6
	confirm_style.corner_radius_bottom_left = 6
	confirm_style.corner_radius_bottom_right = 6
	confirm_button.add_theme_stylebox_override("normal", confirm_style)
	confirm_button.add_theme_color_override("font_color", Color(1.0, 0.98, 1.0, 1.0))
	confirm_button.add_theme_font_size_override("font_size", 22)

func _setup_preview_camera() -> void:
	rider_pivot.position = Vector3(PREVIEW_CENTER_X, BikeRigScript.GARAGE_FLOOR_Y, 0.0)
	var look_target := rider_pivot.position + Vector3(0.0, 0.95, 0.0)
	preview_camera.position = Vector3(PREVIEW_CENTER_X - 3.6, 1.05, 2.4)
	preview_camera.look_at(look_target, Vector3.UP)
	preview_camera.fov = 32.0

func _apply_context_ui() -> void:
	match GameState.character_edit_context:
		"new_game":
			title_label.text = "CREATE YOUR RIDER"
			subtitle_label.text = "W/S navigate — A/D change — Enter start"
			confirm_button.text = "START RIDING"
			cancel_button.text = "Back to menu"
		"wizard_tower":
			title_label.text = "WIZARD'S MIRROR"
			subtitle_label.text = "W/S navigate — A/D change — Enter start"
			confirm_button.text = "ACCEPT NEW FORM"
			cancel_button.text = "Leave unchanged"
		_:
			title_label.text = "CHARACTER"
			subtitle_label.text = "W/S navigate — A/D change — Enter start"
			confirm_button.text = "SAVE & RIDE"
			cancel_button.text = "Cancel"

func _populate_options() -> void:
	outfit_option.clear()
	outfit_option.add_item("Casual")
	outfit_option.add_item("Race")
	outfit_option.add_item("Street")
	hair_option.clear()
	hair_option.add_item("Short")
	hair_option.add_item("Long")
	hair_option.add_item("Helmet")

func _apply_state_to_ui() -> void:
	skin_picker.color = GameState.character_config.skin_tone
	outfit_picker.color = GameState.character_config.outfit_color
	_select_by_text(outfit_option, GameState.character_config.outfit_id)
	_select_by_text(hair_option, GameState.character_config.hair_style)

func _preview_config() -> Resource:
	var cfg: Resource = CharacterConfigResource.new()
	cfg.outfit_id = outfit_option.get_item_text(outfit_option.selected).to_lower()
	cfg.hair_style = hair_option.get_item_text(hair_option.selected).to_lower()
	cfg.skin_tone = skin_picker.color
	cfg.outfit_color = outfit_picker.color
	return cfg

func _refresh_preview() -> void:
	rider_visual.call("apply_config", _preview_config())

func _commit_to_game_state() -> void:
	var cfg: Resource = _preview_config()
	GameState.character_config.outfit_id = cfg.outfit_id
	GameState.character_config.hair_style = cfg.hair_style
	GameState.character_config.skin_tone = cfg.skin_tone
	GameState.character_config.outfit_color = cfg.outfit_color
	GameState.is_new_game_setup = false
	GameState.persist()

func _on_confirm_pressed() -> void:
	_commit_to_game_state()
	_exit_screen(true)

func _on_cancel_pressed() -> void:
	_exit_screen(false)

func _exit_screen(confirmed: bool) -> void:
	var main: Node = get_tree().current_scene
	if main == null:
		return
	match GameState.character_edit_context:
		"new_game":
			if confirmed:
				if main.has_method("show_ride_scene"):
					main.show_ride_scene()
			else:
				GameState.abandon_new_game()
				if main.has_method("show_main_menu"):
					main.show_main_menu()
		"wizard_tower":
			if confirmed:
				GameState.queue_wizard_exit(GameState.wizard_tower_world_position)
			if main.has_method("show_ride_scene"):
				main.show_ride_scene()
		_:
			if main.has_method("show_ride_scene"):
				main.show_ride_scene()

func _on_resized() -> void:
	if viewport_container == null:
		return
	var size := viewport_container.size
	if size.x > 0 and size.y > 0:
		viewport_container.get_child(0).size = Vector2i(int(size.x), int(size.y))

func _select_by_text(option: OptionButton, value: String) -> void:
	for idx in range(option.item_count):
		if option.get_item_text(idx).to_lower() == value:
			option.select(idx)
			return

# Kept for smoke tests and legacy signal hooks.
func _on_save_pressed() -> void:
	_on_confirm_pressed()
