extends Control

@onready var bike: CharacterBody3D = $SubViewportContainer/SubViewport/World/Bike
@onready var speed_label: Label = $HUD/MarginContainer/VBoxContainer/SpeedLabel
@onready var hint_label: Label = $HUD/MarginContainer/VBoxContainer/HintLabel
@onready var mission_label: Label = $HUD/MarginContainer/VBoxContainer/MissionLabel
@onready var checkpoint_label: Label = $HUD/MarginContainer/VBoxContainer/CheckpointLabel
@onready var minimap_marker: ColorRect = $HUD/MinimapPanel/Marker
@onready var rider_visual: Node3D = $SubViewportContainer/SubViewport/World/Bike/RiderVisual
@onready var bike_visual: Node3D = $SubViewportContainer/SubViewport/World/Bike/BikeVisual
@onready var checkpoint: Area3D = $SubViewportContainer/SubViewport/World/CheckpointA
@onready var engine_audio: AudioStreamPlayer3D = $SubViewportContainer/SubViewport/World/Bike/EngineAudio
@onready var world_root: Node3D = $SubViewportContainer/SubViewport/World

var spawn_position: Vector3 = Vector3(0, 0.72, 0)
var mission_step: int = 0
var _garage_zone_active: bool = false
var _pedal_phase: float = 0.0

func _ready() -> void:
	hint_label.text = "Ride to garage entrance to open garage | C: Character | R: Reset"
	_update_mission_text()
	checkpoint_label.text = "Checkpoint: not reached"
	_apply_visuals()
	bike.call("set_reset_position", spawn_position)
	checkpoint.body_entered.connect(_on_checkpoint_body_entered)
	if world_root.has_signal("garage_zone_created"):
		world_root.garage_zone_created.connect(_on_garage_zone_created)
	_connect_existing_garage_zones()

func _process(_delta: float) -> void:
	var kmh := int((bike as Node).get("speed") * 3.6)
	speed_label.text = "Speed: %d km/h" % max(kmh, 0)
	_update_minimap_marker()
	if Input.is_action_just_pressed("open_garage") and _garage_zone_active:
		_complete_mission_step(0)
		get_tree().root.get_node("Main").show_garage()
	elif Input.is_action_just_pressed("open_garage"):
		checkpoint_label.text = "Garage locked: go to garage entrance"
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
	_snap_rider_to_seat()

func _apply_visuals() -> void:
	bike_visual.call("apply_config", GameState.bike_config)
	rider_visual.call("apply_config", GameState.character_config)
	_snap_rider_to_seat()

func _on_checkpoint_body_entered(body: Node3D) -> void:
	if body == bike:
		spawn_position = bike.global_position + Vector3.UP * 0.2
		bike.call("set_reset_position", spawn_position)
		checkpoint_label.text = "Checkpoint: reached"
		_complete_mission_step(2)

func _update_mission_text() -> void:
	match mission_step:
		0:
			mission_label.text = "Tutorial: Open the garage (G)."
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

func _update_minimap_marker() -> void:
	var world_pos: Vector3 = bike.global_position
	var map_size: Vector2 = Vector2(120, 120)
	var local_x: float = fposmod(world_pos.x, 120.0) / 120.0
	var local_y: float = fposmod(world_pos.z, 120.0) / 120.0
	var x: float = clamp(local_x, 0.0, 1.0)
	var y: float = clamp(local_y, 0.0, 1.0)
	minimap_marker.position = Vector2(x * map_size.x - 4.0, y * map_size.y - 4.0)

func _snap_rider_to_seat() -> void:
	var seat_anchor: Node = bike_visual.get_node_or_null("SeatAnchor")
	if seat_anchor and seat_anchor is Node3D:
		rider_visual.position = (seat_anchor as Node3D).position + Vector3(0.0, 0.02, 0.0)

func _connect_existing_garage_zones() -> void:
	for node in world_root.get_children():
		_scan_garage_zone_recursive(node)

func _scan_garage_zone_recursive(node: Node) -> void:
	if node is Area3D and node.has_meta("is_garage_zone"):
		_on_garage_zone_created(node as Area3D)
	for child in node.get_children():
		_scan_garage_zone_recursive(child)

func _on_garage_zone_created(zone: Area3D) -> void:
	if not zone.body_entered.is_connected(_on_garage_zone_body_entered):
		zone.body_entered.connect(_on_garage_zone_body_entered)
	if not zone.body_exited.is_connected(_on_garage_zone_body_exited):
		zone.body_exited.connect(_on_garage_zone_body_exited)

func _on_garage_zone_body_entered(body: Node3D) -> void:
	if body == bike:
		_garage_zone_active = true
		checkpoint_label.text = "Garage entrance: press G"

func _on_garage_zone_body_exited(body: Node3D) -> void:
	if body == bike:
		_garage_zone_active = false
		checkpoint_label.text = "Checkpoint: not reached"
