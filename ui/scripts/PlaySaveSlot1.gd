extends Button

func _ready():
	# Connect the pressed signal to the button press function
	connect("pressed", Callable(self, "_on_Button_pressed"))

func _on_Button_pressed():
	var save_slot = 1  # Example: SaveSlot1 (Update accordingly for other buttons)
	var char_active_path = "user://saves/save" + str(save_slot) + "/world/char_active" + str(save_slot) + ".json"

	# Check the is_active status in char_active1.json
	var file_char_active = FileAccess.open(char_active_path, FileAccess.READ)
	if file_char_active:
		var json_data = file_char_active.get_as_text()
		var json = JSON.new()
		var error = json.parse(json_data)
		file_char_active.close()

		if error == OK:
			var is_active = json.data.get("is_active", false)

			if is_active:
				# Load directly into the game if character is active (commented out)
				# load_game()
				print("Character is active. Would load game here.")
			else:
				# Prompt to create a new character if not active
				show_character_creation_prompt(save_slot)
		else:
			print("Error parsing char_active.json")
	else:
		print("Error opening char_active.json")

# Function to load directly into the game (commented out)
# func load_game():
#     get_tree().change_scene("res://path_to_your_game_scene.tscn")

# Function to prompt the player to create a new character
func show_character_creation_prompt(save_slot):
	# Create a confirmation dialog
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Create a new character?"
	dialog.title = "No Character"  # Set the prompt text
	add_child(dialog)

	# Connect the confirmed signal to create a new character
	dialog.connect("confirmed", Callable(self, "_on_create_new_character_confirmed").bind(save_slot))
	dialog.connect("canceled", Callable(self, "_on_create_new_character_canceled"))
	
	# Show the dialog
	dialog.popup_centered()

	# Access the content container (VBoxContainer or similar) and set its min size

	dialog.popup_centered()  # Re-center the dialog after resizing

# Function to handle "Yes" in the dialog (Create a new character)
func _on_create_new_character_confirmed(save_slot):
	# Update the load_handler.json
	var handler_file_path = "user://saves/load_handler.json"
	var save_file_path = "user://saves/save" + str(save_slot) + "/"
	
	var file = FileAccess.open(handler_file_path, FileAccess.WRITE)
	if file:
		var json_data = {
			"selected_save_slot": save_slot,
			"save_file_path": save_file_path
		}
		file.store_string(JSON.stringify(json_data))
		file.close()

	# Change to the character creation screen
	get_tree().change_scene_to_file("res://scenes/CharacterCreation.tscn")

# Function to handle "No" or cancel in the dialog
func _on_create_new_character_canceled():
	print("Character creation canceled.")
	# Additional logic for handling "No" if needed
