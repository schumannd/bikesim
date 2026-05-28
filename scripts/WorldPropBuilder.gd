extends Object
class_name WorldPropBuilder

const ROAD_TOP_Y := 0.0

static func populate_chunk(parent: Node3D, rng: RandomNumberGenerator, chunk_coord: Vector2i) -> void:
	var props_root := Node3D.new()
	props_root.name = "Props"
	parent.add_child(props_root)

	_add_sidewalk_strips(props_root, rng)
	_add_road_markings(props_root)
	var prop_count := rng.randi_range(5, 10)
	for i in prop_count:
		var pos := _random_prop_position(rng, chunk_coord)
		if pos == Vector3.INF:
			continue
		match rng.randi_range(0, 6):
			0:
				_add_tree(props_root, pos, rng)
			1:
				_add_lamppost(props_root, pos, rng)
			2:
				_add_bench(props_root, pos, rng)
			3:
				_add_planter(props_root, pos, rng)
			4:
				_add_trash_bin(props_root, pos, rng)
			5:
				_add_bike_rack(props_root, pos, rng)
			6:
				_add_street_sign(props_root, pos, rng)

static func _random_prop_position(rng: RandomNumberGenerator, chunk_coord: Vector2i) -> Vector3:
	for _attempt in 8:
		var on_x_band := rng.randf() > 0.5
		var pos: Vector3
		if on_x_band:
			var side := -1.0 if rng.randf() > 0.5 else 1.0
			pos = Vector3(side * rng.randf_range(22.0, 52.0), ROAD_TOP_Y, rng.randf_range(-52.0, 52.0))
		else:
			var side := -1.0 if rng.randf() > 0.5 else 1.0
			pos = Vector3(rng.randf_range(-52.0, 52.0), ROAD_TOP_Y, side * rng.randf_range(22.0, 52.0))
		if chunk_coord == Vector2i.ZERO and pos.distance_to(Vector3(-18.0, 0.0, -16.0)) < 22.0:
			continue
		if absf(pos.x) < 12.0 and absf(pos.z) < 12.0:
			continue
		return pos
	return Vector3.INF

static func _add_sidewalk_strips(parent: Node3D, rng: RandomNumberGenerator) -> void:
	var mat := _mat(Color(0.42, 0.43, 0.44, 1.0), 0.98)
	var strip_w := 3.5
	var strip_h := 0.08
	var half := 60.0
	var road_half := 8.0
	var offset := road_half + strip_w * 0.5 + 0.5
	_add_box(parent, Vector3(offset, ROAD_TOP_Y + strip_h * 0.5, 0.0), Vector3(strip_w, strip_h, half * 2.0 - 16.0), mat)
	_add_box(parent, Vector3(-offset, ROAD_TOP_Y + strip_h * 0.5, 0.0), Vector3(strip_w, strip_h, half * 2.0 - 16.0), mat)
	_add_box(parent, Vector3(0.0, ROAD_TOP_Y + strip_h * 0.5, offset), Vector3(half * 2.0 - 16.0, strip_h, strip_w), mat)
	_add_box(parent, Vector3(0.0, ROAD_TOP_Y + strip_h * 0.5, -offset), Vector3(half * 2.0 - 16.0, strip_h, strip_w), mat)
	if rng.randf() > 0.4:
		var accent := _mat(Color(0.5, 0.52, 0.54, 1.0), 1.0)
		_add_box(parent, Vector3(offset, ROAD_TOP_Y + strip_h + 0.01, 0.0), Vector3(strip_w - 0.6, 0.02, 1.2), accent)

static func _add_road_markings(parent: Node3D) -> void:
	var line_mat := _mat(Color(0.92, 0.9, 0.35, 1.0), 0.85)
	var dash_mat := _mat(Color(0.85, 0.85, 0.88, 0.9), 0.9)
	var y := ROAD_TOP_Y + 0.02
	var half := 60.0
	var dash_len := 4.0
	var z := -half + 12.0
	while z < half - 8.0:
		_add_box(parent, Vector3(0.0, y, z), Vector3(0.12, 0.02, dash_len), line_mat)
		z += dash_len * 2.2
	z = -half + 12.0
	while z < half - 8.0:
		_add_box(parent, Vector3(z, y, 0.0), Vector3(dash_len, 0.02, 0.12), line_mat)
		z += dash_len * 2.2
	_add_box(parent, Vector3(0.0, y, 0.0), Vector3(0.2, 0.02, 14.0), dash_mat)
	_add_box(parent, Vector3(0.0, y, 0.0), Vector3(14.0, 0.02, 0.2), dash_mat)

static func _add_tree(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var trunk_mat := _mat(Color(0.35, 0.22, 0.12, 1.0), 0.95)
	var leaf_mat := _mat(Color(0.15 + rng.randf() * 0.1, 0.45 + rng.randf() * 0.15, 0.18, 1.0), 0.9)
	var scale := rng.randf_range(0.85, 1.25)
	_add_cylinder(parent, pos + Vector3(0.0, 0.65 * scale, 0.0), 0.18 * scale, 1.3 * scale, trunk_mat)
	_add_sphere(parent, pos + Vector3(0.0, 1.85 * scale, 0.0), 0.95 * scale, leaf_mat)
	_add_sphere(parent, pos + Vector3(0.25 * scale, 1.55 * scale, 0.1), 0.65 * scale, leaf_mat)

static func _add_lamppost(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var metal := _mat(Color(0.2, 0.21, 0.22, 1.0), 0.35)
	var glow := _mat(Color(1.0, 0.92, 0.7, 1.0), 0.2)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.9, 0.65, 1.0)
	glow.emission_energy_multiplier = 1.2
	_add_cylinder(parent, pos + Vector3(0.0, 1.6, 0.0), 0.07, 3.2, metal)
	_add_box(parent, pos + Vector3(0.35, 3.1, 0.0), Vector3(0.7, 0.08, 0.08), metal)
	_add_sphere(parent, pos + Vector3(0.55, 3.05, 0.0), 0.14, glow)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0.5, 3.0, 0.0)
	light.light_energy = 0.9
	light.omni_range = 10.0
	light.light_color = Color(1.0, 0.88, 0.65, 1.0)
	parent.add_child(light)

static func _add_bench(parent: Node3D, pos: Vector3, _rng: RandomNumberGenerator) -> void:
	var wood := _mat(Color(0.42, 0.28, 0.14, 1.0), 0.92)
	var metal := _mat(Color(0.18, 0.18, 0.19, 1.0), 0.4)
	_add_box(parent, pos + Vector3(0.0, 0.28, 0.0), Vector3(1.4, 0.08, 0.45), wood)
	_add_box(parent, pos + Vector3(0.0, 0.55, -0.16), Vector3(1.35, 0.5, 0.06), wood)
	_add_cylinder(parent, pos + Vector3(-0.55, 0.22, 0.0), 0.04, 0.44, metal)
	_add_cylinder(parent, pos + Vector3(0.55, 0.22, 0.0), 0.04, 0.44, metal)

static func _add_planter(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var pot := _mat(Color(0.48, 0.32, 0.22, 1.0), 0.9)
	var plant := _mat(Color(0.2, 0.55 + rng.randf() * 0.1, 0.25, 1.0), 0.95)
	_add_box(parent, pos + Vector3(0.0, 0.22, 0.0), Vector3(1.0, 0.44, 1.0), pot)
	_add_sphere(parent, pos + Vector3(0.0, 0.65, 0.0), 0.42, plant)

static func _add_trash_bin(parent: Node3D, pos: Vector3, _rng: RandomNumberGenerator) -> void:
	var mat := _mat(Color(0.28, 0.45, 0.32, 1.0), 0.85)
	_add_cylinder(parent, pos + Vector3(0.0, 0.45, 0.0), 0.28, 0.9, mat)
	_add_box(parent, pos + Vector3(0.0, 0.95, 0.0), Vector3(0.5, 0.12, 0.5), mat)

static func _add_bike_rack(parent: Node3D, pos: Vector3, _rng: RandomNumberGenerator) -> void:
	var metal := _mat(Color(0.25, 0.26, 0.28, 1.0), 0.4)
	_add_box(parent, pos + Vector3(0.0, 0.35, 0.0), Vector3(1.8, 0.06, 0.5), metal)
	_add_cylinder(parent, pos + Vector3(-0.7, 0.45, 0.0), 0.03, 0.9, metal)
	_add_cylinder(parent, pos + Vector3(0.7, 0.45, 0.0), 0.03, 0.9, metal)
	_add_cylinder(parent, pos + Vector3(0.0, 0.45, 0.22), 0.03, 0.9, metal)

static func _add_street_sign(parent: Node3D, pos: Vector3, rng: RandomNumberGenerator) -> void:
	var metal := _mat(Color(0.22, 0.23, 0.24, 1.0), 0.45)
	var sign_colors: Array[Color] = [
		Color(0.15, 0.45, 0.85, 1.0),
		Color(0.85, 0.2, 0.15, 1.0),
		Color(0.2, 0.65, 0.3, 1.0)
	]
	var sign_mat := _mat(sign_colors[rng.randi_range(0, sign_colors.size() - 1)], 0.7)
	_add_cylinder(parent, pos + Vector3(0.0, 1.2, 0.0), 0.05, 2.4, metal)
	_add_box(parent, pos + Vector3(0.0, 2.35, 0.0), Vector3(0.9, 0.55, 0.06), sign_mat)

static func add_building_windows(building: StaticBody3D, size: Vector3, rng: RandomNumberGenerator) -> void:
	var window_mat := _mat(Color(0.55, 0.72, 0.92, 1.0), 0.15)
	window_mat.emission_enabled = true
	window_mat.emission = Color(0.4, 0.55, 0.75, 1.0)
	window_mat.emission_energy_multiplier = 0.35
	var cols := maxi(2, int(size.x / 4.0))
	var rows := maxi(2, int(size.y / 4.5))
	var win_w := 1.2
	var win_h := 1.6
	for col in cols:
		for row in rows:
			if rng.randf() < 0.2:
				continue
			var fx := (float(col) / float(cols - 1) - 0.5) * (size.x - 2.0)
			var fy := 2.0 + float(row) / float(rows) * (size.y - 4.0)
			var face := 1.0 if rng.randf() > 0.5 else -1.0
			var fz := face * (size.z * 0.5 + 0.06)
			var win := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(win_w, win_h, 0.12)
			win.mesh = mesh
			win.position = Vector3(fx, fy, fz)
			win.material_override = window_mat
			building.add_child(win)

static func _add_box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)

static func _add_cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)

static func _add_sphere(parent: Node3D, pos: Vector3, radius: float, mat: Material) -> void:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	node.mesh = mesh
	node.position = pos
	node.material_override = mat
	parent.add_child(node)

static func _mat(color: Color, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat
