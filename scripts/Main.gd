extends Node

@onready var current_screen: Control = $UI/CurrentScreen

func _ready() -> void:
	show_main_menu()

func show_main_menu() -> void:
	_clear_current_screen()
	var scene := preload("res://scenes/MainMenuScene.tscn").instantiate()
	current_screen.add_child(scene)

func show_settings() -> void:
	_clear_current_screen()
	var scene := preload("res://scenes/SettingsScene.tscn").instantiate()
	current_screen.add_child(scene)

func show_ride_scene() -> void:
	_clear_current_screen()
	var scene := preload("res://scenes/RideScene.tscn").instantiate()
	current_screen.add_child(scene)

func show_garage() -> void:
	_clear_current_screen()
	var scene := preload("res://scenes/GarageScene.tscn").instantiate()
	current_screen.add_child(scene)

func show_character_customization() -> void:
	_clear_current_screen()
	var scene := preload("res://scenes/CharacterCustomizationScene.tscn").instantiate()
	current_screen.add_child(scene)

func _clear_current_screen() -> void:
	for child in current_screen.get_children():
		child.queue_free()
