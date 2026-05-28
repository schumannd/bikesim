extends Node3D

func apply_config(config: Resource) -> void:
	_clear_parts()
	var skin_tone: Color = config.get("skin_tone")
	var outfit_color: Color = config.get("outfit_color")
	var hair_style: String = str(config.get("hair_style"))

	var skin_mat := _make_material(skin_tone, 0.9)
	var cloth_mat := _make_material(outfit_color, 0.98)
	var dark_mat := _make_material(Color(0.08, 0.08, 0.08, 1.0), 0.9)

	_add_capsule("Torso", Vector3(0.0, 1.26, 0.16), 0.2, 0.46, cloth_mat)
	_add_capsule("Hips", Vector3(0.0, 0.95, 0.14), 0.18, 0.25, cloth_mat)
	_add_sphere("Head", Vector3(0.0, 1.63, 0.23), 0.15, skin_mat)

	_add_capsule("UpperArmL", Vector3(-0.2, 1.32, 0.48), 0.07, 0.25, cloth_mat, Vector3(0.2, 0.0, 0.65))
	_add_capsule("UpperArmR", Vector3(0.2, 1.32, 0.48), 0.07, 0.25, cloth_mat, Vector3(0.2, 0.0, -0.65))
	_add_capsule("ForearmL", Vector3(-0.24, 1.07, 0.55), 0.06, 0.23, skin_mat, Vector3(0.75, 0.0, 0.35))
	_add_capsule("ForearmR", Vector3(0.24, 1.07, 0.55), 0.06, 0.23, skin_mat, Vector3(0.75, 0.0, -0.35))

	_add_capsule("ThighL", Vector3(-0.12, 0.74, 0.08), 0.085, 0.34, cloth_mat, Vector3(0.95, 0.0, 0.22))
	_add_capsule("ThighR", Vector3(0.12, 0.74, 0.08), 0.085, 0.34, cloth_mat, Vector3(0.95, 0.0, -0.22))
	_add_capsule("CalfL", Vector3(-0.12, 0.43, 0.06), 0.07, 0.32, cloth_mat, Vector3(0.28, 0.0, 0.08))
	_add_capsule("CalfR", Vector3(0.12, 0.43, 0.06), 0.07, 0.32, cloth_mat, Vector3(0.28, 0.0, -0.08))
	_add_box("FootL", Vector3(-0.12, 0.2, 0.0), Vector3(0.11, 0.05, 0.2), dark_mat)
	_add_box("FootR", Vector3(0.12, 0.2, 0.0), Vector3(0.11, 0.05, 0.2), dark_mat)

	match hair_style:
		"helmet":
			_add_sphere("Helmet", Vector3(0.0, 1.72, 0.23), 0.17, dark_mat)
		"long":
			_add_box("HairLong", Vector3(0.0, 1.54, 0.08), Vector3(0.17, 0.2, 0.08), _make_material(Color(0.18, 0.09, 0.04, 1.0), 0.9))
		_:
			_add_box("HairShort", Vector3(0.0, 1.75, 0.23), Vector3(0.18, 0.06, 0.16), _make_material(Color(0.18, 0.09, 0.04, 1.0), 0.9))

func _add_capsule(name: String, pos: Vector3, radius: float, height: float, mat: Material, rot: Vector3 = Vector3.ZERO) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos
	node.rotation = rot
	node.material_override = mat
	add_child(node)

func _add_sphere(name: String, pos: Vector3, radius: float, mat: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	add_child(node)

func _add_box(name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = name
	var mesh := BoxMesh.new()
	mesh.size = size
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
	return mat
