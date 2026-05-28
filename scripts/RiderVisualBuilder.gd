extends Node3D

func apply_config(config: Resource) -> void:
	_clear_parts()
	var skin_tone: Color = config.get("skin_tone")
	var outfit_color: Color = config.get("outfit_color")
	var hair_style: String = str(config.get("hair_style"))

	var skin_mat := _make_material(skin_tone, 0.9)
	var cloth_mat := _make_material(outfit_color, 0.98)
	var dark_mat := _make_material(Color(0.08, 0.08, 0.08, 1.0), 0.9)

	_add_capsule("Torso", Vector3(0.0, 0.92, 0.08), 0.18, 0.4, cloth_mat)
	_add_capsule("Hips", Vector3(0.0, 0.73, 0.04), 0.17, 0.22, cloth_mat)
	_add_sphere("Head", Vector3(0.0, 1.2, 0.14), 0.14, skin_mat)

	_add_capsule("UpperArmL", Vector3(-0.19, 0.98, 0.38), 0.06, 0.23, cloth_mat, Vector3(0.25, 0.0, 0.62))
	_add_capsule("UpperArmR", Vector3(0.19, 0.98, 0.38), 0.06, 0.23, cloth_mat, Vector3(0.25, 0.0, -0.62))
	_add_capsule("ForearmL", Vector3(-0.24, 0.78, 0.48), 0.055, 0.2, skin_mat, Vector3(0.72, 0.0, 0.32))
	_add_capsule("ForearmR", Vector3(0.24, 0.78, 0.48), 0.055, 0.2, skin_mat, Vector3(0.72, 0.0, -0.32))

	_add_capsule("ThighL", Vector3(-0.11, 0.62, 0.16), 0.08, 0.28, cloth_mat, Vector3(1.05, 0.0, 0.18))
	_add_capsule("ThighR", Vector3(0.11, 0.62, 0.16), 0.08, 0.28, cloth_mat, Vector3(1.05, 0.0, -0.18))
	_add_capsule("CalfL", Vector3(-0.12, 0.46, 0.0), 0.065, 0.24, cloth_mat, Vector3(0.36, 0.0, 0.05))
	_add_capsule("CalfR", Vector3(0.12, 0.46, 0.0), 0.065, 0.24, cloth_mat, Vector3(0.36, 0.0, -0.05))
	_add_box("FootL", Vector3(-0.12, 0.34, -0.05), Vector3(0.11, 0.05, 0.2), dark_mat)
	_add_box("FootR", Vector3(0.12, 0.34, -0.05), Vector3(0.11, 0.05, 0.2), dark_mat)

	match hair_style:
		"helmet":
			_add_sphere("Helmet", Vector3(0.0, 1.28, 0.14), 0.16, dark_mat)
		"long":
			_add_box("HairLong", Vector3(0.0, 1.12, 0.02), Vector3(0.16, 0.18, 0.08), _make_material(Color(0.18, 0.09, 0.04, 1.0), 0.9))
		_:
			_add_box("HairShort", Vector3(0.0, 1.33, 0.14), Vector3(0.18, 0.06, 0.16), _make_material(Color(0.18, 0.09, 0.04, 1.0), 0.9))

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
