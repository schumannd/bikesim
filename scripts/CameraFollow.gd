extends Camera3D

@export var target_path: NodePath
@export var follow_distance: float = 3.8
@export var follow_height: float = 2.0
@export var look_at_height: float = 1.15
@export var smoothing: float = 6.0

@onready var target: Node3D = get_node_or_null(target_path)

func _physics_process(delta: float) -> void:
	if target == null:
		return
	var desired := target.global_position + (target.global_basis.z * follow_distance) + Vector3.UP * follow_height
	global_position = global_position.lerp(desired, clamp(smoothing * delta, 0.0, 1.0))
	look_at(target.global_position + Vector3.UP * look_at_height, Vector3.UP)
