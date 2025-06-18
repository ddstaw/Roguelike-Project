extends Button

func _ready():
	print("Button script ready")  # Ensures the script is running

func _on_pressed():
	get_tree().change_scene_to_file("res://scenes/play/CharEquipment.tscn")
