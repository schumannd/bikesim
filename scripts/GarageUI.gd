extends Control

const BikeConfigResource := preload("res://resources/BikeConfig.gd")
const BikeRigScript := preload("res://scripts/BikeRig.gd")
const BikePaintLibraryScript := preload("res://scripts/BikePaintLibrary.gd")

const MENU_FONT_NORMAL := 22
const MENU_FONT_SELECTED := 30
const BIKE_SHOWROOM_X := 3.2

@onready var bike_visual: Node3D = $ViewportPanel/SubViewportContainer/SubViewport/World/BikePivot/BikeVisual
@onready var bike_pivot: Node3D = $ViewportPanel/SubViewportContainer/SubViewport/World/BikePivot
@onready var showroom_camera: Camera3D = $ViewportPanel/SubViewportContainer/SubViewport/World/Camera3D
@onready var menu_list: VBoxContainer = $MenuPanel/Margin/VBox/MenuList
@onready var selection_label: Label = $MenuPanel/Margin/VBox/DetailBox/SelectionLabel
@onready var value_label: Label = $MenuPanel/Margin/VBox/DetailBox/ValueLabel
@onready var hint_label: Label = $MenuPanel/Margin/VBox/DetailBox/HintLabel
@onready var paint_picker: VBoxContainer = $MenuPanel/Margin/VBox/DetailBox/PaintPicker
@onready var color_grid: GridContainer = $MenuPanel/Margin/VBox/DetailBox/PaintPicker/ColorGrid
@onready var leave_garage_button: Button = $MenuPanel/Margin/VBox/LeaveGarageButton
@onready var cancel_button: Button = $MenuPanel/Margin/VBox/ButtonRow/CancelButton
@onready var viewport_container: SubViewportContainer = $ViewportPanel/SubViewportContainer

var _preview_config: Dictionary = {}
var _category_index: int = 0
var _menu_rows: Array[Label] = []
var _categories: Array[String] = [
	"frame", "wheel", "fork", "handlebar", "seat", "pedal",
	"paint_frame", "paint_fork", "paint_rim", "paint_handlebar", "paint_seat"
]
var _category_names: Dictionary = {
	"frame": "Frame",
	"wheel": "Wheels",
	"fork": "Fork",
	"handlebar": "Handlebar",
	"seat": "Saddle",
	"pedal": "Pedals",
	"paint_frame": "Paint — Frame",
	"paint_fork": "Paint — Fork",
	"paint_rim": "Paint — Rims",
	"paint_handlebar": "Paint — Bars",
	"paint_seat": "Paint — Saddle"
}
var _part_options: Dictionary = {
	"frame": [
		{"id": "trail", "label": "Trail Frame"},
		{"id": "enduro", "label": "Enduro Frame"},
		{"id": "downhill", "label": "Downhill Frame"},
		{"id": "xc", "label": "XC Frame"}
	],
	"wheel": [
		{"id": "mtb_29", "label": "29in MTB"},
		{"id": "mtb_27_5", "label": "27.5in MTB"},
		{"id": "mtb_plus", "label": "Plus Tire"},
		{"id": "gravel_700", "label": "700c Gravel"}
	],
	"fork": [
		{"id": "trail_susp", "label": "Trail Suspension"},
		{"id": "dh_susp", "label": "DH Suspension"},
		{"id": "rigid_carbon", "label": "Rigid Carbon"},
		{"id": "rigid_steel", "label": "Rigid Steel"}
	],
	"handlebar": [
		{"id": "riser", "label": "Riser Bar"},
		{"id": "flat", "label": "Flat Bar"},
		{"id": "dh_bar", "label": "DH Bar"},
		{"id": "bmx", "label": "BMX Bar"}
	],
	"seat": [
		{"id": "trail", "label": "Trail Saddle"},
		{"id": "comfort", "label": "Comfort Saddle"},
		{"id": "slim", "label": "Slim Saddle"},
		{"id": "dh", "label": "DH Saddle"}
	],
	"pedal": [
		{"id": "platform", "label": "Platform Pedals"},
		{"id": "clipless", "label": "Clipless Pedals"},
		{"id": "dh", "label": "DH Pedals"}
	]
}
var _selection_indices: Dictionary = {
	"frame": 0,
	"wheel": 0,
	"fork": 0,
	"handlebar": 0,
	"seat": 0,
	"pedal": 0,
	"paint_frame": 0,
	"paint_fork": 0,
	"paint_rim": 0,
	"paint_handlebar": 0,
	"paint_seat": 0
}
var _paint_finish_indices: Dictionary = {
	"paint_frame": 0,
	"paint_fork": 0,
	"paint_rim": 0,
	"paint_handlebar": 0,
	"paint_seat": 0
}
var _color_swatch_panels: Array[PanelContainer] = []

func _ready() -> void:
	SoundEffects.wire_menu_buttons(self)
	_style_panels()
	_style_leave_button()
	for paint_category: String in ["paint_frame", "paint_fork", "paint_rim", "paint_handlebar", "paint_seat"]:
		_part_options[paint_category] = BikePaintLibraryScript.color_presets()
	_build_color_swatches()
	_build_menu()
	_setup_showroom_camera()
	_init_preview_config()
	_sync_indices_from_config()
	_apply_preview()
	_update_ui()
	set_process_unhandled_input(true)
	resized.connect(_on_resized)

func _style_panels() -> void:
	var menu_style := StyleBoxFlat.new()
	menu_style.bg_color = Color(0.07, 0.08, 0.1, 1.0)
	$MenuPanel.add_theme_stylebox_override("panel", menu_style)
	var viewport_style := StyleBoxFlat.new()
	viewport_style.bg_color = Color(0.05, 0.06, 0.07, 1.0)
	$ViewportPanel.add_theme_stylebox_override("panel", viewport_style)

func _style_leave_button() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1.0, 0.52, 0.08, 1.0)
	normal.corner_radius_top_left = 6
	normal.corner_radius_top_right = 6
	normal.corner_radius_bottom_left = 6
	normal.corner_radius_bottom_right = 6
	normal.content_margin_left = 16.0
	normal.content_margin_right = 16.0
	normal.content_margin_top = 12.0
	normal.content_margin_bottom = 12.0
	var hover := normal.duplicate()
	hover.bg_color = Color(1.0, 0.62, 0.18, 1.0)
	leave_garage_button.add_theme_stylebox_override("normal", normal)
	leave_garage_button.add_theme_stylebox_override("hover", hover)
	leave_garage_button.add_theme_stylebox_override("pressed", hover)
	leave_garage_button.add_theme_color_override("font_color", Color(0.05, 0.05, 0.06, 1.0))
	leave_garage_button.add_theme_color_override("font_hover_color", Color(0.05, 0.05, 0.06, 1.0))
	leave_garage_button.add_theme_color_override("font_pressed_color", Color(0.05, 0.05, 0.06, 1.0))
	leave_garage_button.add_theme_font_size_override("font_size", 26)

func _on_resized() -> void:
	if viewport_container:
		var size := viewport_container.size
		if size.x > 0 and size.y > 0:
			viewport_container.get_child(0).size = Vector2i(int(size.x), int(size.y))

func _setup_showroom_camera() -> void:
	bike_pivot.position = Vector3(BIKE_SHOWROOM_X, 0.0, 0.0)
	var look_target := bike_pivot.position + Vector3(0.0, 0.55, 0.0)
	showroom_camera.position = Vector3(BIKE_SHOWROOM_X - 8.4, 0.95, 0.2)
	showroom_camera.look_at(look_target, Vector3.UP)
	showroom_camera.fov = 36.0

func _build_color_swatches() -> void:
	for child in color_grid.get_children():
		child.queue_free()
	_color_swatch_panels.clear()

	var presets: Array = BikePaintLibraryScript.color_presets()
	for i in range(presets.size()):
		var preset: Dictionary = presets[i]
		var swatch := PanelContainer.new()
		swatch.name = "Swatch_%d" % i
		swatch.custom_minimum_size = Vector2(30, 30)
		swatch.tooltip_text = str(preset["label"])
		swatch.mouse_filter = Control.MOUSE_FILTER_STOP
		swatch.gui_input.connect(_on_swatch_gui_input.bind(i))

		var style := StyleBoxFlat.new()
		style.bg_color = preset["color"]
		style.set_border_width_all(2)
		style.border_color = Color(0.2, 0.2, 0.22, 1.0)
		style.set_corner_radius_all(4)
		swatch.add_theme_stylebox_override("panel", style)
		color_grid.add_child(swatch)
		_color_swatch_panels.append(swatch)

func _on_swatch_gui_input(event: InputEvent, color_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_paint_color_index(_categories[_category_index], color_index)
		SoundEffects.play_menu_move()

func _build_menu() -> void:
	for child in menu_list.get_children():
		child.queue_free()
	_menu_rows.clear()

	for category: String in _categories:
		var row := Label.new()
		row.text = "  %s" % _category_names.get(category, category.capitalize())
		row.add_theme_font_size_override("font_size", MENU_FONT_NORMAL)
		row.add_theme_color_override("font_color", Color(0.72, 0.74, 0.78, 1.0))
		menu_list.add_child(row)
		_menu_rows.append(row)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	var category: String = _categories[_category_index]
	match event.keycode:
		KEY_W, KEY_UP:
			_category_index = posmod(_category_index - 1, _categories.size())
			SoundEffects.play_menu_move()
			_update_ui()
		KEY_S, KEY_DOWN:
			_category_index = posmod(_category_index + 1, _categories.size())
			SoundEffects.play_menu_move()
			_update_ui()
		KEY_A, KEY_LEFT:
			if _is_paint_category(category):
				_step_paint_color(category, -1)
			else:
				_step_option(-1)
			SoundEffects.play_menu_move()
		KEY_D, KEY_RIGHT:
			if _is_paint_category(category):
				_step_paint_color(category, 1)
			else:
				_step_option(1)
			SoundEffects.play_menu_move()
		KEY_Q:
			if _is_paint_category(category):
				_step_paint_finish(category, -1)
				SoundEffects.play_menu_move()
		KEY_E:
			if _is_paint_category(category):
				_step_paint_finish(category, 1)
				SoundEffects.play_menu_move()
		KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0:
			if _is_paint_category(category):
				var digit := _keycode_to_color_index(event.keycode)
				if digit >= 0:
					_select_paint_color_index(category, digit)
					SoundEffects.play_menu_move()
		KEY_ENTER, KEY_KP_ENTER:
			SoundEffects.play_menu_confirm()
			_on_leave_garage_pressed()
		KEY_ESCAPE:
			_on_cancel_pressed()

func _is_paint_category(category: String) -> bool:
	return category.begins_with("paint_")

func _paint_part_key(category: String) -> String:
	return category.replace("paint_", "")

func _keycode_to_color_index(keycode: Key) -> int:
	match keycode:
		KEY_1: return 0
		KEY_2: return 1
		KEY_3: return 2
		KEY_4: return 3
		KEY_5: return 4
		KEY_6: return 5
		KEY_7: return 6
		KEY_8: return 7
		KEY_9: return 8
		KEY_0: return 9
		_: return -1

func _select_paint_color_index(category: String, color_index: int) -> void:
	var presets: Array = BikePaintLibraryScript.color_presets()
	if presets.is_empty():
		return
	color_index = posmod(color_index, presets.size())
	_selection_indices[category] = color_index
	var selected: Dictionary = presets[color_index]
	var part: String = _paint_part_key(category)
	_preview_config["%s_paint_color" % part] = selected["color"]
	_apply_preview()
	_update_ui()

func _step_paint_color(category: String, direction: int) -> void:
	var idx: int = int(_selection_indices[category]) + direction
	_select_paint_color_index(category, idx)

func _step_paint_finish(category: String, direction: int) -> void:
	var finishes: Array = BikePaintLibraryScript.finishes()
	var idx: int = int(_paint_finish_indices[category])
	idx = posmod(idx + direction, finishes.size())
	_paint_finish_indices[category] = idx
	var part: String = _paint_part_key(category)
	_preview_config["%s_paint_finish" % part] = str(finishes[idx]["id"])
	_apply_preview()
	_update_ui()

func _step_option(direction: int) -> void:
	var category: String = _categories[_category_index]
	var options: Array = _part_options[category]
	var idx: int = int(_selection_indices[category])
	idx = posmod(idx + direction, options.size())
	_selection_indices[category] = idx
	var selected: Dictionary = options[idx]
	match category:
		"frame":
			_preview_config["frame_id"] = selected["id"]
		"wheel":
			_preview_config["wheel_id"] = selected["id"]
		"fork":
			_preview_config["fork_id"] = selected["id"]
		"handlebar":
			_preview_config["handlebar_id"] = selected["id"]
		"seat":
			_preview_config["seat_id"] = selected["id"]
		"pedal":
			_preview_config["pedal_id"] = selected["id"]
	_apply_preview()
	_update_ui()

func _on_leave_garage_pressed() -> void:
	_commit_preview_to_game_state()
	_exit_to_ride()

func _on_save_pressed() -> void:
	_on_leave_garage_pressed()

func _on_cancel_pressed() -> void:
	_exit_to_ride()

func _commit_preview_to_game_state() -> void:
	var cfg: Resource = GameState.bike_config
	cfg.frame_id = _preview_config["frame_id"]
	cfg.wheel_id = _preview_config["wheel_id"]
	cfg.fork_id = _preview_config["fork_id"]
	cfg.handlebar_id = _preview_config["handlebar_id"]
	cfg.seat_id = _preview_config["seat_id"]
	cfg.pedal_id = _preview_config["pedal_id"]
	cfg.frame_paint_color = _preview_config["frame_paint_color"]
	cfg.fork_paint_color = _preview_config["fork_paint_color"]
	cfg.rim_paint_color = _preview_config["rim_paint_color"]
	cfg.handlebar_paint_color = _preview_config["handlebar_paint_color"]
	cfg.seat_paint_color = _preview_config["seat_paint_color"]
	cfg.frame_paint_finish = _preview_config["frame_paint_finish"]
	cfg.fork_paint_finish = _preview_config["fork_paint_finish"]
	cfg.rim_paint_finish = _preview_config["rim_paint_finish"]
	cfg.handlebar_paint_finish = _preview_config["handlebar_paint_finish"]
	cfg.seat_paint_finish = _preview_config["seat_paint_finish"]
	cfg.sync_legacy_paint_color()
	GameState.persist()

func _exit_to_ride() -> void:
	GameState.queue_garage_exit()
	var main: Node = get_tree().current_scene
	if main and main.has_method("show_ride_scene"):
		main.show_ride_scene()

func _init_preview_config() -> void:
	var cfg: Resource = GameState.bike_config
	_preview_config = {
		"frame_id": cfg.frame_id,
		"wheel_id": cfg.wheel_id,
		"fork_id": cfg.fork_id,
		"handlebar_id": cfg.handlebar_id,
		"seat_id": cfg.seat_id,
		"pedal_id": cfg.pedal_id,
		"frame_paint_color": cfg.frame_paint_color,
		"fork_paint_color": cfg.fork_paint_color,
		"rim_paint_color": cfg.rim_paint_color,
		"handlebar_paint_color": cfg.handlebar_paint_color,
		"seat_paint_color": cfg.seat_paint_color,
		"frame_paint_finish": cfg.frame_paint_finish,
		"fork_paint_finish": cfg.fork_paint_finish,
		"rim_paint_finish": cfg.rim_paint_finish,
		"handlebar_paint_finish": cfg.handlebar_paint_finish,
		"seat_paint_finish": cfg.seat_paint_finish
	}

func _sync_indices_from_config() -> void:
	_sync_index_for("frame", "frame_id")
	_sync_index_for("wheel", "wheel_id")
	_sync_index_for("fork", "fork_id")
	_sync_index_for("handlebar", "handlebar_id")
	_sync_index_for("seat", "seat_id")
	_sync_index_for("pedal", "pedal_id")
	for paint_category: String in ["paint_frame", "paint_fork", "paint_rim", "paint_handlebar", "paint_seat"]:
		var part: String = _paint_part_key(paint_category)
		var color: Color = _preview_config["%s_paint_color" % part]
		_selection_indices[paint_category] = BikePaintLibraryScript.find_color_index(color)
		_paint_finish_indices[paint_category] = BikePaintLibraryScript.find_finish_index(
			str(_preview_config["%s_paint_finish" % part])
		)

func _sync_index_for(category: String, config_key: String) -> void:
	var options: Array = _part_options[category]
	var value := str(_preview_config[config_key])
	for i in range(options.size()):
		if str(options[i]["id"]) == value:
			_selection_indices[category] = i
			return
	_selection_indices[category] = 0

func _apply_preview() -> void:
	var preview_config: Resource = BikeConfigResource.new()
	for key: String in _preview_config.keys():
		preview_config.set(key, _preview_config[key])
	bike_visual.call("apply_config", preview_config)
	bike_pivot.position = Vector3(BIKE_SHOWROOM_X, BikeRigScript.GARAGE_FLOOR_Y, 0.0)

func _update_ui() -> void:
	var category: String = _categories[_category_index]
	_refresh_menu_highlight()

	selection_label.text = _category_names.get(category, category.capitalize())
	var is_paint := _is_paint_category(category)
	paint_picker.visible = is_paint
	if is_paint:
		var color_options: Array = _part_options[category]
		var color_idx: int = int(_selection_indices[category])
		var finish_idx: int = int(_paint_finish_indices[category])
		var color_label: String = color_options[color_idx]["label"]
		var finish_label: String = BikePaintLibraryScript.finishes()[finish_idx]["label"]
		value_label.text = "%s  ·  %s" % [color_label, finish_label]
		hint_label.text = "↑↓ part   ←→ color (1-0)   Q/E finish   Enter leave   Esc discard"
		_refresh_color_swatch_highlight(color_idx)
	else:
		var options: Array = _part_options[category]
		var idx: int = int(_selection_indices[category])
		value_label.text = options[idx]["label"]
		hint_label.text = "↑↓ part   ←→ option   Enter leave   Esc discard"

func _refresh_color_swatch_highlight(selected_index: int) -> void:
	for i in range(_color_swatch_panels.size()):
		var swatch: PanelContainer = _color_swatch_panels[i]
		var preset: Dictionary = BikePaintLibraryScript.color_preset(i)
		var style := StyleBoxFlat.new()
		style.bg_color = preset["color"]
		style.set_corner_radius_all(4)
		if i == selected_index:
			style.set_border_width_all(3)
			style.border_color = Color(1.0, 0.58, 0.12, 1.0)
		else:
			style.set_border_width_all(2)
			style.border_color = Color(0.25, 0.26, 0.28, 1.0)
		swatch.add_theme_stylebox_override("panel", style)

func _refresh_menu_highlight() -> void:
	for i in range(_menu_rows.size()):
		var row: Label = _menu_rows[i]
		if i == _category_index:
			row.text = "▶ %s" % _category_names.get(_categories[i], _categories[i]).strip_edges()
			row.add_theme_font_size_override("font_size", MENU_FONT_SELECTED)
			row.add_theme_color_override("font_color", Color(1.0, 0.58, 0.12, 1.0))
		else:
			row.text = "  %s" % _category_names.get(_categories[i], _categories[i])
			row.add_theme_font_size_override("font_size", MENU_FONT_NORMAL)
			row.add_theme_color_override("font_color", Color(0.72, 0.74, 0.78, 1.0))
