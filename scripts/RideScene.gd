extends Control

const BikeRigScript := preload("res://scripts/BikeRig.gd")

@onready var bike: CharacterBody3D = $SubViewportContainer/SubViewport/World/Bike
@onready var bike_collision: CollisionShape3D = $SubViewportContainer/SubViewport/World/Bike/CollisionShape3D
@onready var speed_label: Label = $HUD/MarginContainer/VBoxContainer/SpeedLabel
@onready var money_label: Label = $HUD/MoneyLabel
@onready var hint_label: Label = $HUD/MarginContainer/VBoxContainer/HintLabel
@onready var mission_label: Label = $HUD/MarginContainer/VBoxContainer/MissionLabel
@onready var checkpoint_label: Label = $HUD/MarginContainer/VBoxContainer/CheckpointLabel
@onready var minimap: Panel = $HUD/MinimapPanel
@onready var rider_visual: Node3D = $SubViewportContainer/SubViewport/World/Bike/RiderVisual
@onready var bike_visual: Node3D = $SubViewportContainer/SubViewport/World/Bike/BikeVisual
@onready var engine_audio: AudioStreamPlayer3D = $SubViewportContainer/SubViewport/World/Bike/EngineAudio
@onready var world_root: Node3D = $SubViewportContainer/SubViewport/World
@onready var quest_controller: Node3D = $SubViewportContainer/SubViewport/World/QuestController

var spawn_position: Vector3 = BikeRigScript.ride_spawn_position()
var mission_step: int = 0
var _pedal_phase: float = 0.0
var _garage_world_pos: Vector3 = Vector3(-18.0, 0.0, -7.8)
var _wizard_tower_world_pos: Vector3 = Vector3.ZERO
var _has_wizard_tower_poi: bool = false
var _garage_auto_enter_block_until: float = 0.0
var _wizard_auto_enter_block_until: float = 0.0
var _house_auto_enter_block_until: float = 0.0
var _house_in_range: Area3D = null

func _ready() -> void:
	hint_label.text = "E: interact | Golden door: apartment | G: garage | C: character | R: reset"
	_update_mission_text()
	_update_money_label()
	_update_quest_labels()
	_apply_visuals()
	_setup_minimap()
	if quest_controller.has_signal("quest_state_changed"):
		quest_controller.quest_state_changed.connect(_on_quest_state_changed)
	if world_root.has_signal("garage_zone_created"):
		world_root.garage_zone_created.connect(_on_garage_zone_created)
	if world_root.has_signal("wizard_tower_zone_created"):
		world_root.wizard_tower_zone_created.connect(_on_wizard_tower_zone_created)
	if world_root.has_signal("house_entrance_created"):
		world_root.house_entrance_created.connect(_on_house_entrance_created)
	_connect_existing_zones()

func _bike_speed() -> float:
	if bike == null:
		return 0.0
	var value: Variant = (bike as Node).get("speed")
	return float(value) if value != null else 0.0

func _process(_delta: float) -> void:
	var kmh := int(_bike_speed() * 3.6)
	speed_label.text = "Speed: %d km/h" % max(kmh, 0)
	if minimap.has_method("update_for_player"):
		minimap.call("update_for_player", bike.global_position)
	if Input.is_action_just_pressed("open_garage"):
		_enter_garage()
	if Input.is_action_just_pressed("open_character_customization"):
		_complete_mission_step(1)
		get_tree().root.get_node("Main").show_character_customization("ride")
	if Input.is_action_just_pressed("interact"):
		if _try_enter_house():
			pass
		elif quest_controller.has_method("try_interact"):
			quest_controller.call("try_interact")
	_update_quest_labels()

func _physics_process(_delta: float) -> void:
	var current_speed := _bike_speed()
	var normalized_speed: float = clamp(absf(current_speed) / 30.0, 0.0, 1.0)
	engine_audio.pitch_scale = 0.75 + normalized_speed * 0.9
	engine_audio.volume_db = lerp(-18.0, -4.0, normalized_speed)
	_pedal_phase += absf(current_speed) * _delta * 0.9
	bike_visual.call("animate_drive", current_speed, _delta)
	rider_visual.call("animate_pedaling", _pedal_phase, normalized_speed)

func _apply_visuals() -> void:
	bike_visual.call("apply_config", GameState.bike_config)
	rider_visual.call("apply_config", GameState.character_config)
	bike_visual.call("mount_rider", rider_visual)

	var wheel_radius: float = bike_visual.call("get_wheel_radius")
	bike.position = BikeRigScript.ride_spawn_position(bike.position)
	bike_collision.position.y = BikeRigScript.collision_shape_y(wheel_radius)
	if bike.has_method("set_wheel_radius"):
		bike.call("set_wheel_radius", wheel_radius)
	spawn_position = BikeRigScript.ride_spawn_position(spawn_position)
	bike.call("set_reset_position", spawn_position)
	_apply_exit_spawns_if_pending()

func _apply_exit_spawns_if_pending() -> void:
	var garage_exit: Vector3 = GameState.consume_garage_exit_spawn()
	var wizard_exit: Vector3 = GameState.consume_wizard_exit_spawn()
	var house_exit: Vector3 = GameState.consume_house_exit_spawn()
	var house_yaw: float = GameState.consume_house_exit_yaw()
	if garage_exit == Vector3.INF and wizard_exit == Vector3.INF and house_exit == Vector3.INF:
		return
	if house_exit != Vector3.INF:
		bike.global_position = house_exit
		bike.rotation.y = house_yaw
		_house_auto_enter_block_until = Time.get_ticks_msec() / 1000.0 + 2.5
	elif garage_exit != Vector3.INF:
		bike.global_position = BikeRigScript.ride_spawn_position(garage_exit)
		bike.rotation.y = BikeRigScript.garage_exit_yaw()
		_garage_auto_enter_block_until = Time.get_ticks_msec() / 1000.0 + 2.5
	elif wizard_exit != Vector3.INF:
		bike.global_position = wizard_exit
		bike.rotation.y = BikeRigScript.wizard_exit_yaw(GameState.wizard_tower_world_position)
		_wizard_auto_enter_block_until = Time.get_ticks_msec() / 1000.0 + 2.5
	spawn_position = bike.global_position
	bike.call("set_reset_position", spawn_position)
	_refresh_minimap_pois()

func _on_quest_state_changed() -> void:
	_update_money_label()
	_update_quest_labels()
	_refresh_minimap_pois()

func _update_money_label() -> void:
	money_label.text = GameState.format_money()

func _update_quest_labels() -> void:
	if quest_controller.has_method("get_quest_status_text"):
		mission_label.text = quest_controller.call("get_quest_status_text")
	if GameState.quest_active:
		checkpoint_label.text = "Follow the arrow to the next checkpoint"
	elif GameState.quest_completed:
		checkpoint_label.text = "Quest finished — $2.00 earned"
	else:
		checkpoint_label.text = "Press E at the golden mist to start the quest"

func _update_mission_text() -> void:
	if GameState.quest_completed:
		mission_label.text = "Quest complete — explore freely"
		return
	match mission_step:
		0:
			mission_label.text = "Tutorial: Enter the garage (ride in or press G)."
		1:
			mission_label.text = "Tutorial: Edit character (C) or find the purple wizard tower."
		_:
			if quest_controller.has_method("get_quest_status_text"):
				mission_label.text = quest_controller.call("get_quest_status_text")
			else:
				mission_label.text = "Ride freely."

func _complete_mission_step(required_step: int) -> void:
	if mission_step != required_step:
		return
	mission_step += 1
	_update_mission_text()

func _setup_minimap() -> void:
	if not minimap.has_method("set_points_of_interest"):
		return
	var pois: Array = [
		{
			"id": "garage",
			"world_position": _garage_world_pos,
			"color": Color(1.0, 0.55, 0.08, 1.0)
		},
		{
			"id": "spawn",
			"world_position": spawn_position,
			"color": Color(0.75, 0.75, 0.75, 1.0)
		}
	]
	if not GameState.quest_completed:
		var quest_pos: Vector3 = Vector3.INF
		if quest_controller.has_method("get_active_quest_position"):
			quest_pos = quest_controller.call("get_active_quest_position")
		if quest_pos != Vector3.INF:
			var quest_color := Color(1.0, 0.82, 0.2, 1.0)
			if GameState.quest_active:
				quest_color = Color(0.2, 0.85, 1.0, 1.0)
			pois.append({
				"id": "quest",
				"world_position": quest_pos,
				"color": quest_color
			})
	if _has_wizard_tower_poi:
		pois.append({
			"id": "wizard",
			"world_position": _wizard_tower_world_pos,
			"color": Color(0.72, 0.28, 1.0, 1.0)
		})
	minimap.call("set_points_of_interest", pois)

func _refresh_minimap_pois() -> void:
	_setup_minimap()

func _connect_existing_zones() -> void:
	for node in world_root.get_children():
		_scan_zones_recursive(node)

func _scan_zones_recursive(node: Node) -> void:
	if node is Area3D:
		if node.has_meta("is_garage_zone"):
			_on_garage_zone_created(node as Area3D)
		if node.has_meta("is_wizard_tower_zone"):
			_on_wizard_tower_zone_created(node as Area3D)
		if node.has_meta("is_house_entrance"):
			_on_house_entrance_created(node as Area3D)
	for child in node.get_children():
		_scan_zones_recursive(child)

func _on_garage_zone_created(zone: Area3D) -> void:
	_garage_world_pos = zone.global_position
	_refresh_minimap_pois()
	if not zone.body_entered.is_connected(_on_garage_zone_body_entered):
		zone.body_entered.connect(_on_garage_zone_body_entered)

func _on_garage_zone_body_entered(body: Node3D) -> void:
	if body == bike:
		_enter_garage()

func _on_wizard_tower_zone_created(zone: Area3D) -> void:
	_wizard_tower_world_pos = zone.global_position
	_has_wizard_tower_poi = true
	_refresh_minimap_pois()
	if not zone.body_entered.is_connected(_on_wizard_tower_zone_body_entered):
		zone.body_entered.connect(_on_wizard_tower_zone_body_entered)

func _on_wizard_tower_zone_body_entered(body: Node3D) -> void:
	if body == bike:
		_enter_wizard_tower()

func _enter_garage() -> void:
	if Time.get_ticks_msec() / 1000.0 < _garage_auto_enter_block_until:
		return
	_complete_mission_step(0)
	get_tree().root.get_node("Main").show_garage()

func _enter_wizard_tower() -> void:
	if Time.get_ticks_msec() / 1000.0 < _wizard_auto_enter_block_until:
		return
	_complete_mission_step(1)
	GameState.wizard_tower_world_position = _wizard_tower_world_pos
	get_tree().root.get_node("Main").show_character_customization("wizard_tower")

func _on_house_entrance_created(zone: Area3D) -> void:
	if not zone.body_entered.is_connected(_on_house_entrance_body_entered):
		zone.body_entered.connect(_on_house_entrance_body_entered.bind(zone))
	if not zone.body_exited.is_connected(_on_house_entrance_body_exited):
		zone.body_exited.connect(_on_house_entrance_body_exited.bind(zone))

func _on_house_entrance_body_entered(body: Node3D, zone: Area3D) -> void:
	if body == bike:
		_house_in_range = zone
		_enter_house(zone)

func _on_house_entrance_body_exited(body: Node3D, _zone: Area3D) -> void:
	if body == bike:
		_house_in_range = null

func _try_enter_house() -> bool:
	if _house_in_range == null or not is_instance_valid(_house_in_range):
		return false
	_enter_house(_house_in_range)
	return true

func _enter_house(zone: Area3D) -> void:
	if Time.get_ticks_msec() / 1000.0 < _house_auto_enter_block_until:
		return
	var seed := int(zone.get_meta("house_seed", 0))
	GameState.begin_house_visit(zone.global_position, bike.rotation.y, seed)
	_house_in_range = null
	get_tree().root.get_node("Main").show_house_interior()
