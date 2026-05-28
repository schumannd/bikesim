extends Control

const BikeConfigResource := preload("res://resources/BikeConfig.gd")
const CharacterConfigResource := preload("res://resources/CharacterConfig.gd")
const BikeRigScript := preload("res://scripts/BikeRig.gd")

const PREVIEW_BIKE_X := 3.2
const MENU_FONT_NORMAL := 20
const MENU_FONT_SLOT_NORMAL := 17
const MENU_FONT_SELECTED := 24
const MENU_FONT_SLOT_SELECTED := 20

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
@onready var continue_label: Label = $MenuPanel/Margin/VBox/ContinueLabel

var _nav_items: Array[Dictionary] = []
var _nav_index: int = 0

func _ready() -> void:
	SoundEffects.wire_menu_buttons(self)
	_style_menu()
	_setup_preview_camera()
	for slot in range(slot_buttons.size()):
		var button: Button = slot_buttons[slot]
		button.mouse_entered.connect(_on_slot_mouse_hover.bind(slot))
		button.pressed.connect(_on_slot_pressed.bind(slot))
	_refresh_slot_buttons()
	_apply_preview(GameState.default_preview_data())
	new_game_button.mouse_entered.connect(_on_new_game_mouse_hover)
	settings_button.mouse_entered.connect(_on_settings_mouse_hover)
	quit_button.mouse_entered.connect(_on_quit_mouse_hover)
	resized.connect(_on_resized)
	set_process_unhandled_input(true)
	_rebuild_nav_items()
	_apply_nav_selection(false)

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
	_rebuild_nav_items()
	_apply_nav_selection(false)
	continue_label.text = "W/S or ↑/↓ to navigate — Enter to select"

func _on_resized() -> void:
	if viewport_container == null:
		return
	var size := viewport_container.size
	if size.x > 0 and size.y > 0:
		viewport_container.get_child(0).size = Vector2i(int(size.x), int(size.y))

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	_rebuild_nav_items()
	if _nav_items.is_empty():
		return
	match event.keycode:
		KEY_W, KEY_UP:
			_nav_index = posmod(_nav_index - 1, _nav_items.size())
			SoundEffects.play_menu_move()
			_apply_nav_selection(true)
		KEY_S, KEY_DOWN:
			_nav_index = posmod(_nav_index + 1, _nav_items.size())
			SoundEffects.play_menu_move()
			_apply_nav_selection(true)
		KEY_ENTER, KEY_KP_ENTER:
			SoundEffects.play_menu_confirm()
			_activate_nav_item(_nav_items[_nav_index])

func _rebuild_nav_items() -> void:
	_nav_items.clear()
	_nav_items.append({"action": "new_game"})
	for slot in range(slot_buttons.size()):
		if not slot_buttons[slot].disabled:
			_nav_items.append({"action": "slot", "slot": slot})
	_nav_items.append({"action": "settings"})
	_nav_items.append({"action": "quit"})
	if _nav_items.is_empty():
		_nav_index = 0
	else:
		_nav_index = clampi(_nav_index, 0, _nav_items.size() - 1)

func _apply_nav_selection(update_preview: bool) -> void:
	_reset_menu_styles()
	if _nav_items.is_empty():
		return
	var item: Dictionary = _nav_items[_nav_index]
	var button := _button_for_nav_item(item)
	if button != null:
		_style_selected_button(button, item["action"] == "slot")
	if update_preview:
		_update_preview_for_nav_item(item)

func _activate_nav_item(item: Dictionary) -> void:
	match str(item.get("action", "")):
		"new_game":
			_on_new_game_pressed()
		"slot":
			_on_slot_pressed(int(item["slot"]))
		"settings":
			_on_settings_pressed()
		"quit":
			_on_quit_pressed()

func _button_for_nav_item(item: Dictionary) -> Button:
	match str(item.get("action", "")):
		"new_game":
			return new_game_button
		"slot":
			return slot_buttons[int(item["slot"])]
		"settings":
			return settings_button
		"quit":
			return quit_button
	return null

func _update_preview_for_nav_item(item: Dictionary) -> void:
	match str(item.get("action", "")):
		"new_game":
			_on_new_game_hover()
		"slot":
			_on_slot_hover(int(item["slot"]))
		"settings":
			preview_label.text = "Settings — frame rate and quality"
		"quit":
			preview_label.text = "Quit BikeSim"

func _reset_menu_styles() -> void:
	_style_normal_button(new_game_button, MENU_FONT_NORMAL)
	_style_normal_button(settings_button, 18)
	_style_normal_button(quit_button, 18)
	for button: Button in slot_buttons:
		_style_normal_button(button, MENU_FONT_SLOT_NORMAL)

func _style_normal_button(button: Button, font_size: int) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))

func _style_selected_button(button: Button, is_slot: bool) -> void:
	var font_size := MENU_FONT_SLOT_SELECTED if is_slot else MENU_FONT_SELECTED
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color(1.0, 0.72, 0.28, 1.0))

func _sync_nav_index_to_item(item: Dictionary) -> void:
	_rebuild_nav_items()
	for i in range(_nav_items.size()):
		if str(_nav_items[i].get("action")) != str(item.get("action")):
			continue
		if str(item.get("action")) == "slot" and int(_nav_items[i].get("slot", -1)) != int(item.get("slot", -1)):
			continue
		_nav_index = i
		_apply_nav_selection(false)
		return

func _on_new_game_mouse_hover() -> void:
	_sync_nav_index_to_item({"action": "new_game"})
	_on_new_game_hover()

func _on_slot_mouse_hover(slot: int) -> void:
	_sync_nav_index_to_item({"action": "slot", "slot": slot})
	_on_slot_hover(slot)

func _on_settings_mouse_hover() -> void:
	_sync_nav_index_to_item({"action": "settings"})
	_update_preview_for_nav_item({"action": "settings"})

func _on_quit_mouse_hover() -> void:
	_sync_nav_index_to_item({"action": "quit"})
	_update_preview_for_nav_item({"action": "quit"})

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
	var main: Node = get_tree().current_scene
	if main and main.has_method("show_character_customization"):
		main.show_character_customization("new_game")

func _on_slot_pressed(slot: int) -> void:
	if slot_buttons[slot].disabled or not SaveSystem.has_slot(slot):
		return
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
