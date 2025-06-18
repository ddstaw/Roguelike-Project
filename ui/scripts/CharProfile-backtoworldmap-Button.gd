extends Button

func _ready():
	print("Button script ready")  # Ensures the script is running

# This function is called when the back button is pressed
func _on_chrp_back_button_pressed():
	print("Back button pressed")  # Debug print
	# Call the SceneManager to return to the play scene
	SceneManager.return_to_play_scene()
