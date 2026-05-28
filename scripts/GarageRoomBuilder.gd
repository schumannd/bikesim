extends Node3D

const FLOOR_SIZE := Vector3(14.0, 0.2, 10.0)
const WALL_HEIGHT := 4.2

func _ready() -> void:
	_build_room()

func _build_room() -> void:
	var floor_mat := _mat(Color(0.14, 0.14, 0.15, 1.0), 0.95)
	var wall_mat := _mat(Color(0.22, 0.23, 0.25, 1.0), 0.9)
	var trim_mat := _mat(Color(0.32, 0.34, 0.36, 1.0), 0.75)
	var ceiling_mat := _mat(Color(0.1, 0.1, 0.11, 1.0), 1.0)

	_add_box("Floor", Vector3(0.0, -0.1, 0.0), FLOOR_SIZE, floor_mat)
	_add_box("Ceiling", Vector3(0.0, WALL_HEIGHT + 0.1, 0.0), Vector3(FLOOR_SIZE.x, 0.2, FLOOR_SIZE.z), ceiling_mat)

	var half_x := FLOOR_SIZE.x * 0.5
	var half_z := FLOOR_SIZE.z * 0.5
	var wall_thickness := 0.25
	var wall_y := WALL_HEIGHT * 0.5

	_add_box("WallBack", Vector3(0.0, wall_y, -half_z), Vector3(FLOOR_SIZE.x, WALL_HEIGHT, wall_thickness), wall_mat)
	_add_box("WallFront", Vector3(0.0, wall_y, half_z), Vector3(FLOOR_SIZE.x, WALL_HEIGHT, wall_thickness), wall_mat)
	_add_box("WallLeft", Vector3(-half_x, wall_y, 0.0), Vector3(wall_thickness, WALL_HEIGHT, FLOOR_SIZE.z), wall_mat)
	_add_box("WallRight", Vector3(half_x, wall_y, 0.0), Vector3(wall_thickness, WALL_HEIGHT, FLOOR_SIZE.z), wall_mat)

	_add_box("TrimBack", Vector3(0.0, 0.12, -half_z + 0.12), Vector3(FLOOR_SIZE.x - 0.4, 0.08, 0.5), trim_mat)
	_add_box("ToolBench", Vector3(-4.8, 0.55, 3.2), Vector3(2.4, 1.1, 0.7), trim_mat)
	_add_box("PartsShelf", Vector3(4.7, 1.2, 3.0), Vector3(1.8, 2.4, 0.45), trim_mat)

func _add_box(name: String, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = mat
	add_child(mesh)

func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat
