extends Control

const LivingRoomBuilderScript := preload("res://scripts/LivingRoomBuilder.gd")

@onready var dialogue_label: Label = $MenuPanel/Margin/VBox/DialogueLabel
@onready var hint_label: Label = $MenuPanel/Margin/VBox/HintLabel
@onready var room_root: Node3D = $ViewportPanel/SubViewportContainer/SubViewport/World
@onready var camera: Camera3D = $ViewportPanel/SubViewportContainer/SubViewport/World/Camera3D
@onready var phone_minigame: Control = $PhoneMinigame
@onready var viewport_container: SubViewportContainer = $ViewportPanel/SubViewportContainer

var _room: Node3D
var _npc_index: int = 0
var _npcs: Array[Node3D] = []

func _ready() -> void:
	SoundEffects.wire_menu_buttons(self)
	_style_panels()
	_setup_camera()
	_room = Node3D.new()
	_room.name = "LivingRoom"
	_room.set_script(LivingRoomBuilderScript)
	room_root.add_child(_room)
	await get_tree().process_frame
	_npcs = _room.call("get_npcs")
	_npc_index = 0
	_update_dialogue()
	hint_label.text = "W/S: select person | E: talk | P: phone | Esc: leave"
	phone_minigame.visible = false
	set_process_unhandled_input(true)
	resized.connect(_on_resized)

func _style_panels() -> void:
	var menu_style := StyleBoxFlat.new()
	menu_style.bg_color = Color(0.07, 0.08, 0.1, 1.0)
	$MenuPanel.add_theme_stylebox_override("panel", menu_style)
	var viewport_style := StyleBoxFlat.new()
	viewport_style.bg_color = Color(0.05, 0.06, 0.07, 1.0)
	$ViewportPanel.add_theme_stylebox_override("panel", viewport_style)

func _setup_camera() -> void:
	camera.position = Vector3(0.0, 2.0, 5.2)
	camera.look_at(Vector3(0.0, 0.9, 0.0), Vector3.UP)
	camera.fov = 52.0

func _on_resized() -> void:
	if viewport_container == null:
		return
	var size := viewport_container.size
	if size.x > 0 and size.y > 0:
		viewport_container.get_child(0).size = Vector2i(int(size.x), int(size.y))

func _unhandled_input(event: InputEvent) -> void:
	if phone_minigame.visible:
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_W, KEY_UP:
			_cycle_npc(-1)
		KEY_S, KEY_DOWN:
			_cycle_npc(1)
		KEY_E:
			_talk_to_selected_npc()
		KEY_P:
			_open_phone_minigame()
		KEY_ESCAPE:
			_exit_to_world()

func _cycle_npc(direction: int) -> void:
	if _npcs.is_empty():
		return
	_npc_index = posmod(_npc_index + direction, _npcs.size())
	SoundEffects.play_menu_move()
	_update_dialogue()

func _talk_to_selected_npc() -> void:
	if _npcs.is_empty():
		return
	var npc: Node3D = _npcs[_npc_index]
	if npc.has_method("advance_dialogue"):
		dialogue_label.text = npc.call("advance_dialogue")
	else:
		_update_dialogue()
	SoundEffects.play_menu_confirm()

func _update_dialogue() -> void:
	if _npcs.is_empty():
		dialogue_label.text = "The room is quiet."
		return
	var npc: Node3D = _npcs[_npc_index]
	var name_str := str(npc.get("npc_name"))
	var line := str(npc.call("get_current_line")) if npc.has_method("get_current_line") else "..."
	dialogue_label.text = "%s: %s" % [name_str, line]

func _open_phone_minigame() -> void:
	SoundEffects.play_menu_confirm()
	phone_minigame.visible = true
	if phone_minigame.has_method("restart"):
		phone_minigame.call("restart")

func _exit_to_world() -> void:
	GameState.queue_house_exit()
	var main: Node = get_tree().current_scene
	if main and main.has_method("show_ride_scene"):
		main.show_ride_scene()

func _on_leave_pressed() -> void:
	_exit_to_world()

func _on_phone_pressed() -> void:
	_open_phone_minigame()
