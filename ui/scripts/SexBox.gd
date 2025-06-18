extends Node

var selected_button: TextureButton = null
var sex_to_save: String = ""

func _ready():
	# Connect signals for sex selection buttons and pass the correct values
	$malebutton.connect("pressed", Callable(self, "_on_sex_button_pressed").bind($malebutton, "male"))
	$femalebutton.connect("pressed", Callable(self, "_on_sex_button_pressed").bind($femalebutton, "female"))

func _on_sex_button_pressed(button: TextureButton, sex: String):
	_handle_button_selection(button)
	sex_to_save = sex
	update_sex_in_json(sex_to_save)

func _handle_button_selection(button: TextureButton):
	# Handles selection and deselection visuals for the buttons
	if selected_button:
		selected_button.modulate = Color(0.5, 0.5, 0.5)  # Muted color
		selected_button.disabled = false

	selected_button = button
	selected_button.modulate = Color(1, 1, 1)  # Normal color
	selected_button.disabled = false

	# Mutate other buttons
	for child in get_children():
		if child != selected_button and child is TextureButton:
			child.modulate = Color(0.5, 0.5, 0.5)  # Muted color

# Function to update the sex field in character_template.json without erasing other data
func update_sex_in_json(sex_value: String):
	var json_path = "user://saves/character_template.json"
	var file = FileAccess.open(json_path, FileAccess.READ)

	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)
		file.close()  # Close after reading

		if parse_result == OK:
			var data = json.data
			# Update the sex inside the character key
			if data.has("character"):
				data["character"]["sex"] = sex_value
			else:
				data["character"] = { "sex": sex_value }

			# Reopen the file in write mode to overwrite its content
			file = FileAccess.open(json_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(data, "\t"))  # Save the updated data back to the file
			file.close()
		else:
			print("Failed to parse character_template.json:", parse_result)
	else:
		print("Failed to open character_template.json for reading.")
