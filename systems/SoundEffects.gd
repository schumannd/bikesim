extends Node

## Procedural UI and gameplay one-shots (no external assets).

const SAMPLE_RATE := 44100

var _menu_move: AudioStreamWAV
var _menu_confirm: AudioStreamWAV
var _wall_hit: AudioStreamWAV
var _brake_loop: AudioStreamWAV

var _brake_player: AudioStreamPlayer
var _wall_cooldown: float = 0.0

func _ready() -> void:
	_menu_move = _make_click(920.0, 0.045, 55.0, 0.35)
	_menu_confirm = _make_click(520.0, 0.09, 38.0, 0.5)
	_wall_hit = _make_wall_thunk()
	_brake_loop = _make_brake_loop()

	_brake_player = AudioStreamPlayer.new()
	_brake_player.name = "BrakeLoop"
	_brake_player.stream = _brake_loop
	_brake_player.volume_db = -24.0
	_brake_player.bus = &"Master"
	add_child(_brake_player)

func wire_menu_buttons(root: Node) -> void:
	for node: Node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null:
			continue
		if not button.mouse_entered.is_connected(_on_menu_button_hover):
			button.mouse_entered.connect(_on_menu_button_hover)
		if not button.pressed.is_connected(_on_menu_button_pressed):
			button.pressed.connect(_on_menu_button_pressed)

func wire_option_button(option: OptionButton) -> void:
	if option.item_selected.is_connected(_on_option_changed):
		return
	option.item_selected.connect(_on_option_changed)

func play_menu_move() -> void:
	_play_stream(_menu_move, -16.0, randf_range(0.96, 1.04))

func play_menu_confirm() -> void:
	_play_stream(_menu_confirm, -12.0, randf_range(0.98, 1.02))

func play_wall_hit(intensity: float) -> void:
	if _wall_cooldown > 0.0:
		return
	var power := clampf(intensity, 0.0, 1.0)
	if power < 0.12:
		return
	_wall_cooldown = 0.16
	var volume := lerpf(-20.0, -6.0, power)
	var pitch := lerpf(0.85, 1.15, power)
	_play_stream(_wall_hit, volume, pitch)

func set_brake_active(active: bool, intensity: float) -> void:
	if _brake_player == null:
		return
	var power := clampf(intensity, 0.0, 1.0)
	if not active or power < 0.05:
		if _brake_player.playing:
			_brake_player.stop()
		return
	if not _brake_player.playing:
		_brake_player.play()
	_brake_player.volume_db = lerpf(-32.0, -14.0, power)
	_brake_player.pitch_scale = lerpf(0.9, 1.25, power)

func _process(delta: float) -> void:
	if _wall_cooldown > 0.0:
		_wall_cooldown = maxf(_wall_cooldown - delta, 0.0)

func _on_menu_button_hover() -> void:
	play_menu_move()

func _on_menu_button_pressed() -> void:
	play_menu_confirm()

func _on_option_changed(_index: int) -> void:
	play_menu_move()

func _play_stream(stream: AudioStream, volume_db: float, pitch_scale: float = 1.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.bus = &"Master"
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)

func _make_click(freq: float, duration: float, decay: float, gain: float) -> AudioStreamWAV:
	var count := maxi(1, int(SAMPLE_RATE * duration))
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * decay)
		var phase := TAU * freq * t
		samples[i] = (sin(phase) * 0.75 + sin(phase * 2.0) * 0.15) * env * gain
	return _samples_to_wav(samples)

func _make_wall_thunk() -> AudioStreamWAV:
	var duration := 0.14
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 90210
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var env := exp(-t * 28.0)
		var noise := rng.randf_range(-1.0, 1.0)
		var thump := sin(TAU * 110.0 * t) * exp(-t * 18.0)
		samples[i] = (noise * 0.55 + thump * 0.65) * env * 0.7
	return _samples_to_wav(samples)

func _make_brake_loop() -> AudioStreamWAV:
	var duration := 0.22
	var count := int(SAMPLE_RATE * duration)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 44012
	for i in count:
		var t := float(i) / SAMPLE_RATE
		var scrape := sin(TAU * 220.0 * t + sin(TAU * 7.0 * t) * 2.5)
		var noise := rng.randf_range(-1.0, 1.0)
		samples[i] = (noise * 0.35 + scrape * 0.25) * 0.45
	var stream := _samples_to_wav(samples)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream

func _samples_to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	var byte_count := samples.size() * 4
	var data := PackedByteArray()
	data.resize(byte_count)
	for i in samples.size():
		var value := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		var lo := value & 0xFF
		var hi := (value >> 8) & 0xFF
		var base := i * 4
		data[base] = lo
		data[base + 1] = hi
		data[base + 2] = lo
		data[base + 3] = hi
	stream.data = data
	return stream
