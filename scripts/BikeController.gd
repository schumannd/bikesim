extends CharacterBody3D

const BikeRigScript := preload("res://scripts/BikeRig.gd")

@export var acceleration: float = 18.0
@export var max_speed: float = 30.0
@export var brake_power: float = 20.0
@export var steering_speed: float = 1.6
@export var gravity: float = 18.0

var speed: float = 0.0
var reset_position: Vector3 = BikeRigScript.ride_spawn_position()

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
	rotate_y(-steer * steering_speed * delta * (abs(speed) / max_speed + 0.25))

	var forward := -global_transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	velocity.y -= gravity * delta
	move_and_slide()

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
