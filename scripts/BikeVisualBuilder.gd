extends Node3D

const BikeRigScript := preload("res://scripts/BikeRig.gd")

const CYL_RADIAL := 20
const CYL_RINGS := 8
var _wheel_spin: float = 0.0
var _wheel_radius: float = 0.44

func get_wheel_radius() -> float:
	return _wheel_radius

func apply_config(config: Resource) -> void:
	_clear_parts()

	var paint_color: Color = config.get("paint_color")
	var frame_id: String = str(config.get("frame_id"))
	var wheel_id: String = str(config.get("wheel_id"))
	var fork_id: String = str(config.get("fork_id"))
	if fork_id.is_empty():
		fork_id = "trail_susp"
	var handlebar_id: String = str(config.get("handlebar_id"))
	var seat_id: String = str(config.get("seat_id"))
	if seat_id.is_empty():
		seat_id = "trail"
	var pedal_id: String = str(config.get("pedal_id"))
	if pedal_id.is_empty():
		pedal_id = "platform"

	var frame_mat := _make_material(paint_color, 0.52)
	var frame_accent := _make_material(paint_color.lightened(0.25), 0.45)
	var metal_mat := _make_material(Color(0.16, 0.17, 0.18, 1.0), 0.18)
	var metal_shine := _make_material(Color(0.32, 0.34, 0.36, 1.0), 0.12)
	var rubber_mat := _make_material(Color(0.04, 0.04, 0.04, 1.0), 0.98)
	var rubber_side := _make_material(Color(0.08, 0.08, 0.08, 1.0), 0.95)

	var rear_wheel_z: float = -0.86
	var front_wheel_z: float = 0.86
	var frame_height: float = 0.76
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
		"xc":
			frame_height = 0.74
			top_tube_drop = 0.06

	match wheel_id:
		"mtb_27_5":
			wheel_radius = 0.40
			tire_width = 0.075
		"mtb_plus":
			wheel_radius = 0.43
			tire_width = 0.095
		"gravel_700":
			wheel_radius = 0.36
			tire_width = 0.04
		_:
			wheel_radius = 0.44
			tire_width = 0.07
	_wheel_radius = wheel_radius

	_add_frame(frame_height, top_tube_drop, front_wheel_z, rear_wheel_z, wheel_radius, frame_mat, frame_accent, metal_mat)
	_add_fork(front_wheel_z, wheel_radius, fork_id, frame_mat, metal_mat, metal_shine)
	_add_rear_triangle(rear_wheel_z, wheel_radius, frame_mat, metal_mat)
	_add_drivetrain(rear_wheel_z, wheel_radius, metal_mat, metal_shine)
	_add_cockpit(front_wheel_z, frame_height, handlebar_id, frame_mat, frame_accent, metal_mat, metal_shine, rubber_mat)
	_add_wheel("Rear", rear_wheel_z, wheel_radius, tire_width, metal_shine, metal_mat, rubber_mat, rubber_side)
	_add_wheel("Front", front_wheel_z, wheel_radius, tire_width, metal_shine, metal_mat, rubber_mat, rubber_side)
	_add_seat(frame_height, seat_id, frame_mat, frame_accent, metal_mat)
	_add_pedals(pedal_id, metal_mat, metal_shine)
	_add_seat_anchor(frame_height)

func mount_rider(rider: Node3D) -> void:
	var bike := get_parent()
	if bike:
		BikeRigScript.mount_rider_on_bike(bike, self, rider)

func _add_frame(frame_height: float, top_tube_drop: float, front_z: float, rear_z: float, wheel_r: float, frame_mat: Material, accent: Material, metal: Material) -> void:
	_add_tube(Vector3(0.0, frame_height + top_tube_drop, -0.38), Vector3(0.0, frame_height, 0.36), 0.048, frame_mat)
	_add_tube(Vector3(0.0, frame_height + top_tube_drop, -0.38), Vector3(0.0, frame_height + top_tube_drop, -0.18), 0.038, accent)
	_add_tube(Vector3(0.0, frame_height, 0.36), Vector3(0.0, wheel_r + 0.14, front_z - 0.04), 0.042, frame_mat)
	_add_tube(Vector3(0.0, frame_height + top_tube_drop, -0.38), Vector3(0.0, wheel_r + 0.1, rear_z + 0.08), 0.042, frame_mat)
	_add_tube(Vector3(0.0, wheel_r + 0.1, rear_z + 0.08), Vector3(0.0, wheel_r + 0.14, front_z - 0.04), 0.04, frame_mat)
	_add_tube(Vector3(0.0, wheel_r + 0.12, rear_z + 0.2), Vector3(0.0, frame_height + top_tube_drop, -0.24), 0.036, frame_mat)
	_add_cylinder_mesh("HeadTube", Vector3(0.0, frame_height + 0.08, front_z - 0.06), Vector3(0.055, 0.14, 0.055), metal)
	_add_sphere_mesh("BottomBracket", Vector3(0.0, 0.42, -0.03), 0.06, metal)
	_add_box_mesh("DropoutL", Vector3(-0.06, wheel_r + 0.02, rear_z), Vector3(0.02, 0.08, 0.06), metal)
	_add_box_mesh("DropoutR", Vector3(0.06, wheel_r + 0.02, rear_z), Vector3(0.02, 0.08, 0.06), metal)
	_add_tube(Vector3(0.04, frame_height + 0.1, 0.0), Vector3(0.04, 0.5, -0.1), 0.006, metal)
	_add_tube(Vector3(-0.04, frame_height + 0.1, 0.0), Vector3(-0.04, 0.5, -0.1), 0.006, metal)

func _add_fork(front_z: float, wheel_r: float, fork_id: String, frame_mat: Material, metal: Material, shine: Material) -> void:
	var crown_y: float = 0.94
	var leg_spread: float = 0.065
	match fork_id:
		"dh_susp":
			crown_y = 0.98
			leg_spread = 0.085
			_add_tube(Vector3(0.0, crown_y - 0.08, front_z - 0.02), Vector3(0.0, wheel_r + 0.22, front_z - 0.12), 0.048, metal)
			_add_cylinder_mesh("ForkBrace", Vector3(0.0, wheel_r + 0.16, front_z - 0.06), Vector3(0.12, 0.03, 0.03), shine)
		"trail_susp":
			_add_tube(Vector3(0.0, crown_y - 0.05, front_z - 0.03), Vector3(0.0, wheel_r + 0.18, front_z - 0.1), 0.038, metal)
		"rigid_carbon":
			crown_y = 0.9
		_:
			pass

	_add_tube(Vector3(0.0, crown_y, front_z - 0.04), Vector3(0.0, wheel_r + 0.15, front_z - 0.1), 0.032, frame_mat)
	_add_tube(Vector3(-leg_spread, wheel_r + 0.15, front_z - 0.1), Vector3(-leg_spread, wheel_r + 0.02, front_z), 0.022, metal)
	_add_tube(Vector3(leg_spread, wheel_r + 0.15, front_z - 0.1), Vector3(leg_spread, wheel_r + 0.02, front_z), 0.022, metal)
	_add_tube(Vector3(-leg_spread, wheel_r + 0.08, front_z - 0.04), Vector3(leg_spread, wheel_r + 0.08, front_z - 0.04), 0.018, shine)
	_add_cylinder_mesh("FrontHub", Vector3(0.0, wheel_r, front_z), Vector3(0.04, 0.1, 0.04), shine)

func _add_rear_triangle(rear_z: float, wheel_r: float, frame_mat: Material, metal: Material) -> void:
	_add_tube(Vector3(-0.05, wheel_r + 0.14, rear_z + 0.15), Vector3(-0.05, wheel_r + 0.02, rear_z), 0.022, frame_mat)
	_add_tube(Vector3(0.05, wheel_r + 0.14, rear_z + 0.15), Vector3(0.05, wheel_r + 0.02, rear_z), 0.022, frame_mat)
	_add_tube(Vector3(0.0, 0.58, -0.12), Vector3(0.0, wheel_r + 0.14, rear_z + 0.15), 0.028, frame_mat)
	_add_cylinder_mesh("SeatStayBridge", Vector3(0.0, wheel_r + 0.2, rear_z + 0.08), Vector3(0.08, 0.02, 0.02), metal)

func _add_drivetrain(rear_z: float, wheel_radius: float, metal: Material, shine: Material) -> void:
	_add_torus_mesh("ChainringOuter", Vector3(0.0, 0.42, -0.03), 0.17, 0.13, metal, Vector3(PI * 0.5, 0, 0))
	_add_torus_mesh("ChainringInner", Vector3(0.0, 0.42, -0.028), 0.13, 0.1, shine, Vector3(PI * 0.5, 0, 0))
	for i in range(8):
		var a := float(i) / 8.0 * TAU
		_add_box_mesh(
			"ChainringTooth%d" % i,
			Vector3(cos(a) * 0.15, 0.42, -0.03 + sin(a) * 0.15),
			Vector3(0.018, 0.012, 0.024),
			shine
		)
	var hub_y: float = wheel_radius
	_add_cylinder_mesh("CassetteBody", Vector3(0.0, hub_y, rear_z + 0.02), Vector3(0.09, 0.06, 0.09), metal)
	for i in range(5):
		_add_torus_mesh(
			"CassetteRing%d" % i,
			Vector3(0.0, hub_y, rear_z + 0.02),
			0.08 - i * 0.008,
			0.07 - i * 0.008,
			shine,
			Vector3(PI * 0.5, 0, 0)
		)
	_add_tube(Vector3(0.0, 0.43, 0.05), Vector3(0.0, hub_y, rear_z + 0.04), 0.006, metal)
	_add_tube(Vector3(0.0, 0.43, 0.05), Vector3(0.05, 0.4, 0.0), 0.005, metal)
	_add_box_mesh("Derailleur", Vector3(0.06, hub_y - 0.02, rear_z + 0.06), Vector3(0.04, 0.08, 0.05), shine)

func _add_cockpit(front_z: float, frame_height: float, handlebar_id: String, frame_mat: Material, accent: Material, metal: Material, shine: Material, rubber: Material) -> void:
	_add_tube(Vector3(0.0, frame_height + 0.02, front_z - 0.04), Vector3(0.0, frame_height + 0.22, front_z - 0.02), 0.024, metal)
	_add_cylinder_mesh("Stem", Vector3(0.0, frame_height + 0.2, front_z - 0.03), Vector3(0.03, 0.1, 0.03), metal)

	var width: float = 0.7
	var rise: float = 0.0
	match handlebar_id:
		"dh_bar":
			width = 0.82
			rise = 0.12
		"riser":
			width = 0.76
			rise = 0.08
		"bmx":
			width = 0.62
			rise = 0.02
		_:
			width = 0.7

	var bar_y: float = frame_height + 0.22 + rise
	var bar_z: float = front_z - 0.02
	_add_tube(Vector3(-width * 0.5, bar_y, bar_z), Vector3(width * 0.5, bar_y, bar_z), 0.024, frame_mat)
	_add_tube(Vector3(-width * 0.5, bar_y, bar_z), Vector3(-width * 0.5, bar_y - 0.04, bar_z + 0.04), 0.02, accent)
	_add_tube(Vector3(width * 0.5, bar_y, bar_z), Vector3(width * 0.5, bar_y - 0.04, bar_z + 0.04), 0.02, accent)
	_add_cylinder_mesh("GripL", Vector3(-width * 0.5 - 0.03, bar_y, bar_z), Vector3(0.02, 0.1, 0.02), rubber)
	_add_cylinder_mesh("GripR", Vector3(width * 0.5 + 0.03, bar_y, bar_z), Vector3(0.02, 0.1, 0.02), rubber)
	_add_box_mesh("BrakeLeverL", Vector3(-width * 0.35, bar_y + 0.02, bar_z + 0.05), Vector3(0.05, 0.02, 0.06), shine)
	_add_box_mesh("BrakeLeverR", Vector3(width * 0.35, bar_y + 0.02, bar_z + 0.05), Vector3(0.05, 0.02, 0.06), shine)

func _add_wheel(prefix: String, wheel_z: float, wheel_radius: float, tire_width: float, rim_mat: Material, hub_mat: Material, tire_mat: Material, tire_side_mat: Material) -> void:
	var spin := Node3D.new()
	spin.name = "%sWheelSpin" % prefix
	spin.position = Vector3(0.0, wheel_radius, wheel_z)
	add_child(spin)

	var outer_r: float = wheel_radius
	var inner_tire_r: float = max(0.02, wheel_radius - tire_width)

	_add_torus_to(spin, "%sTire" % prefix, Vector3.ZERO, outer_r, inner_tire_r, tire_mat, Vector3(0, 0, PI * 0.5))
	_add_torus_to(spin, "%sTireStripe" % prefix, Vector3.ZERO, outer_r - tire_width * 0.15, outer_r - tire_width * 0.35, tire_side_mat, Vector3(0, 0, PI * 0.5))

	var rim_r: float = wheel_radius - tire_width * 0.55
	_add_torus_to(spin, "%sRim" % prefix, Vector3.ZERO, rim_r, rim_r - 0.035, rim_mat, Vector3(0, 0, PI * 0.5))
	_add_torus_to(spin, "%sRimInner" % prefix, Vector3.ZERO, rim_r - 0.04, rim_r - 0.07, hub_mat, Vector3(0, 0, PI * 0.5))

	_add_cylinder_to(spin, "%sHub" % prefix, Vector3.ZERO, Vector3(0.05, 0.12, 0.05), hub_mat, Vector3(0, 0, PI * 0.5))
	_add_cylinder_to(spin, "%sAxle" % prefix, Vector3.ZERO, Vector3(0.015, 0.14, 0.015), hub_mat, Vector3(0, 0, PI * 0.5))

	var spoke_count := 16
	for i in range(spoke_count):
		var angle := float(i) / float(spoke_count) * TAU
		var x := cos(angle) * rim_r * 0.85
		var y := sin(angle) * rim_r * 0.85
		_add_tube_to(spin, Vector3(x * 0.15, y * 0.15, 0.0), Vector3(x, y, 0.0), 0.004, hub_mat)

	_add_torus_to(spin, "%sRotor" % prefix, Vector3(0.0, 0.0, 0.02), 0.12, 0.08, hub_mat, Vector3(PI * 0.5, 0, 0))
	for i in range(6):
		var a := float(i) / 6.0 * TAU
		_add_box_to(spin, "RotorHole%d" % i, Vector3(cos(a) * 0.1, sin(a) * 0.1, 0.02), Vector3(0.02, 0.01, 0.01), hub_mat)

	var knob_count := 14
	for i in range(knob_count):
		var a := float(i) / float(knob_count) * TAU
		var kx := cos(a) * outer_r
		var ky := sin(a) * outer_r
		_add_box_to(spin, "Knob%d" % i, Vector3(kx, ky, 0.0), Vector3(0.025, 0.015, tire_width * 0.9), tire_mat)

func _add_seat(frame_height: float, seat_id: String, frame_mat: Material, accent: Material, metal: Material) -> void:
	_add_tube(Vector3(0.0, frame_height + 0.02, -0.4), Vector3(0.0, frame_height + 0.2, -0.44), 0.024, metal)
	_add_tube(Vector3(-0.05, frame_height + 0.2, -0.44), Vector3(0.05, frame_height + 0.2, -0.44), 0.008, metal)

	var seat_size := Vector3(0.19, 0.05, 0.34)
	match seat_id:
		"dh":
			seat_size = Vector3(0.22, 0.06, 0.28)
		"comfort":
			seat_size = Vector3(0.24, 0.07, 0.38)
		"slim":
			seat_size = Vector3(0.16, 0.04, 0.3)

	var seat_pos := Vector3(0.0, frame_height + 0.22, -0.46)
	_add_box_mesh("SeatBase", seat_pos, seat_size, frame_mat)
	_add_box_mesh("SeatPadding", seat_pos + Vector3(0.0, seat_size.y * 0.35, 0.0), seat_size * Vector3(0.92, 0.5, 0.92), accent)
	_add_box_mesh("SeatNose", seat_pos + Vector3(0.0, 0.0, -seat_size.z * 0.35), Vector3(seat_size.x * 0.5, seat_size.y * 0.7, seat_size.z * 0.3), frame_mat)

func _add_pedals(pedal_id: String, metal: Material, shine: Material) -> void:
	var pedal_size := Vector3(0.09, 0.03, 0.14)
	match pedal_id:
		"clipless":
			pedal_size = Vector3(0.08, 0.04, 0.12)
		"dh":
			pedal_size = Vector3(0.11, 0.04, 0.16)

	for side_sign in [-1.0, 1.0]:
		var suffix := "R" if side_sign > 0.0 else "L"
		var pivot := Node3D.new()
		pivot.name = "Crank%sPivot" % suffix
		pivot.position = Vector3(0.0, 0.42, -0.03)
		add_child(pivot)

		_add_cylinder_to(pivot, "Crank%sShaft" % suffix, Vector3(0.0, 0.0, 0.0), Vector3(0.02, 0.06, 0.02), metal, Vector3(PI * 0.5, 0, 0))
		_add_box_to(pivot, "Crank%sArm" % suffix, Vector3(0.12 * side_sign, 0.0, 0.0), Vector3(0.24, 0.024, 0.032), metal)
		_add_box_to(pivot, "Pedal%sBody" % suffix, Vector3(0.24 * side_sign, 0.0, 0.0), pedal_size, shine)
		_add_box_to(pivot, "Pedal%sAxle" % suffix, Vector3(0.24 * side_sign, -0.02, 0.0), Vector3(0.03, 0.03, 0.03), metal)
		for i in range(6):
			_add_box_to(
				pivot,
				"Pedal%sPin%d" % [suffix, i],
				Vector3(0.24 * side_sign, -0.015, -0.05 + i * 0.02),
				Vector3(0.06, 0.008, 0.008),
				shine
			)

func _add_seat_anchor(frame_height: float) -> void:
	var anchor := Node3D.new()
	anchor.name = "SeatAnchor"
	anchor.position = Vector3(0.0, frame_height + 0.22, -0.46)
	add_child(anchor)

func _add_tube(from_pos: Vector3, to_pos: Vector3, radius: float, mat: Material) -> void:
	_add_tube_to(self, from_pos, to_pos, radius, mat)

func _add_tube_to(parent: Node, from_pos: Vector3, to_pos: Vector3, radius: float, mat: Material) -> void:
	var segment := MeshInstance3D.new()
	var tube_mesh := CylinderMesh.new()
	tube_mesh.top_radius = radius
	tube_mesh.bottom_radius = radius
	tube_mesh.radial_segments = CYL_RADIAL
	tube_mesh.rings = CYL_RINGS
	tube_mesh.height = from_pos.distance_to(to_pos)
	segment.mesh = tube_mesh
	segment.position = (from_pos + to_pos) * 0.5
	parent.add_child(segment)
	segment.look_at(to_pos, Vector3.UP)
	segment.rotate_object_local(Vector3.RIGHT, PI * 0.5)
	segment.material_override = mat

func _add_torus_mesh(name: String, pos: Vector3, outer_r: float, inner_r: float, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	_add_torus_to(self, name, pos, outer_r, inner_r, mat, rot)

func _add_torus_to(parent: Node, name: String, pos: Vector3, outer_r: float, inner_r: float, mat: Material, rot: Vector3) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := TorusMesh.new()
	mesh.outer_radius = outer_r
	mesh.inner_radius = inner_r
	node.mesh = mesh
	node.position = pos
	node.rotation = rot
	node.material_override = mat
	parent.add_child(node)

func _add_cylinder_mesh(name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	_add_cylinder_to(self, name, pos, size, mat)

func _add_cylinder_to(parent: Node, name: String, pos: Vector3, size: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := CylinderMesh.new()
	mesh.top_radius = size.x
	mesh.bottom_radius = size.x
	mesh.height = size.y
	mesh.radial_segments = CYL_RADIAL
	mesh.rings = CYL_RINGS
	node.mesh = mesh
	node.position = pos
	node.rotation = rot
	node.material_override = mat
	parent.add_child(node)

func _add_box_mesh(name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	_add_box_to(self, name, pos, size, mat)

func _add_box_to(parent: Node, name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)

func _add_sphere_mesh(name: String, pos: Vector3, radius: float, mat: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = CYL_RADIAL
	mesh.rings = CYL_RINGS
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	add_child(node)

func _clear_parts() -> void:
	for child in get_children():
		child.queue_free()

func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.15 if roughness < 0.3 else 0.05
	return mat

func animate_drive(speed: float, delta: float) -> void:
	var abs_speed: float = absf(speed)
	if abs_speed < 0.05:
		return
	var wheel_delta: float = abs_speed * delta * 2.6
	_wheel_spin += wheel_delta
	for pivot_name in ["RearWheelSpin", "FrontWheelSpin"]:
		var pivot: Node = get_node_or_null(pivot_name)
		if pivot and pivot is Node3D:
			(pivot as Node3D).rotate_object_local(Vector3.RIGHT, wheel_delta)
	_set_pedal_phase(_wheel_spin * 1.6)

func _set_pedal_phase(phase: float) -> void:
	var right: Node = get_node_or_null("CrankRPivot")
	var left: Node = get_node_or_null("CrankLPivot")
	if right and right is Node3D:
		(right as Node3D).rotation.z = phase
	if left and left is Node3D:
		(left as Node3D).rotation.z = phase + PI
