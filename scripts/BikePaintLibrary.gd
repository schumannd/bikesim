extends Object
class_name BikePaintLibrary

const COLOR_PRESETS: Array[Dictionary] = [
	{"id": "arctic_blue", "label": "Arctic Blue", "color": Color(0.12, 0.52, 0.95, 1.0)},
	{"id": "sunset_orange", "label": "Sunset Orange", "color": Color(0.92, 0.38, 0.12, 1.0)},
	{"id": "trail_green", "label": "Trail Green", "color": Color(0.18, 0.62, 0.28, 1.0)},
	{"id": "crimson", "label": "Crimson", "color": Color(0.78, 0.1, 0.18, 1.0)},
	{"id": "violet", "label": "Violet", "color": Color(0.48, 0.22, 0.82, 1.0)},
	{"id": "hot_pink", "label": "Hot Pink", "color": Color(0.95, 0.2, 0.55, 1.0)},
	{"id": "lime", "label": "Lime", "color": Color(0.62, 0.88, 0.18, 1.0)},
	{"id": "gold", "label": "Gold", "color": Color(0.92, 0.72, 0.12, 1.0)},
	{"id": "teal", "label": "Teal", "color": Color(0.12, 0.68, 0.62, 1.0)},
	{"id": "burnt_red", "label": "Burnt Red", "color": Color(0.55, 0.15, 0.1, 1.0)},
	{"id": "navy", "label": "Navy", "color": Color(0.08, 0.14, 0.38, 1.0)},
	{"id": "factory_black", "label": "Factory Black", "color": Color(0.1, 0.1, 0.12, 1.0)},
	{"id": "sand", "label": "Desert Sand", "color": Color(0.76, 0.66, 0.48, 1.0)},
	{"id": "silver", "label": "Silver", "color": Color(0.74, 0.76, 0.8, 1.0)},
	{"id": "white", "label": "Pearl White", "color": Color(0.94, 0.94, 0.92, 1.0)},
	{"id": "charcoal", "label": "Charcoal", "color": Color(0.28, 0.3, 0.32, 1.0)}
]

const FINISHES: Array[Dictionary] = [
	{"id": "gloss", "label": "Gloss"},
	{"id": "matte", "label": "Matte"},
	{"id": "metallic", "label": "Metallic"},
	{"id": "carbon", "label": "Carbon Weave"},
	{"id": "brushed", "label": "Brushed Metal"},
	{"id": "splatter", "label": "Splatter"}
]

static var _texture_cache: Dictionary = {}

static func color_presets() -> Array[Dictionary]:
	return COLOR_PRESETS

static func color_preset_count() -> int:
	return COLOR_PRESETS.size()

static func color_preset(index: int) -> Dictionary:
	return COLOR_PRESETS[posmod(index, COLOR_PRESETS.size())]

static func finishes() -> Array[Dictionary]:
	return FINISHES

static func find_color_index(color: Color) -> int:
	var best_idx := 0
	var best_dist := 9999.0
	for i in range(COLOR_PRESETS.size()):
		var c: Color = COLOR_PRESETS[i]["color"]
		var d: float = absf(c.r - color.r) + absf(c.g - color.g) + absf(c.b - color.b)
		if d < best_dist:
			best_dist = d
			best_idx = i
	return best_idx

static func find_finish_index(finish_id: String) -> int:
	for i in range(FINISHES.size()):
		if str(FINISHES[i]["id"]) == finish_id:
			return i
	return 0

static func make_material(color: Color, finish_id: String) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	match finish_id:
		"matte":
			mat.roughness = 0.95
			mat.metallic = 0.02
		"metallic":
			mat.roughness = 0.28
			mat.metallic = 0.82
		"carbon":
			mat.roughness = 0.42
			mat.metallic = 0.35
			mat.albedo_texture = _pattern_texture("carbon", color)
		"brushed":
			mat.roughness = 0.38
			mat.metallic = 0.55
			mat.albedo_texture = _pattern_texture("brushed", color)
		"splatter":
			mat.roughness = 0.72
			mat.metallic = 0.08
			mat.albedo_texture = _pattern_texture("splatter", color)
		_:
			mat.roughness = 0.45
			mat.metallic = 0.12
	return mat

static func _pattern_texture(pattern_id: String, base_color: Color) -> Texture2D:
	var key := "%s_%s" % [pattern_id, base_color.to_html()]
	if _texture_cache.has(key):
		return _texture_cache[key]

	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	match pattern_id:
		"carbon":
			_fill_carbon_weave(image, base_color)
		"brushed":
			_fill_brushed_metal(image, base_color)
		"splatter":
			_fill_splatter_paint(image, base_color)
		_:
			image.fill(base_color)

	var texture := ImageTexture.create_from_image(image)
	_texture_cache[key] = texture
	return texture

static func _fill_carbon_weave(image: Image, base_color: Color) -> void:
	var dark := base_color.darkened(0.35)
	var light := base_color.lightened(0.12)
	var w := image.get_width()
	var h := image.get_height()
	for y in range(h):
		for x in range(w):
			var cell_x := int(x / 8) % 2
			var cell_y := int(y / 8) % 2
			var diag := int((x + y) / 4) % 2
			var c := light if (cell_x ^ cell_y ^ diag) == 0 else dark
			image.set_pixel(x, y, c)

static func _fill_brushed_metal(image: Image, base_color: Color) -> void:
	var w := image.get_width()
	var h := image.get_height()
	for y in range(h):
		for x in range(w):
			var streak := sin(float(x) * 0.55) * 0.5 + 0.5
			var shade := base_color.lightened(streak * 0.14 - 0.07)
			image.set_pixel(x, y, shade)

static func _fill_splatter_paint(image: Image, base_color: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(base_color.to_html())
	image.fill(base_color.darkened(0.08))
	var w := image.get_width()
	var h := image.get_height()
	for _i in range(180):
		var px := rng.randi_range(0, w - 1)
		var py := rng.randi_range(0, h - 1)
		var radius := rng.randi_range(1, 4)
		var speck := base_color.lightened(rng.randf_range(-0.1, 0.25))
		for oy in range(-radius, radius + 1):
			for ox in range(-radius, radius + 1):
				var sx := px + ox
				var sy := py + oy
				if sx < 0 or sy < 0 or sx >= w or sy >= h:
					continue
				if ox * ox + oy * oy <= radius * radius:
					image.set_pixel(sx, sy, speck)
