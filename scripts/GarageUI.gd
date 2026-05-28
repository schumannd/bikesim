extends Control

const BikeConfigResource := preload("res://resources/BikeConfig.gd")
const BikeRigScript := preload("res://scripts/BikeRig.gd")

@onready var bike_visual: Node3D = $SubViewportContainer/SubViewport/World/BikePivot/BikeVisual
@onready var bike_pivot: Node3D = $SubViewportContainer/SubViewport/World/BikePivot
@onready var selection_label: Label = $Overlay/Panel/MarginContainer/VBoxContainer/SelectionLabel
@onready var value_label: Label = $Overlay/Panel/MarginContainer/VBoxContainer/ValueLabel

var _preview_config: Dictionary = {}
var _category_index: int = 0
var _categories: Array[String] = ["frame", "wheel", "fork", "handlebar", "seat", "pedal", "paint"]
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
	],
	"paint": [
		{"id": "sunset_orange", "label": "Sunset Orange", "color": Color(0.88, 0.35, 0.15, 1.0)},
		{"id": "trail_green", "label": "Trail Green", "color": Color(0.2, 0.56, 0.3, 1.0)},
		{"id": "arctic_blue", "label": "Arctic Blue", "color": Color(0.1, 0.5, 0.9, 1.0)},
		{"id": "factory_black", "label": "Factory Black", "color": Color(0.15, 0.15, 0.17, 1.0)},
		{"id": "crimson", "label": "Crimson", "color": Color(0.72, 0.12, 0.18, 1.0)},
		{"id": "violet", "label": "Violet", "color": Color(0.42, 0.2, 0.78, 1.0)}
	]
}
var _selection_indices: Dictionary = {
	"frame": 0,
	"wheel": 0,
	"fork": 0,
	"handlebar": 0,
	"seat": 0,
	"pedal": 0,
	"paint": 0
}

func _ready() -> void:
	_init_preview_config()
	_sync_indices_from_config()
	_apply_preview()
	_update_labels()
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A:
				_category_index = posmod(_category_index - 1, _categories.size())
				_update_labels()
			KEY_D:
				_category_index = posmod(_category_index + 1, _categories.size())
				_update_labels()
			KEY_W:
				_step_option(1)
			KEY_S:
				_step_option(-1)
			KEY_Q:
				bike_pivot.rotate_y(0.12)
			KEY_E:
				bike_pivot.rotate_y(-0.12)
			KEY_ENTER:
				_on_save_pressed()
			KEY_ESCAPE:
				_on_cancel_pressed()

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
		"paint":
			_preview_config["paint_color"] = selected["color"]
	_apply_preview()
	_update_labels()

func _on_save_pressed() -> void:
	GameState.bike_config.paint_color = _preview_config["paint_color"]
	GameState.bike_config.frame_id = _preview_config["frame_id"]
	GameState.bike_config.wheel_id = _preview_config["wheel_id"]
	GameState.bike_config.fork_id = _preview_config["fork_id"]
	GameState.bike_config.handlebar_id = _preview_config["handlebar_id"]
	GameState.bike_config.seat_id = _preview_config["seat_id"]
	GameState.bike_config.pedal_id = _preview_config["pedal_id"]
	GameState.persist()
	var main: Node = get_tree().current_scene
	if main and main.has_method("show_ride_scene"):
		main.show_ride_scene()

func _on_cancel_pressed() -> void:
	var main: Node = get_tree().current_scene
	if main and main.has_method("show_ride_scene"):
		main.show_ride_scene()

func _init_preview_config() -> void:
	_preview_config = {
		"frame_id": GameState.bike_config.frame_id,
		"wheel_id": GameState.bike_config.wheel_id,
		"fork_id": GameState.bike_config.fork_id,
		"handlebar_id": GameState.bike_config.handlebar_id,
		"seat_id": GameState.bike_config.seat_id,
		"pedal_id": GameState.bike_config.pedal_id,
		"paint_color": GameState.bike_config.paint_color
	}

func _sync_indices_from_config() -> void:
	_sync_index_for("frame", "frame_id")
	_sync_index_for("wheel", "wheel_id")
	_sync_index_for("fork", "fork_id")
	_sync_index_for("handlebar", "handlebar_id")
	_sync_index_for("seat", "seat_id")
	_sync_index_for("pedal", "pedal_id")
	var paint_options: Array = _part_options["paint"]
	var best_idx: int = 0
	var best_dist: float = 9999.0
	for i in range(paint_options.size()):
		var c: Color = paint_options[i]["color"]
		var d := absf(c.r - _preview_config["paint_color"].r) + absf(c.g - _preview_config["paint_color"].g) + absf(c.b - _preview_config["paint_color"].b)
		if d < best_dist:
			best_dist = d
			best_idx = i
	_selection_indices["paint"] = best_idx

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
	preview_config.set("frame_id", _preview_config["frame_id"])
	preview_config.set("wheel_id", _preview_config["wheel_id"])
	preview_config.set("fork_id", _preview_config["fork_id"])
	preview_config.set("handlebar_id", _preview_config["handlebar_id"])
	preview_config.set("seat_id", _preview_config["seat_id"])
	preview_config.set("pedal_id", _preview_config["pedal_id"])
	preview_config.set("paint_color", _preview_config["paint_color"])
	bike_visual.call("apply_config", preview_config)
	bike_pivot.position = Vector3(0.0, BikeRigScript.GARAGE_FLOOR_Y, 0.0)

func _update_labels() -> void:
	var category: String = _categories[_category_index]
	var category_name := category.capitalize()
	selection_label.text = "Selected: %s (A/D)" % category_name
	var options: Array = _part_options[category]
	var idx: int = int(_selection_indices[category])
	var selected: Dictionary = options[idx]
	value_label.text = "Option: %s (W/S)" % selected["label"]
