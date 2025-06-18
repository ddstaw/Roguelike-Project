extends Node

var selected_button: TextureButton = null
var faith_to_save: String = ""  # Variable to track the selected faith

func _ready():
	# Connect signals for all faith buttons and pass the correct button as an argument
	$Orthslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Orthslot, "Orthodox Dogmatist"))
	$Refoslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Refoslot, "Pious Reformationist"))
	$Fundslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Fundslot, "Fundamentalist Zealot"))
	$Sataslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Sataslot, "Sinister Cultist"))
	$Estoslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Estoslot, "Guided By The Void"))
	$Oldwslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Oldwslot, "Follower of The Old Ways"))
	$Rexmslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Rexmslot, "Disciple of Rex Mundi"))
	$Godlslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Godlslot, "Godless"))

func _on_faith_button_pressed(button: TextureButton, faith: String):
	# Deselect the previous button
	if selected_button:
		selected_button.modulate = Color(0.2, 0.2, 0.2) # Muted color
		selected_button.disabled = false # Ensure it stays interactive

	# Select the new button
	selected_button = button
	selected_button.modulate = Color(1, 1, 1) # Normal color
	selected_button.disabled = false # Ensure it stays interactive

	# Mutate other buttons
	for child in get_children():
		if child != selected_button and child is TextureButton:
			child.modulate = Color(0.2, 0.2, 0.2) # Muted color

	# Update the selected faith and save to JSON
	faith_to_save = faith
	update_character_faith_in_json(faith_to_save)

# Function to update the faith in the JSON file without erasing other values
func update_character_faith_in_json(selected_faith: String):
	var json_path = "user://saves/character_template.json"
	var file = FileAccess.open(json_path, FileAccess.READ_WRITE)

	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)

		if parse_result == OK:
			var data = json.data
			# Update the faith inside the character key
			if data.has("character"):
				data["character"]["faith"] = selected_faith
			else:
				data["character"] = { "faith": selected_faith }

			# Reopen the file in write mode to overwrite its content
			file = FileAccess.open(json_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(data, "\t"))  # Save the updated data back to the file
			file.close()
		else:
			print("Failed to parse character_template.json:", parse_result)
	else:
		print("Failed to open character_template.json for reading.")

