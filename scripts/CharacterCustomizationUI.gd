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

func _ready() -> void:
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
	set_process(true)

func _process(delta: float) -> void:
	_preview_spin += delta * 0.35
	if rider_pivot:
		rider_pivot.rotation.y = _preview_spin

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
			subtitle_label.text = "Customize before your first ride"
			confirm_button.text = "START RIDING"
			cancel_button.text = "Back to menu"
		"wizard_tower":
			title_label.text = "WIZARD'S MIRROR"
			subtitle_label.text = "The tower reshapes your appearance"
			confirm_button.text = "ACCEPT NEW FORM"
			cancel_button.text = "Leave unchanged"
		_:
			title_label.text = "CHARACTER"
			subtitle_label.text = "Edit outfit, hair, and colors"
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
