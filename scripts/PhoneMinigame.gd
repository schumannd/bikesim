extends Control

## Slide stones to the left edge of the phone screen using the credit card (mouse).

const STONE_COUNT := 6
const TABLE_FRICTION := 0.55
const STONE_FRICTION := 0.42
const CARD_FRICTION := 0.35

@onready var viewport: SubViewport = $SubViewportContainer/SubViewport
@onready var world: Node2D = $SubViewportContainer/SubViewport/WorldRoot
@onready var status_label: Label = $HUD/StatusLabel
@onready var hint_label: Label = $HUD/HintLabel

var _stones: Array[RigidBody2D] = []
var _card: RigidBody2D
var _goal_x: float = -155.0
var _won: bool = false
var _table_material: PhysicsMaterial

func _ready() -> void:
	_table_material = PhysicsMaterial.new()
	_table_material.friction = TABLE_FRICTION
	_table_material.bounce = 0.08
	_build_table()
	_build_stones()
	_build_card()
	_build_walls()
	hint_label.text = "Move the card with your mouse — push all stones past the left edge"
	status_label.text = "Stones remaining: %d" % STONE_COUNT
	set_process(true)
	set_physics_process(true)

func _physics_process(_delta: float) -> void:
	if _won or _card == null:
		return
	var target := _mouse_in_world()
	var diff := target - _card.global_position
	_card.linear_velocity = diff * 18.0
	_card.angular_velocity = 0.0
	_update_status()

func _process(_delta: float) -> void:
	if _won:
		return
	if _check_win():
		_won = true
		status_label.text = "You cleared the board!"
		SoundEffects.play_menu_confirm()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_minigame()

func close_minigame() -> void:
	visible = false
	set_process(false)
	set_physics_process(false)

func restart() -> void:
	_won = false
	for child in world.get_children():
		child.queue_free()
	_stones.clear()
	_card = null
	_build_table()
	_build_walls()
	_build_stones()
	_build_card()
	status_label.text = "Stones on left: 0 / %d" % STONE_COUNT
	hint_label.text = "Move the card with your mouse — push all stones past the left edge"
	set_process(true)
	set_physics_process(true)

func _mouse_in_world() -> Vector2:
	var global_mouse := get_global_mouse_position()
	var container: SubViewportContainer = $SubViewportContainer
	var local := container.get_global_transform().affine_inverse() * global_mouse
	var ratio := container.size / Vector2(viewport.size)
	if ratio.x < 0.001 or ratio.y < 0.001:
		return Vector2.ZERO
	var vp_pos := local / ratio
	return vp_pos

func _build_table() -> void:
	var table := StaticBody2D.new()
	table.name = "Table"
	table.position = Vector2(0.0, 40.0)
	table.physics_material_override = _table_material
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(300.0, 420.0)
	shape.shape = rect
	table.add_child(shape)
	world.add_child(table)

	var visual := ColorRect.new()
	visual.size = rect.size
	visual.position = rect.size * -0.5
	visual.color = Color(0.12, 0.14, 0.18, 1.0)
	table.add_child(visual)

func _build_walls() -> void:
	var wall_mat := PhysicsMaterial.new()
	wall_mat.friction = 0.2
	wall_mat.bounce = 0.15
	var specs := [
		[Vector2(0.0, -175.0), Vector2(320.0, 20.0)],
		[Vector2(0.0, 255.0), Vector2(320.0, 20.0)],
		[Vector2(-170.0, 40.0), Vector2(20.0, 400.0)],
		[Vector2(170.0, 40.0), Vector2(20.0, 400.0)],
	]
	for spec in specs:
		var wall := StaticBody2D.new()
		wall.position = spec[0]
		wall.physics_material_override = wall_mat
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = spec[1]
		shape.shape = rect
		wall.add_child(shape)
		world.add_child(wall)

func _build_stones() -> void:
	var stone_mat := PhysicsMaterial.new()
	stone_mat.friction = STONE_FRICTION
	stone_mat.bounce = 0.12
	var rng := RandomNumberGenerator.new()
	rng.seed = int(GameState.current_house_seed) ^ 20790
	var positions := [
		Vector2(-40.0, -20.0),
		Vector2(30.0, -50.0),
		Vector2(80.0, 10.0),
		Vector2(-70.0, 60.0),
		Vector2(20.0, 70.0),
		Vector2(90.0, -70.0),
	]
	for i in STONE_COUNT:
		var stone := RigidBody2D.new()
		stone.name = "Stone_%d" % i
		stone.position = positions[i] + Vector2(rng.randf_range(-15.0, 15.0), rng.randf_range(-10.0, 10.0))
		stone.gravity_scale = 1.0
		stone.physics_material_override = stone_mat
		stone.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = rng.randf_range(16.0, 22.0)
		shape.shape = circle
		stone.add_child(shape)
		var dot := Polygon2D.new()
		var r := circle.radius
		dot.polygon = PackedVector2Array([
			Vector2(-r, 0), Vector2(0, -r), Vector2(r, 0), Vector2(0, r)
		])
		dot.color = Color.from_hsv(rng.randf(), 0.35, rng.randf_range(0.55, 0.75), 1.0)
		stone.add_child(dot)
		world.add_child(stone)
		_stones.append(stone)

func _build_card() -> void:
	_card = RigidBody2D.new()
	_card.name = "CreditCard"
	_card.position = Vector2(60.0, 80.0)
	_card.gravity_scale = 0.0
	_card.lock_rotation = true
	_card.mass = 4.0
	var card_mat := PhysicsMaterial.new()
	card_mat.friction = CARD_FRICTION
	card_mat.bounce = 0.05
	_card.physics_material_override = card_mat
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(72.0, 44.0)
	shape.shape = rect
	_card.add_child(shape)
	var visual := ColorRect.new()
	visual.size = rect.size
	visual.position = rect.size * -0.5
	visual.color = Color(0.85, 0.82, 0.75, 1.0)
	_card.add_child(visual)
	var stripe := ColorRect.new()
	stripe.size = Vector2(rect.size.x, 8.0)
	stripe.position = Vector2(-rect.size.x * 0.5, -6.0)
	stripe.color = Color(0.2, 0.35, 0.75, 1.0)
	_card.add_child(stripe)
	world.add_child(_card)

func _stones_on_goal_side() -> int:
	var count := 0
	for stone: RigidBody2D in _stones:
		if not is_instance_valid(stone):
			continue
		if stone.global_position.x <= _goal_x:
			count += 1
	return count

func _check_win() -> bool:
	return _stones_on_goal_side() >= STONE_COUNT

func _update_status() -> void:
	var done := _stones_on_goal_side()
	status_label.text = "Stones on left: %d / %d" % [done, STONE_COUNT]
