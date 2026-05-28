extends Control

@onready var bike: CharacterBody3D = $SubViewportContainer/SubViewport/World/Bike
@onready var speed_label: Label = $HUD/MarginContainer/VBoxContainer/SpeedLabel
@onready var hint_label: Label = $HUD/MarginContainer/VBoxContainer/HintLabel
@onready var mission_label: Label = $HUD/MarginContainer/VBoxContainer/MissionLabel
@onready var checkpoint_label: Label = $HUD/MarginContainer/VBoxContainer/CheckpointLabel
@onready var minimap_marker: ColorRect = $HUD/MinimapPanel/Marker
@onready var rider_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/World/Bike/RiderMesh
@onready var checkpoint: Area3D = $SubViewportContainer/SubViewport/World/CheckpointA
@onready var engine_audio: AudioStreamPlayer3D = $SubViewportContainer/SubViewport/World/Bike/EngineAudio

var spawn_position: Vector3 = Vector3(0, 1.2, 0)
var mission_step: int = 0

func _ready() -> void:
	hint_label.text = "G: Garage | C: Character | R: Reset"
	_update_mission_text()
	checkpoint_label.text = "Checkpoint: not reached"
	_apply_visuals()
	bike.call("set_reset_position", spawn_position)
	checkpoint.body_entered.connect(_on_checkpoint_body_entered)

func _process(_delta: float) -> void:
	var kmh := int((bike as Node).get("speed") * 3.6)
	speed_label.text = "Speed: %d km/h" % max(kmh, 0)
	_update_minimap_marker()
	if Input.is_action_just_pressed("open_garage"):
		_complete_mission_step(0)
		get_tree().root.get_node("Main").show_garage()
	if Input.is_action_just_pressed("open_character_customization"):
		_complete_mission_step(1)
		get_tree().root.get_node("Main").show_character_customization()

func _physics_process(_delta: float) -> void:
	var normalized_speed: float = clamp(abs((bike as Node).get("speed")) / 30.0, 0.0, 1.0)
	engine_audio.pitch_scale = 0.75 + normalized_speed * 0.9
	engine_audio.volume_db = lerp(-18.0, -4.0, normalized_speed)

func _apply_visuals() -> void:
	var bike_mesh: MeshInstance3D = $SubViewportContainer/SubViewport/World/Bike/BikeMesh
	var bike_material := StandardMaterial3D.new()
	bike_material.albedo_color = GameState.bike_config.paint_color
	bike_mesh.material_override = bike_material
	match GameState.bike_config.frame_id:
		"bmx":
			bike_mesh.scale = Vector3(0.85, 0.85, 0.85)
		"road":
			bike_mesh.scale = Vector3(0.95, 0.75, 1.1)
		_:
			bike_mesh.scale = Vector3.ONE

	var rider_material := StandardMaterial3D.new()
	rider_material.albedo_color = GameState.character_config.outfit_color
	rider_mesh.material_override = rider_material

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
	var world_extent := 100.0
	var x: float = clamp((world_pos.x + world_extent) / (world_extent * 2.0), 0.0, 1.0)
	var y: float = clamp((world_pos.z + world_extent) / (world_extent * 2.0), 0.0, 1.0)
	minimap_marker.position = Vector2(x * map_size.x - 4.0, y * map_size.y - 4.0)
