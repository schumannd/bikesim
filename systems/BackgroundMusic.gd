extends Node

## Procedural looping background music (no external assets).

const SAMPLE_RATE := 44100.0
const BPM := 92.0
const MUSIC_VOLUME_DB := -14.0

# Am — F — C — G (chill ride progression)
const CHORDS: Array = [
	[57, 60, 64],
	[53, 57, 60],
	[48, 52, 55],
	[55, 59, 62],
]

var _player: AudioStreamPlayer
var _sample_clock: float = 0.0

func _ready() -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = SAMPLE_RATE
	generator.buffer_length = 0.25

	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.stream = generator
	_player.bus = &"Master"
	_player.volume_db = MUSIC_VOLUME_DB
	_player.autoplay = true
	add_child(_player)
	_player.play()

func _process(_delta: float) -> void:
	_push_audio_frames()

func _push_audio_frames() -> void:
	if _player == null or not _player.playing:
		return
	var playback: AudioStreamGeneratorPlayback = _player.get_stream_playback()
	if playback == null:
		return
	var available := playback.get_frames_available()
	if available < 1:
		return

	var frames := PackedVector2Array()
	frames.resize(available)
	for i in available:
		var sample := _mix_sample()
		frames[i] = Vector2(sample, sample)
		_sample_clock += 1.0
	playback.push_buffer(frames)

func _mix_sample() -> float:
	var beat := 60.0 / BPM
	var samples_per_beat := SAMPLE_RATE * beat
	var bar_samples := samples_per_beat * 4.0
	var bar_index := int(floor(_sample_clock / bar_samples))
	var chord_idx := bar_index % CHORDS.size()
	var chord: Array = CHORDS[chord_idx]
	var t_in_bar := fmod(_sample_clock, bar_samples) / SAMPLE_RATE

	var pad := _pad_layer(chord, t_in_bar, beat)
	var bass := _bass_layer(chord, _sample_clock, samples_per_beat)
	var arp := _arp_layer(chord, _sample_clock, samples_per_beat * 0.5)
	return clampf((pad + bass + arp) * 0.42, -1.0, 1.0)

func _pad_layer(chord: Array, t_in_bar: float, beat: float) -> float:
	var bar_len := beat * 4.0
	var env := _adsr(t_in_bar, 0.35, 0.2, 0.65, bar_len)
	var sample := 0.0
	for note: int in chord:
		var freq := _midi_to_hz(note - 12)
		var phase := _sample_clock * TAU * freq / SAMPLE_RATE
		sample += sin(phase) * 0.55 + sin(phase * 2.0) * 0.12
	return sample * env * 0.09

func _bass_layer(chord: Array, clock: float, samples_per_beat: float) -> float:
	var beat_idx := int(floor(clock / samples_per_beat)) % 4
	if beat_idx != 0 and beat_idx != 2:
		return 0.0
	var root: int = chord[0] - 24
	var freq := _midi_to_hz(root)
	var t_beat := fmod(clock, samples_per_beat) / SAMPLE_RATE
	var env := _adsr(t_beat, 0.02, 0.08, 0.5, 60.0 / BPM)
	var phase := clock * TAU * freq / SAMPLE_RATE
	return sin(phase) * env * 0.14

func _arp_layer(chord: Array, clock: float, samples_per_step: float) -> float:
	var step := int(floor(clock / samples_per_step))
	var note: int = chord[step % chord.size()] + 12
	var freq := _midi_to_hz(note)
	var t_step := fmod(clock, samples_per_step) / SAMPLE_RATE
	var env := _adsr(t_step, 0.005, 0.04, 0.25, samples_per_step / SAMPLE_RATE)
	var phase := clock * TAU * freq / SAMPLE_RATE
	return sin(phase) * env * 0.07

func _midi_to_hz(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)

func _adsr(t: float, attack: float, decay: float, sustain: float, duration: float) -> float:
	if t < attack:
		return t / maxf(attack, 0.001)
	if t < attack + decay:
		var k := (t - attack) / maxf(decay, 0.001)
		return lerpf(1.0, sustain, k)
	var release_start := maxf(duration - decay, attack + decay)
	if t > release_start:
		var k := (t - release_start) / maxf(decay, 0.001)
		return lerpf(sustain, 0.0, k)
	return sustain
