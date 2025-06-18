extends Button

func _ready():
	print("Button script ready")  # Ensures the script is running

func _on_pressed():
	print("Back button pressed")  # Debug print
	# Call the SceneManager to return to the play scene
	SceneManager.return_to_play_scene()
