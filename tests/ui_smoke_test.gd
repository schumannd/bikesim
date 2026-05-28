extends SceneTree

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	_assert(packed != null, "Main scene must load")
	if packed == null:
		_finish()
		return

	var main: Node = packed.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var current_screen: Control = main.get_node("UI/CurrentScreen")
	_assert(current_screen.get_child_count() == 1, "Main should start with one active screen")
	_assert(current_screen.get_child(0).name == "RideScene", "Initial screen should be RideScene")

	main.call("show_garage")
	await process_frame
	_assert(current_screen.get_child_count() == 1, "Garage navigation keeps one active screen")
	_assert(current_screen.get_child(0).name == "GarageScene", "Garage menu should open")

	var garage: Node = current_screen.get_child(0)
	garage.call("_on_save_pressed")
	await process_frame
	_assert(current_screen.get_child(0).name == "RideScene", "Save in garage should return to ride scene")

	main.call("show_character_customization")
	await process_frame
	_assert(current_screen.get_child_count() == 1, "Character nav keeps one active screen")
	_assert(current_screen.get_child(0).name == "CharacterCustomizationScene", "Character menu should open")

	var character_menu: Node = current_screen.get_child(0)
	character_menu.call("_on_cancel_pressed")
	await process_frame
	_assert(current_screen.get_child(0).name == "RideScene", "Cancel in character menu should return to ride scene")

	_finish()

func _assert(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		print("FAIL: %s" % message)
	else:
		print("PASS: %s" % message)

func _finish() -> void:
	if current_scene:
		current_scene.free()
		current_scene = null
	if failures.is_empty():
		print("UI smoke test passed.")
		quit(0)
	else:
		push_error("UI smoke test failed (%d): %s" % [failures.size(), ", ".join(failures)])
		quit(1)
