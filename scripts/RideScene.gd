extends Control

const BikeRigScript := preload("res://scripts/BikeRig.gd")

@onready var bike: CharacterBody3D = $SubViewportContainer/SubViewport/World/Bike
@onready var bike_collision: CollisionShape3D = $SubViewportContainer/SubViewport/World/Bike/CollisionShape3D
@onready var speed_label: Label = $HUD/MarginContainer/VBoxContainer/SpeedLabel
@onready var hint_label: Label = $HUD/MarginContainer/VBoxContainer/HintLabel
@onready var mission_label: Label = $HUD/MarginContainer/VBoxContainer/MissionLabel
@onready var checkpoint_label: Label = $HUD/MarginContainer/VBoxContainer/CheckpointLabel
@onready var minimap: Panel = $HUD/MinimapPanel
@onready var rider_visual: Node3D = $SubViewportContainer/SubViewport/World/Bike/RiderVisual
@onready var bike_visual: Node3D = $SubViewportContainer/SubViewport/World/Bike/BikeVisual
@onready var checkpoint: Area3D = $SubViewportContainer/SubViewport/World/CheckpointA
@onready var engine_audio: AudioStreamPlayer3D = $SubViewportContainer/SubViewport/World/Bike/EngineAudio
@onready var world_root: Node3D = $SubViewportContainer/SubViewport/World

var spawn_position: Vector3 = BikeRigScript.ride_spawn_position()
var mission_step: int = 0
var _pedal_phase: float = 0.0
var _garage_world_pos: Vector3 = Vector3(-18.0, 0.0, -7.8)
var _garage_auto_enter_block_until: float = 0.0

func _ready() -> void:
	hint_label.text = "Ride to the orange garage to enter automatically — or press G anywhere | C: Character | R: Reset"
	_update_mission_text()
	checkpoint_label.text = "Checkpoint: not reached"
	_apply_visuals()
	_setup_minimap()
	checkpoint.body_entered.connect(_on_checkpoint_body_entered)
	if world_root.has_signal("garage_zone_created"):
		world_root.garage_zone_created.connect(_on_garage_zone_created)
	_connect_existing_garage_zones()

func _process(_delta: float) -> void:
	var kmh := int((bike as Node).get("speed") * 3.6)
	speed_label.text = "Speed: %d km/h" % max(kmh, 0)
	if minimap.has_method("update_for_player"):
		minimap.call("update_for_player", bike.global_position)
	if Input.is_action_just_pressed("open_garage"):
		_enter_garage()
	if Input.is_action_just_pressed("open_character_customization"):
		_complete_mission_step(1)
		get_tree().root.get_node("Main").show_character_customization()

func _physics_process(_delta: float) -> void:
	var normalized_speed: float = clamp(abs((bike as Node).get("speed")) / 30.0, 0.0, 1.0)
	engine_audio.pitch_scale = 0.75 + normalized_speed * 0.9
	engine_audio.volume_db = lerp(-18.0, -4.0, normalized_speed)
	_pedal_phase += abs((bike as Node).get("speed")) * _delta * 0.9
	bike_visual.call("animate_drive", (bike as Node).get("speed"), _delta)
	rider_visual.call("animate_pedaling", _pedal_phase, normalized_speed)

func _apply_visuals() -> void:
	bike_visual.call("apply_config", GameState.bike_config)
	rider_visual.call("apply_config", GameState.character_config)
	bike_visual.call("mount_rider", rider_visual)

	var wheel_radius: float = bike_visual.call("get_wheel_radius")
	bike.position = BikeRigScript.ride_spawn_position(bike.position)
	bike_collision.position.y = BikeRigScript.collision_shape_y(wheel_radius)
	spawn_position = BikeRigScript.ride_spawn_position(spawn_position)
	bike.call("set_reset_position", spawn_position)
	_apply_garage_exit_spawn_if_pending()

func _apply_garage_exit_spawn_if_pending() -> void:
	var exit_pos: Vector3 = GameState.consume_garage_exit_spawn()
	if exit_pos == Vector3.INF:
		return
	bike.global_position = BikeRigScript.ride_spawn_position(exit_pos)
	bike.rotation.y = BikeRigScript.garage_exit_yaw()
	spawn_position = bike.global_position
	bike.call("set_reset_position", spawn_position)
	_garage_auto_enter_block_until = Time.get_ticks_msec() / 1000.0 + 2.5
	_refresh_minimap_pois()

func _on_checkpoint_body_entered(body: Node3D) -> void:
	if body == bike:
		spawn_position = BikeRigScript.ride_spawn_position(bike.global_position)
		bike.call("set_reset_position", spawn_position)
		checkpoint_label.text = "Checkpoint: reached"
		_complete_mission_step(2)

func _update_mission_text() -> void:
	match mission_step:
		0:
			mission_label.text = "Tutorial: Enter the garage (ride in or press G)."
		1:
			mission_label.text = "Tutorial: Open character customization (C)."
		2:
			mission_label.text = "Tutorial: Reach checkpoint marker."
		_:
			mission_label.text = "Tutorial complete. Ride freely."

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
			"id": "checkpoint",
			"world_position": checkpoint.global_position,
			"color": Color(0.2, 0.85, 1.0, 1.0)
		},
		{
			"id": "spawn",
			"world_position": spawn_position,
			"color": Color(0.75, 0.75, 0.75, 1.0)
		}
	]
	minimap.call("set_points_of_interest", pois)

func _refresh_minimap_pois() -> void:
	_setup_minimap()

func _connect_existing_garage_zones() -> void:
	for node in world_root.get_children():
		_scan_garage_zone_recursive(node)

func _scan_garage_zone_recursive(node: Node) -> void:
	if node is Area3D and node.has_meta("is_garage_zone"):
		_on_garage_zone_created(node as Area3D)
	for child in node.get_children():
		_scan_garage_zone_recursive(child)

func _on_garage_zone_created(zone: Area3D) -> void:
	_garage_world_pos = zone.global_position
	_refresh_minimap_pois()
	if not zone.body_entered.is_connected(_on_garage_zone_body_entered):
		zone.body_entered.connect(_on_garage_zone_body_entered)
func _on_garage_zone_body_entered(body: Node3D) -> void:
	if body == bike:
		_enter_garage()

func _enter_garage() -> void:
	if Time.get_ticks_msec() / 1000.0 < _garage_auto_enter_block_until:
		return
	_complete_mission_step(0)
	get_tree().root.get_node("Main").show_garage()
