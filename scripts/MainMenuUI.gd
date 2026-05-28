extends Control

const BikeConfigResource := preload("res://resources/BikeConfig.gd")
const CharacterConfigResource := preload("res://resources/CharacterConfig.gd")
const BikeRigScript := preload("res://scripts/BikeRig.gd")

const PREVIEW_BIKE_X := 3.2

@onready var new_game_button: Button = $MenuPanel/Margin/VBox/NewGameButton
@onready var slot_buttons: Array[Button] = [
	$MenuPanel/Margin/VBox/SlotButtons/Slot0Button,
	$MenuPanel/Margin/VBox/SlotButtons/Slot1Button,
	$MenuPanel/Margin/VBox/SlotButtons/Slot2Button
]
@onready var settings_button: Button = $MenuPanel/Margin/VBox/SettingsButton
@onready var quit_button: Button = $MenuPanel/Margin/VBox/QuitButton
@onready var preview_label: Label = $PreviewPanel/Margin/PreviewLabel
@onready var bike_visual: Node3D = $PreviewPanel/SubViewportContainer/SubViewport/World/BikePivot/BikeVisual
@onready var rider_visual: Node3D = $PreviewPanel/SubViewportContainer/SubViewport/World/BikePivot/RiderVisual
@onready var bike_pivot: Node3D = $PreviewPanel/SubViewportContainer/SubViewport/World/BikePivot
@onready var preview_camera: Camera3D = $PreviewPanel/SubViewportContainer/SubViewport/World/Camera3D
@onready var viewport_container: SubViewportContainer = $PreviewPanel/SubViewportContainer

func _ready() -> void:
	_style_menu()
	_setup_preview_camera()
	for slot in range(slot_buttons.size()):
		var button: Button = slot_buttons[slot]
		button.mouse_entered.connect(_on_slot_hover.bind(slot))
		button.pressed.connect(_on_slot_pressed.bind(slot))
	_refresh_slot_buttons()
	_apply_preview(GameState.default_preview_data())
	new_game_button.mouse_entered.connect(_on_new_game_hover)
	resized.connect(_on_resized)

func _style_menu() -> void:
	var menu_style := StyleBoxFlat.new()
	menu_style.bg_color = Color(0.07, 0.08, 0.1, 1.0)
	$MenuPanel.add_theme_stylebox_override("panel", menu_style)
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Color(0.05, 0.06, 0.07, 1.0)
	$PreviewPanel.add_theme_stylebox_override("panel", preview_style)

func _setup_preview_camera() -> void:
	bike_pivot.position = Vector3(PREVIEW_BIKE_X, BikeRigScript.GARAGE_FLOOR_Y, 0.0)
	var look_target := bike_pivot.position + Vector3(0.0, 0.55, 0.0)
	preview_camera.position = Vector3(PREVIEW_BIKE_X - 8.4, 0.95, 0.2)
	preview_camera.look_at(look_target, Vector3.UP)
	preview_camera.fov = 36.0

func _refresh_slot_buttons() -> void:
	for slot in range(slot_buttons.size()):
		var button: Button = slot_buttons[slot]
		var summary: Dictionary = GameState.slot_summary(slot)
		if summary["empty"]:
			button.text = "%s — Empty" % summary["title"]
			button.disabled = true
		else:
			button.text = "%s — %s" % [summary["title"], summary["subtitle"]]
			button.disabled = false

func _on_resized() -> void:
	if viewport_container == null:
		return
	var size := viewport_container.size
	if size.x > 0 and size.y > 0:
		viewport_container.get_child(0).size = Vector2i(int(size.x), int(size.y))

func _on_new_game_hover() -> void:
	_apply_preview(GameState.default_preview_data())
	preview_label.text = "New game — default bike & rider"

func _on_slot_hover(slot: int) -> void:
	if not SaveSystem.has_slot(slot):
		_apply_preview(GameState.default_preview_data())
		preview_label.text = "Empty slot"
		return
	_apply_preview(GameState.preview_data_for_slot(slot))
	var summary: Dictionary = GameState.slot_summary(slot)
	preview_label.text = "%s — %s" % [summary["title"], summary["subtitle"]]

func _apply_preview(preview_data: Dictionary) -> void:
	var bike_cfg: Resource = BikeConfigResource.new()
	var char_cfg: Resource = CharacterConfigResource.new()
	if preview_data.has("bike"):
		bike_cfg.from_dict(preview_data["bike"])
	if preview_data.has("character"):
		char_cfg.from_dict(preview_data["character"])
	bike_visual.call("apply_config", bike_cfg)
	rider_visual.call("apply_config", char_cfg)
	bike_visual.call("mount_rider", rider_visual)
	bike_pivot.position = Vector3(PREVIEW_BIKE_X, BikeRigScript.GARAGE_FLOOR_Y, 0.0)

func _on_new_game_pressed() -> void:
	var slot := GameState.first_empty_slot()
	GameState.start_new_game(slot)
	_go_to_ride()

func _on_slot_pressed(slot: int) -> void:
	if not GameState.load_slot(slot):
		return
	_go_to_ride()

func _on_settings_pressed() -> void:
	var main: Node = get_tree().current_scene
	if main and main.has_method("show_settings"):
		main.show_settings()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _go_to_ride() -> void:
	var main: Node = get_tree().current_scene
	if main and main.has_method("show_ride_scene"):
		main.show_ride_scene()
