extends Node3D

var _wheel_spin: float = 0.0

func apply_config(config: Resource) -> void:
	_clear_parts()

	var paint_color: Color = config.get("paint_color")
	var frame_id: String = str(config.get("frame_id"))
	var wheel_id: String = str(config.get("wheel_id"))
	var handlebar_id: String = str(config.get("handlebar_id"))

	var frame_mat := _make_material(paint_color, 0.55)
	var metal_mat := _make_material(Color(0.16, 0.17, 0.18, 1.0), 0.2)
	var rubber_mat := _make_material(Color(0.05, 0.05, 0.05, 1.0), 1.0)

	var rear_wheel_z: float = -0.86
	var front_wheel_z: float = 0.86
	var frame_height: float = 0.78
	var top_tube_drop: float = 0.02
	var wheel_radius: float = 0.44
	var tire_width: float = 0.07

	match frame_id:
		"downhill":
			frame_height = 0.82
			top_tube_drop = -0.08
		"enduro":
			frame_height = 0.79
			top_tube_drop = -0.03
		_:
			frame_height = 0.76

	match wheel_id:
		"mtb_27_5":
			wheel_radius = 0.40
			tire_width = 0.075
		"mtb_plus":
			wheel_radius = 0.43
			tire_width = 0.095
		_:
			wheel_radius = 0.44
			tire_width = 0.07

	_add_tube(Vector3(0.0, frame_height + top_tube_drop, -0.38), Vector3(0.0, frame_height, 0.36), 0.045, frame_mat)
	_add_tube(Vector3(0.0, frame_height, 0.36), Vector3(0.0, wheel_radius + 0.14, front_wheel_z - 0.04), 0.04, frame_mat)
	_add_tube(Vector3(0.0, frame_height + top_tube_drop, -0.38), Vector3(0.0, wheel_radius + 0.1, rear_wheel_z + 0.08), 0.04, frame_mat)
	_add_tube(Vector3(0.0, wheel_radius + 0.1, rear_wheel_z + 0.08), Vector3(0.0, wheel_radius + 0.14, front_wheel_z - 0.04), 0.04, frame_mat)
	_add_tube(Vector3(0.0, wheel_radius + 0.12, rear_wheel_z + 0.2), Vector3(0.0, frame_height + top_tube_drop, -0.24), 0.035, frame_mat)

	_add_fork(front_wheel_z, wheel_radius, frame_mat, metal_mat)
	_add_rear_triangle(rear_wheel_z, wheel_radius, frame_mat)
	_add_drivetrain(rear_wheel_z, metal_mat)
	_add_cockpit(front_wheel_z, frame_height, handlebar_id, frame_mat, metal_mat)
	_add_wheel("RearWheel", rear_wheel_z, wheel_radius, tire_width, metal_mat, rubber_mat)
	_add_wheel("FrontWheel", front_wheel_z, wheel_radius, tire_width, metal_mat, rubber_mat)
	_add_seat(frame_height, frame_mat, metal_mat)
	_add_pedals(metal_mat)

func _add_wheel(name: String, wheel_z: float, wheel_radius: float, tire_width: float, rim_mat: Material, tire_mat: Material) -> void:
	var tire := MeshInstance3D.new()
	tire.name = "%sTire" % name
	var tire_mesh := TorusMesh.new()
	tire_mesh.outer_radius = wheel_radius
	tire_mesh.inner_radius = max(0.02, wheel_radius - tire_width)
	tire.mesh = tire_mesh
	tire.rotation = Vector3(PI * 0.5, 0, 0)
	tire.position = Vector3(0.0, wheel_radius, wheel_z)
	tire.material_override = tire_mat
	add_child(tire)

	var rim := MeshInstance3D.new()
	rim.name = "%sRim" % name
	var rim_mesh := TorusMesh.new()
	rim_mesh.outer_radius = wheel_radius - tire_width * 0.5
	rim_mesh.inner_radius = rim_mesh.outer_radius - 0.03
	rim.mesh = rim_mesh
	rim.rotation = Vector3(PI * 0.5, 0, 0)
	rim.position = Vector3(0.0, wheel_radius, wheel_z)
	rim.material_override = rim_mat
	add_child(rim)

func _add_fork(front_wheel_z: float, wheel_radius: float, frame_mat: Material, metal_mat: Material) -> void:
	_add_tube(Vector3(0.0, 0.94, front_wheel_z - 0.04), Vector3(0.0, wheel_radius + 0.15, front_wheel_z - 0.1), 0.03, frame_mat)
	_add_tube(Vector3(-0.06, wheel_radius + 0.15, front_wheel_z - 0.1), Vector3(-0.06, wheel_radius + 0.02, front_wheel_z), 0.02, metal_mat)
	_add_tube(Vector3(0.06, wheel_radius + 0.15, front_wheel_z - 0.1), Vector3(0.06, wheel_radius + 0.02, front_wheel_z), 0.02, metal_mat)

func _add_rear_triangle(rear_wheel_z: float, wheel_radius: float, frame_mat: Material) -> void:
	_add_tube(Vector3(-0.05, wheel_radius + 0.14, rear_wheel_z + 0.15), Vector3(-0.05, wheel_radius + 0.02, rear_wheel_z), 0.02, frame_mat)
	_add_tube(Vector3(0.05, wheel_radius + 0.14, rear_wheel_z + 0.15), Vector3(0.05, wheel_radius + 0.02, rear_wheel_z), 0.02, frame_mat)
	_add_tube(Vector3(0.0, 0.58, -0.12), Vector3(0.0, wheel_radius + 0.14, rear_wheel_z + 0.15), 0.025, frame_mat)

func _add_drivetrain(rear_wheel_z: float, metal_mat: Material) -> void:
	var chainring := MeshInstance3D.new()
	var ring_mesh := TorusMesh.new()
	ring_mesh.outer_radius = 0.16
	ring_mesh.inner_radius = 0.12
	chainring.mesh = ring_mesh
	chainring.rotation = Vector3(PI * 0.5, 0, 0)
	chainring.position = Vector3(0.0, 0.42, -0.03)
	chainring.material_override = metal_mat
	add_child(chainring)
	_add_tube(Vector3(0.0, 0.43, 0.05), Vector3(0.0, 0.45, rear_wheel_z + 0.04), 0.007, metal_mat)

func _add_cockpit(front_wheel_z: float, frame_height: float, handlebar_id: String, frame_mat: Material, metal_mat: Material) -> void:
	_add_tube(Vector3(0.0, frame_height + 0.02, front_wheel_z - 0.04), Vector3(0.0, frame_height + 0.22, front_wheel_z - 0.02), 0.022, metal_mat)
	var width: float = 0.7
	var rise: float = 0.0
	match handlebar_id:
		"dh_bar":
			width = 0.82
		"riser":
			width = 0.76
			rise = 0.08
		_:
			width = 0.7
	_add_tube(Vector3(-width * 0.5, frame_height + 0.22 + rise, front_wheel_z - 0.02), Vector3(width * 0.5, frame_height + 0.22 + rise, front_wheel_z - 0.02), 0.02, frame_mat)

func _add_seat(frame_height: float, frame_mat: Material, metal_mat: Material) -> void:
	_add_tube(Vector3(0.0, frame_height + 0.02, -0.4), Vector3(0.0, frame_height + 0.2, -0.44), 0.022, metal_mat)
	var seat := MeshInstance3D.new()
	var seat_mesh := BoxMesh.new()
	seat_mesh.size = Vector3(0.19, 0.05, 0.34)
	seat.mesh = seat_mesh
	seat.position = Vector3(0.0, frame_height + 0.22, -0.46)
	seat.material_override = frame_mat
	add_child(seat)

func _add_pedals(metal_mat: Material) -> void:
	var crank_right := Node3D.new()
	crank_right.name = "CrankRightPivot"
	crank_right.position = Vector3(0.0, 0.42, -0.03)
	add_child(crank_right)

	var crank_arm_right := MeshInstance3D.new()
	crank_arm_right.name = "CrankRightArm"
	var arm_mesh := BoxMesh.new()
	arm_mesh.size = Vector3(0.24, 0.022, 0.03)
	crank_arm_right.mesh = arm_mesh
	crank_arm_right.position = Vector3(0.12, 0.0, 0.0)
	crank_arm_right.material_override = metal_mat
	crank_right.add_child(crank_arm_right)

	var pedal_right := MeshInstance3D.new()
	pedal_right.name = "PedalRight"
	var pedal_mesh := BoxMesh.new()
	pedal_mesh.size = Vector3(0.09, 0.03, 0.14)
	pedal_right.mesh = pedal_mesh
	pedal_right.position = Vector3(0.24, 0.0, 0.0)
	pedal_right.material_override = metal_mat
	crank_right.add_child(pedal_right)

	var crank_left := Node3D.new()
	crank_left.name = "CrankLeftPivot"
	crank_left.position = Vector3(0.0, 0.42, -0.03)
	add_child(crank_left)

	var crank_arm_left := MeshInstance3D.new()
	crank_arm_left.name = "CrankLeftArm"
	crank_arm_left.mesh = arm_mesh
	crank_arm_left.position = Vector3(-0.12, 0.0, 0.0)
	crank_arm_left.material_override = metal_mat
	crank_left.add_child(crank_arm_left)

	var pedal_left := MeshInstance3D.new()
	pedal_left.name = "PedalLeft"
	pedal_left.mesh = pedal_mesh
	pedal_left.position = Vector3(-0.24, 0.0, 0.0)
	pedal_left.material_override = metal_mat
	crank_left.add_child(pedal_left)

func _add_tube(from_pos: Vector3, to_pos: Vector3, radius: float, mat: Material) -> void:
	var segment := MeshInstance3D.new()
	var tube_mesh := CylinderMesh.new()
	tube_mesh.top_radius = radius
	tube_mesh.bottom_radius = radius
	tube_mesh.height = from_pos.distance_to(to_pos)
	segment.mesh = tube_mesh
	segment.position = (from_pos + to_pos) * 0.5
	add_child(segment)
	segment.look_at(to_pos, Vector3.UP)
	segment.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	segment.material_override = mat

func _clear_parts() -> void:
	for child in get_children():
		child.queue_free()

func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

func animate_drive(speed: float, delta: float) -> void:
	var abs_speed: float = absf(speed)
	if abs_speed < 0.05:
		return
	var wheel_delta: float = abs_speed * delta * 2.6
	_wheel_spin += wheel_delta
	for wheel_name in ["RearWheelTire", "RearWheelRim", "FrontWheelTire", "FrontWheelRim"]:
		var wheel: Node = get_node_or_null(wheel_name)
		if wheel and wheel is Node3D:
			(wheel as Node3D).rotate_object_local(Vector3.RIGHT, wheel_delta)
	_set_pedal_phase(_wheel_spin * 1.6)

func _set_pedal_phase(phase: float) -> void:
	var right: Node = get_node_or_null("CrankRightPivot")
	var left: Node = get_node_or_null("CrankLeftPivot")
	if right and right is Node3D:
		(right as Node3D).rotation.z = phase
	if left and left is Node3D:
		(left as Node3D).rotation.z = phase + PI
