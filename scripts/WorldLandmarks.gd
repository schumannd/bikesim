extends Object
class_name WorldLandmarks

const CityTerrainScript := preload("res://scripts/CityTerrain.gd")

static func add_train_tracks(parent: Node3D, chunk_coord: Vector2i, chunk_size: float) -> void:
	var root := Node3D.new()
	root.name = "TrainTracks"
	parent.add_child(root)
	var rail_mat := _mat(Color(0.35, 0.34, 0.33, 1.0), 0.95)
	var tie_mat := _mat(Color(0.28, 0.22, 0.16, 1.0), 1.0)
	var ox := float(chunk_coord.x) * chunk_size
	var oz := float(chunk_coord.y) * chunk_size
	var step := 8.0
	var x := 0.0
	while x <= chunk_size + 0.1:
		var z := 0.0
		while z <= chunk_size + 0.1:
			var wx := ox + x
			var wz := oz + z
			if not CityTerrainScript.is_train_corridor(wx, wz):
				z += step
				continue
			var h := CityTerrainScript.sample_height(wx, wz)
			_add_box(root, Vector3(x, h + 0.06, z), Vector3(6.5, 0.1, step + 0.5), rail_mat)
			if int(x) % 16 == 0:
				_add_box(root, Vector3(x, h + 0.04, z), Vector3(0.35, 0.08, step + 0.2), tie_mat)
			z += step
		x += step
	# Rails (thin metal strips)
	x = 0.0
	while x <= chunk_size + 0.1:
		z = 0.0
		while z <= chunk_size + 0.1:
			var wx := ox + x
			var wz := oz + z
			if not CityTerrainScript.is_train_corridor(wx, wz):
				z += step * 0.5
				continue
			var h := CityTerrainScript.sample_height(wx, wz)
			var offset := 0.9 if fposmod(wx - wz, 2.0) > 1.0 else -0.9
			_add_box(root, Vector3(x + offset, h + 0.11, z), Vector3(0.08, 0.06, step * 0.6), _mat(Color(0.55, 0.56, 0.58, 1.0), 0.4))
			z += step * 0.5
		x += step * 0.5

static func add_school(parent: Node3D, local_center: Vector3, chunk_coord: Vector2i, chunk_size: float) -> void:
	var base := _terrain_base(local_center, chunk_coord, chunk_size)
	var wall := _mat(Color(0.72, 0.74, 0.76, 1.0), 0.9)
	var roof := _mat(Color(0.55, 0.28, 0.22, 1.0), 0.85)
	var accent := _mat(Color(0.2, 0.45, 0.75, 1.0), 0.8)
	_add_colored_building(parent, base + Vector3(0.0, 4.0, 0.0), Vector3(36.0, 8.0, 22.0), wall, true)
	_add_colored_building(parent, base + Vector3(-14.0, 3.0, 8.0), Vector3(12.0, 6.0, 10.0), accent, true)
	_add_colored_building(parent, base + Vector3(14.0, 3.0, 8.0), Vector3(12.0, 6.0, 10.0), accent, true)
	_add_colored_building(parent, base + Vector3(0.0, 9.5, 0.0), Vector3(34.0, 1.2, 20.0), roof, false)
	_add_sign(parent, base + Vector3(0.0, 12.0, 12.0), Color(0.95, 0.95, 0.2, 1.0), "SCHOOL")

static func add_stadium(parent: Node3D, local_center: Vector3, chunk_coord: Vector2i, chunk_size: float) -> void:
	var base := _terrain_base(local_center, chunk_coord, chunk_size)
	var field := _mat(Color(0.16, 0.48, 0.22, 1.0), 0.95)
	var seat := _mat(Color(0.42, 0.44, 0.48, 1.0), 0.9)
	_add_colored_building(parent, base + Vector3(0.0, 0.15, 0.0), Vector3(48.0, 0.3, 36.0), field, true)
	_add_colored_building(parent, base + Vector3(0.0, 4.0, -20.0), Vector3(50.0, 8.0, 6.0), seat, true)
	_add_colored_building(parent, base + Vector3(0.0, 4.0, 20.0), Vector3(50.0, 8.0, 6.0), seat, true)
	_add_colored_building(parent, base + Vector3(-24.0, 4.0, 0.0), Vector3(6.0, 8.0, 40.0), seat, true)
	_add_colored_building(parent, base + Vector3(24.0, 4.0, 0.0), Vector3(6.0, 8.0, 40.0), seat, true)
	_add_sign(parent, base + Vector3(0.0, 10.0, 0.0), Color(1.0, 0.85, 0.2, 1.0), "STADIUM")

static func add_train_station(parent: Node3D, local_center: Vector3, chunk_coord: Vector2i, chunk_size: float) -> void:
	var base := _terrain_base(local_center, chunk_coord, chunk_size)
	var stone := _mat(Color(0.48, 0.46, 0.44, 1.0), 0.88)
	var glass := _mat(Color(0.55, 0.72, 0.88, 1.0), 0.2)
	glass.emission_enabled = true
	glass.emission = Color(0.5, 0.65, 0.85, 1.0)
	glass.emission_energy_multiplier = 0.5
	_add_colored_building(parent, base + Vector3(0.0, 2.5, 0.0), Vector3(28.0, 5.0, 14.0), stone, true)
	_add_colored_building(parent, base + Vector3(0.0, 2.0, 8.0), Vector3(20.0, 4.0, 0.4), glass, false)
	_add_colored_building(parent, base + Vector3(0.0, 0.2, -10.0), Vector3(40.0, 0.4, 8.0), stone, true)
	_add_sign(parent, base + Vector3(0.0, 7.0, 0.0), Color(0.9, 0.92, 0.95, 1.0), "STATION")

static func _add_colored_building(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, collision: bool) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	if collision:
		var shape_node := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		shape_node.shape = shape
		body.add_child(shape_node)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = mat
	body.add_child(mesh)

static func _add_sign(parent: Node3D, pos: Vector3, color: Color, _text: String) -> void:
	var sign := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(8.0, 1.2, 0.2)
	sign.mesh = mesh
	sign.position = pos
	var mat := _mat(color, 0.5)
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4
	sign.material_override = mat
	parent.add_child(sign)

static func _add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)

static func _terrain_base(local_center: Vector3, chunk_coord: Vector2i, chunk_size: float) -> Vector3:
	var wx := chunk_coord.x * chunk_size + local_center.x
	var wz := chunk_coord.y * chunk_size + local_center.z
	var h := CityTerrainScript.sample_height(wx, wz)
	return Vector3(local_center.x, h, local_center.z)

static func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat
