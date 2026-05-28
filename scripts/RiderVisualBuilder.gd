extends Node3D

const CAP_RADIAL := 24
const CAP_RINGS := 12
const SPH_RADIAL := 32
const SPH_RINGS := 20

var _base_rotations: Dictionary = {}

func apply_config(config: Resource) -> void:
	_clear_parts()
	var skin_tone: Color = config.get("skin_tone")
	var outfit_color: Color = config.get("outfit_color")
	var hair_style: String = str(config.get("hair_style"))

	var skin_mat := _make_material(skin_tone, 0.88)
	var cloth_mat := _make_material(outfit_color, 0.95)
	var cloth_dark := _make_material(outfit_color.darkened(0.22), 0.98)
	var dark_mat := _make_material(Color(0.07, 0.07, 0.08, 1.0), 0.85)
	var accent := _make_material(outfit_color.lightened(0.35), 0.9)
	var hair_mat := _make_material(Color(0.18, 0.09, 0.04, 1.0), 0.92)

	_build_core_body(skin_mat, cloth_mat, cloth_dark, accent, dark_mat)
	_build_arms(skin_mat, cloth_mat, cloth_dark, dark_mat)
	_build_legs(cloth_mat, cloth_dark, skin_mat, dark_mat)
	_build_head_and_hair(hair_style, skin_mat, dark_mat, hair_mat)
	_cache_base_rotations()

func _build_core_body(skin_mat: Material, cloth_mat: Material, cloth_dark: Material, accent: Material, dark_mat: Material) -> void:
	_add_capsule("Hips", Vector3(0.0, 0.73, 0.04), 0.19, 0.24, cloth_dark)
	_add_capsule("HipsAccent", Vector3(0.0, 0.76, 0.02), 0.17, 0.14, cloth_mat)
	_add_box("Belt", Vector3(0.0, 0.82, 0.02), Vector3(0.34, 0.05, 0.2), dark_mat)

	_add_capsule("TorsoLower", Vector3(0.0, 0.9, 0.06), 0.17, 0.22, cloth_mat)
	_add_capsule("TorsoUpper", Vector3(0.0, 1.02, 0.1), 0.2, 0.28, cloth_mat)
	_add_box("ChestPlate", Vector3(0.0, 1.04, 0.14), Vector3(0.32, 0.22, 0.14), cloth_dark)
	_add_box("JerseyStripe", Vector3(0.0, 0.98, 0.2), Vector3(0.28, 0.06, 0.03), accent)
	_add_sphere("ChestL", Vector3(-0.1, 1.02, 0.16), 0.07, cloth_dark)
	_add_sphere("ChestR", Vector3(0.1, 1.02, 0.16), 0.07, cloth_dark)

	_add_capsule("Neck", Vector3(0.0, 1.14, 0.12), 0.055, 0.1, skin_mat)
	_add_sphere("ShoulderL", Vector3(-0.2, 1.06, 0.1), 0.09, cloth_mat)
	_add_sphere("ShoulderR", Vector3(0.2, 1.06, 0.1), 0.09, cloth_mat)

func _build_arms(skin_mat: Material, cloth_mat: Material, cloth_dark: Material, dark_mat: Material) -> void:
	var upper_l := _add_pivot("UpperArmL", Vector3(-0.2, 1.0, 0.3), Vector3(0.35, 0.0, 0.55))
	_add_capsule_to(upper_l, "UpperArmLMesh1", Vector3(-0.04, 0.0, 0.06), 0.075, 0.14, cloth_mat)
	_add_capsule_to(upper_l, "UpperArmLMesh2", Vector3(-0.02, -0.02, 0.14), 0.065, 0.16, cloth_dark)
	_add_sphere_to(upper_l, "UpperArmLJoint", Vector3(0.0, -0.02, 0.22), 0.07, cloth_mat)

	var fore_l := _add_pivot("ForearmL", Vector3(-0.05, -0.04, 0.24), Vector3(0.75, 0.0, 0.35), upper_l)
	_add_capsule_to(fore_l, "ForearmLMesh1", Vector3(0.0, 0.0, 0.05), 0.055, 0.12, skin_mat)
	_add_capsule_to(fore_l, "ForearmLMesh2", Vector3(0.0, -0.01, 0.14), 0.05, 0.14, skin_mat)
	_add_box_to(fore_l, "GloveL", Vector3(0.0, -0.01, 0.24), Vector3(0.08, 0.05, 0.1), dark_mat)
	_add_hand_detail(fore_l, Vector3(0.0, -0.01, 0.3), skin_mat, -1.0)

	var upper_r := _add_pivot("UpperArmR", Vector3(0.2, 1.0, 0.3), Vector3(0.35, 0.0, -0.55))
	_add_capsule_to(upper_r, "UpperArmRMesh1", Vector3(0.04, 0.0, 0.06), 0.075, 0.14, cloth_mat)
	_add_capsule_to(upper_r, "UpperArmRMesh2", Vector3(0.02, -0.02, 0.14), 0.065, 0.16, cloth_dark)
	_add_sphere_to(upper_r, "UpperArmRJoint", Vector3(0.0, -0.02, 0.22), 0.07, cloth_mat)

	var fore_r := _add_pivot("ForearmR", Vector3(0.05, -0.04, 0.24), Vector3(0.75, 0.0, -0.35), upper_r)
	_add_capsule_to(fore_r, "ForearmRMesh1", Vector3(0.0, 0.0, 0.05), 0.055, 0.12, skin_mat)
	_add_capsule_to(fore_r, "ForearmRMesh2", Vector3(0.0, -0.01, 0.14), 0.05, 0.14, skin_mat)
	_add_box_to(fore_r, "GloveR", Vector3(0.0, -0.01, 0.24), Vector3(0.08, 0.05, 0.1), dark_mat)
	_add_hand_detail(fore_r, Vector3(0.0, -0.01, 0.3), skin_mat, 1.0)

func _build_legs(cloth_mat: Material, cloth_dark: Material, skin_mat: Material, dark_mat: Material) -> void:
	var thigh_l := _add_pivot("ThighL", Vector3(-0.11, 0.62, 0.14), Vector3(1.05, 0.0, 0.18))
	_add_capsule_to(thigh_l, "ThighLMesh1", Vector3(0.0, -0.04, 0.02), 0.095, 0.18, cloth_mat)
	_add_capsule_to(thigh_l, "ThighLMesh2", Vector3(0.02, -0.1, -0.02), 0.08, 0.16, cloth_dark)
	_add_sphere_to(thigh_l, "ThighLMuscle", Vector3(-0.03, -0.06, 0.04), 0.07, cloth_mat)

	var calf_l := _add_pivot("CalfL", Vector3(0.0, -0.2, -0.04), Vector3(0.36, 0.0, 0.05), thigh_l)
	_add_capsule_to(calf_l, "CalfLMesh", Vector3(0.0, -0.1, 0.0), 0.07, 0.22, cloth_dark)
	_add_sphere_to(calf_l, "CalfLMuscle", Vector3(0.03, -0.08, 0.02), 0.06, cloth_mat)
	_add_sphere_to(calf_l, "KneeL", Vector3(0.0, 0.02, 0.03), 0.075, dark_mat)
	_add_shoe(calf_l, Vector3(0.0, -0.24, 0.02), dark_mat, skin_mat)

	var thigh_r := _add_pivot("ThighR", Vector3(0.11, 0.62, 0.14), Vector3(1.05, 0.0, -0.18))
	_add_capsule_to(thigh_r, "ThighRMesh1", Vector3(0.0, -0.04, 0.02), 0.095, 0.18, cloth_mat)
	_add_capsule_to(thigh_r, "ThighRMesh2", Vector3(-0.02, -0.1, -0.02), 0.08, 0.16, cloth_dark)
	_add_sphere_to(thigh_r, "ThighRMuscle", Vector3(0.03, -0.06, 0.04), 0.07, cloth_mat)

	var calf_r := _add_pivot("CalfR", Vector3(0.0, -0.2, -0.04), Vector3(0.36, 0.0, -0.05), thigh_r)
	_add_capsule_to(calf_r, "CalfRMesh", Vector3(0.0, -0.1, 0.0), 0.07, 0.22, cloth_dark)
	_add_sphere_to(calf_r, "CalfRMuscle", Vector3(-0.03, -0.08, 0.02), 0.06, cloth_mat)
	_add_sphere_to(calf_r, "KneeR", Vector3(0.0, 0.02, 0.03), 0.075, dark_mat)
	_add_shoe(calf_r, Vector3(0.0, -0.24, 0.02), dark_mat, skin_mat)

func _build_head_and_hair(hair_style: String, skin_mat: Material, dark_mat: Material, hair_mat: Material) -> void:
	_add_sphere("Head", Vector3(0.0, 1.24, 0.14), 0.145, skin_mat)
	_add_sphere("SkullBack", Vector3(0.0, 1.28, 0.04), 0.12, skin_mat)
	_add_box("Jaw", Vector3(0.0, 1.18, 0.2), Vector3(0.14, 0.08, 0.12), skin_mat)
	_add_sphere("EarL", Vector3(-0.14, 1.24, 0.12), 0.035, skin_mat)
	_add_sphere("EarR", Vector3(0.14, 1.24, 0.12), 0.035, skin_mat)
	_add_box("Nose", Vector3(0.0, 1.21, 0.26), Vector3(0.03, 0.04, 0.03), skin_mat)

	match hair_style:
		"helmet":
			_add_sphere("HelmetShell", Vector3(0.0, 1.3, 0.14), 0.175, dark_mat)
			_add_box("HelmetVisor", Vector3(0.0, 1.26, 0.28), Vector3(0.2, 0.05, 0.12), _make_material(Color(0.2, 0.22, 0.25, 0.7), 0.2))
			_add_box("HelmetPeak", Vector3(0.0, 1.34, 0.2), Vector3(0.22, 0.04, 0.16), dark_mat)
		"long":
			_add_sphere("HairTop", Vector3(0.0, 1.34, 0.1), 0.14, hair_mat)
			_add_capsule("HairBack", Vector3(0.0, 1.1, -0.02), 0.11, 0.28, hair_mat)
			_add_box("HairSideL", Vector3(-0.12, 1.16, 0.08), Vector3(0.05, 0.2, 0.1), hair_mat)
			_add_box("HairSideR", Vector3(0.12, 1.16, 0.08), Vector3(0.05, 0.2, 0.1), hair_mat)
		_:
			_add_sphere("HairTop", Vector3(0.0, 1.35, 0.13), 0.13, hair_mat)
			_add_box("HairFront", Vector3(0.0, 1.32, 0.22), Vector3(0.16, 0.05, 0.08), hair_mat)
			_add_box("HairSideL", Vector3(-0.12, 1.3, 0.12), Vector3(0.04, 0.08, 0.1), hair_mat)
			_add_box("HairSideR", Vector3(0.12, 1.3, 0.12), Vector3(0.04, 0.08, 0.1), hair_mat)

func _add_hand_detail(parent: Node3D, pos: Vector3, skin_mat: Material, side_sign: float) -> void:
	_add_box_to(parent, "Palm", pos, Vector3(0.06, 0.03, 0.07), skin_mat)
	for i in range(4):
		_add_capsule_to(
			parent,
			"Finger%d" % i,
			pos + Vector3(side_sign * 0.025, -0.01, 0.05 + i * 0.018),
			0.011,
			0.05,
			skin_mat
		)

func _add_shoe(parent: Node3D, pos: Vector3, dark_mat: Material, skin_mat: Material) -> void:
	var side := -1.0 if parent.name.ends_with("L") else 1.0
	_add_box_to(parent, "FootUpper", pos + Vector3(0.0, 0.0, 0.02), Vector3(0.1, 0.07, 0.2), dark_mat)
	_add_box_to(parent, "FootSole", pos + Vector3(0.0, -0.04, -0.02), Vector3(0.11, 0.04, 0.24), dark_mat)
	_add_box_to(parent, "Heel", pos + Vector3(side * 0.02, -0.02, -0.1), Vector3(0.06, 0.05, 0.06), dark_mat)
	_add_sphere_to(parent, "Ankle", pos + Vector3(0.0, 0.02, 0.0), 0.045, skin_mat)

func _add_pivot(name: String, pos: Vector3, rot: Vector3 = Vector3.ZERO, parent: Node = null) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = name
	pivot.position = pos
	pivot.rotation = rot
	if parent:
		parent.add_child(pivot)
	else:
		add_child(pivot)
	return pivot

func _add_capsule(name: String, pos: Vector3, radius: float, height: float, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = CAP_RADIAL
	mesh.rings = CAP_RINGS
	node.mesh = mesh
	node.position = pos
	node.rotation = rot
	node.material_override = mat
	add_child(node)
	return node

func _add_capsule_to(parent: Node3D, name: String, pos: Vector3, radius: float, height: float, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = CAP_RADIAL
	mesh.rings = CAP_RINGS
	node.mesh = mesh
	node.position = pos
	node.rotation = rot
	node.material_override = mat
	parent.add_child(node)

func _add_sphere(name: String, pos: Vector3, radius: float, mat: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = SPH_RADIAL
	mesh.rings = SPH_RINGS
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	add_child(node)

func _add_sphere_to(parent: Node3D, name: String, pos: Vector3, radius: float, mat: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = SPH_RADIAL
	mesh.rings = SPH_RINGS
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)

func _add_box(name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	add_child(node)

func _add_box_to(parent: Node3D, name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)

func _clear_parts() -> void:
	for child in get_children():
		child.queue_free()

func _make_material(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = 0.02
	return mat

func animate_pedaling(phase: float, intensity: float) -> void:
	var pedal: float = clampf(intensity, 0.0, 1.0)
	_set_node_rot_x("ThighL", sin(phase) * 0.7 * pedal)
	_set_node_rot_x("ThighR", sin(phase + PI) * 0.7 * pedal)
	_set_node_rot_x("CalfL", sin(phase + PI * 0.35) * 0.45 * pedal)
	_set_node_rot_x("CalfR", sin(phase + PI * 1.35) * 0.45 * pedal)
	_set_node_rot_x("UpperArmL", sin(phase + PI) * 0.18 * pedal)
	_set_node_rot_x("UpperArmR", sin(phase) * 0.18 * pedal)
	_set_node_rot_x("ForearmL", sin(phase + PI) * 0.12 * pedal)
	_set_node_rot_x("ForearmR", sin(phase) * 0.12 * pedal)

func animate_walk(phase: float, intensity: float) -> void:
	var stride: float = clampf(intensity, 0.0, 1.0)
	_set_node_rot_x("ThighL", sin(phase) * 0.55 * stride)
	_set_node_rot_x("ThighR", sin(phase + PI) * 0.55 * stride)
	_set_node_rot_x("CalfL", maxf(0.0, sin(phase + PI * 0.5)) * 0.35 * stride)
	_set_node_rot_x("CalfR", maxf(0.0, sin(phase + PI * 1.5)) * 0.35 * stride)
	_set_node_rot_x("UpperArmL", sin(phase + PI) * 0.42 * stride)
	_set_node_rot_x("UpperArmR", sin(phase) * 0.42 * stride)
	_set_node_rot_x("ForearmL", 0.18 * stride)
	_set_node_rot_x("ForearmR", 0.18 * stride)

func animate_idle(phase: float) -> void:
	var sway: float = sin(phase * 1.2) * 0.04
	_set_node_rot_x("UpperArmL", sway)
	_set_node_rot_x("UpperArmR", -sway)
	_set_node_rot_x("ForearmL", sway * 0.5)
	_set_node_rot_x("ForearmR", -sway * 0.5)
	_set_node_rot_x("ThighL", sin(phase * 0.8) * 0.02)
	_set_node_rot_x("ThighR", sin(phase * 0.8 + PI) * 0.02)

func _cache_base_rotations() -> void:
	_base_rotations.clear()
	_store_pivot_rotations(self)

func _store_pivot_rotations(node: Node) -> void:
	for child in node.get_children():
		if child is Node3D and _is_animated_pivot(child.name):
			_base_rotations[child.name] = (child as Node3D).rotation
		_store_pivot_rotations(child)

func _is_animated_pivot(node_name: String) -> bool:
	return node_name in ["ThighL", "ThighR", "CalfL", "CalfR", "UpperArmL", "UpperArmR", "ForearmL", "ForearmR"]

func _set_node_rot_x(node_name: String, offset_x: float) -> void:
	var node := find_child(node_name, true, false)
	if node == null or not (node is Node3D):
		return
	var n := node as Node3D
	var base: Vector3 = _base_rotations.get(node_name, n.rotation)
	n.rotation = Vector3(base.x + offset_x, base.y, base.z)
