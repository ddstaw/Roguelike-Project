extends Control

@onready var resume_button = $Panel/Panel/VBoxContainer/ResumeButton
@onready var menu_button   = $Panel/Panel/VBoxContainer/MainMenuButton
@onready var quit_button   = $Panel/Panel/VBoxContainer/QuitButton

func _ready():
	resume_button.pressed.connect(_on_resume_pressed)
	menu_button.pressed.connect(_on_quit_to_menu_pressed)
	quit_button.pressed.connect(_on_quit_game_pressed)
	hide()

func _on_resume_pressed() -> void:
	hide()
	get_tree().paused = false

func _on_quit_to_menu_pressed() -> void:
	# Placeholder for now – will add save logic later
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_quit_game_pressed() -> void:
	# Placeholder for now – will add save logic later
	get_tree().paused = false
	get_tree().quit()
