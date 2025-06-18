extends Control

func _ready():
	$Panel/ProceedButton.pressed.connect(_on_proceed_pressed)
	$Panel/BackButton.pressed.connect(_on_back_pressed)

func _on_proceed_pressed():
	print("Proceeding to place settlements.")
	hide()  # Hide the pop-up window
	get_tree().root.get_node("Path/To/Your/CultureMap.gd").start_settlement_placement()  # Replace with the correct path

func _on_back_pressed():
	print("Returning to map generator.")
	hide()  # Hide the pop-up window
	get_tree().root.get_node("res://scenes/NewGame.tscn").return_to_map_generator()  # Replace with the correct path
