extends CharacterBody3D

const BikeRigScript := preload("res://scripts/BikeRig.gd")

@export var acceleration: float = 18.0
@export var max_speed: float = 30.0
@export var brake_power: float = 20.0
@export var steering_speed: float = 2.2
@export var steer_gain_at_stop: float = 2.6
@export var steer_gain_at_max_speed: float = 0.4
@export var gravity: float = 18.0
@export var step_probe_distance: float = 0.55

var speed: float = 0.0
var reset_position: Vector3 = BikeRigScript.ride_spawn_position()
var _wheel_radius: float = 0.44
var _wall_hit_cooldown: float = 0.0

func _ready() -> void:
	floor_snap_length = 0.35
	floor_max_angle = deg_to_rad(58.0)

func set_wheel_radius(radius: float) -> void:
	_wheel_radius = maxf(radius, 0.2)

func _physics_process(delta: float) -> void:
	var throttle := Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	var steer := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	var braking := Input.is_action_pressed("brake")

	speed += throttle * acceleration * delta
	if braking:
		speed = move_toward(speed, 0.0, brake_power * delta)
	elif abs(throttle) < 0.01:
		speed = move_toward(speed, 0.0, 6.0 * delta)
	speed = move_toward(speed, 0.0, abs(speed) * 0.18 * delta)
	speed = clamp(speed, -max_speed * 0.3, max_speed)
	var steer_gain := _steer_gain_for_speed(speed)
	rotate_y(-steer * steering_speed * steer_gain * delta)

	var forward := -global_transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	if not is_on_floor():
		velocity.y -= gravity * delta
	_try_step_up(forward)
	move_and_slide()
	_handle_impact_sounds(braking)

	if BikeRigScript.should_reset_fall(global_position.y):
		global_position = reset_position
		basis = Basis.IDENTITY
		velocity = Vector3.ZERO
		speed = 0.0

	if Input.is_action_just_pressed("quick_reset"):
		global_position = reset_position
		basis = Basis.IDENTITY
		velocity = Vector3.ZERO
		speed = 0.0

func set_reset_position(pos: Vector3) -> void:
	reset_position = BikeRigScript.ride_spawn_position(pos)

func _steer_gain_for_speed(current_speed: float) -> float:
	var speed_ratio := clampf(abs(current_speed) / max_speed, 0.0, 1.0)
	# Quadratic falloff: nimble U-turns when slow, stable arcs when fast.
	var blend := speed_ratio * speed_ratio
	return lerpf(steer_gain_at_stop, steer_gain_at_max_speed, blend)

func _try_step_up(forward: Vector3) -> void:
	if not is_on_floor() or abs(speed) < 0.4:
		return
	var planar := Vector3(forward.x, 0.0, forward.z)
	if planar.length_squared() < 0.01:
		return
	planar = planar.normalized()
	var max_step := BikeRigScript.max_step_height(_wheel_radius)
	var floor_y := get_floor_position().y
	var space := get_world_3d().direct_space_state
	var ahead := global_position + planar * step_probe_distance
	var low_from := ahead + Vector3.UP * 0.1
	var low_to := ahead - Vector3.UP * 0.4
	var q_low := PhysicsRayQueryParameters3D.create(low_from, low_to)
	q_low.exclude = [get_rid()]
	var hit_low := space.intersect_ray(q_low)
	if hit_low.is_empty():
		return
	var rise := hit_low.position.y - floor_y
	if rise < 0.03 or rise > max_step + 0.02:
		return
	var high_from := ahead + Vector3.UP * (max_step + 0.15)
	var high_to := ahead + Vector3.UP * 0.12
	var q_high := PhysicsRayQueryParameters3D.create(high_from, high_to)
	q_high.exclude = [get_rid()]
	if not space.intersect_ray(q_high).is_empty():
		return
	global_position.y += rise + 0.03
	velocity.y = maxf(velocity.y, 0.0)

func _handle_impact_sounds(braking: bool) -> void:
	var brake_power := 0.0
	if braking and absf(speed) > 0.8:
		brake_power = clampf(absf(speed) / max_speed, 0.0, 1.0)
	SoundEffects.set_brake_active(brake_power > 0.05, brake_power)

	if _wall_hit_cooldown > 0.0:
		_wall_hit_cooldown = maxf(_wall_hit_cooldown - get_physics_process_delta_time(), 0.0)
		return

	var impact := 0.0
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()
		if absf(normal.y) > 0.45:
			continue
		var collider := collision.get_collider()
		if collider == null or not (collider is StaticBody3D):
			continue
		var body := collider as StaticBody3D
		if _is_ride_surface(body):
			continue
		impact = maxf(impact, absf(speed) / max_speed)

	if impact > 0.18:
		SoundEffects.play_wall_hit(impact)
		_wall_hit_cooldown = 0.14

func _is_ride_surface(body: StaticBody3D) -> bool:
	return body.name in ["RideSurface", "Floor", "ApproachPad"]
