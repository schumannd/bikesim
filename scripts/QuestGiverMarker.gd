extends Area3D

const RiderVisualBuilderScript := preload("res://scripts/RiderVisualBuilder.gd")
const CharacterConfigResource := preload("res://resources/CharacterConfig.gd")

const GOLD_MIST := Color(1.0, 0.82, 0.2, 0.14)
const GOLD_CORE := Color(1.0, 0.92, 0.45, 0.2)

signal interact_requested

var player_in_range: bool = false
var _pulse: float = 0.0
var _visual_root: Node3D

func _ready() -> void:
	_build_golden_mist()
	_build_quest_npc()
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(delta: float) -> void:
	if _visual_root == null:
		return
	_pulse += delta * 1.4
	var breathe := 1.0 + sin(_pulse) * 0.07
	_visual_root.scale = Vector3(breathe, 1.0 + sin(_pulse * 0.7) * 0.03, breathe)

func hide_giver() -> void:
	visible = false
	monitoring = false

func _build_quest_npc() -> void:
	var npc := Node3D.new()
	npc.name = "QuestNPC"
	npc.position = Vector3(0.0, 0.0, 0.0)
	add_child(npc)
	var rider := Node3D.new()
	rider.name = "RiderVisual"
	rider.set_script(RiderVisualBuilderScript)
	npc.add_child(rider)
	var cfg: Resource = CharacterConfigResource.new()
	cfg.outfit_id = "race"
	cfg.hair_style = "helmet"
	cfg.outfit_color = Color(0.95, 0.78, 0.12, 1.0)
	cfg.skin_tone = Color(0.82, 0.66, 0.5, 1.0)
	rider.call("apply_config", cfg)

func _build_golden_mist() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "GoldenMist"
	add_child(_visual_root)

	_add_disc(Vector3(0.0, 0.05, 0.0), 2.6, 0.14)
	for i in range(4):
		var h := 1.5 + float(i) * 1.4
		_add_cylinder(Vector3(0.0, h * 0.5, 0.0), 1.2 - float(i) * 0.12, 0.95 - float(i) * 0.1, h)

	var light := OmniLight3D.new()
	light.position = Vector3(0.0, 2.0, 0.0)
	light.light_color = Color(1.0, 0.85, 0.25, 1.0)
	light.light_energy = 1.4
	light.omni_range = 12.0
	_visual_root.add_child(light)

func _add_cylinder(pos: Vector3, bottom_r: float, top_r: float, height: float) -> void:
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = 20
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = _mist_mat(GOLD_MIST, 0.09, 0.7)
	_visual_root.add_child(mesh_inst)

func _add_disc(pos: Vector3, radius: float, height: float) -> void:
	var mesh_inst := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 28
	mesh_inst.mesh = mesh
	mesh_inst.position = pos
	mesh_inst.material_override = _mist_mat(GOLD_CORE, 0.12, 0.9)
	_visual_root.add_child(mesh_inst)

func _mist_mat(color: Color, alpha: float, emission: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(color.r, color.g, color.b, alpha)
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = emission
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func _on_body_entered(body: Node3D) -> void:
	if body != null and body.name == "Bike":
		player_in_range = true

func _on_body_exited(body: Node3D) -> void:
	if body != null and body.name == "Bike":
		player_in_range = false

func request_interact() -> void:
	if player_in_range:
		interact_requested.emit()
