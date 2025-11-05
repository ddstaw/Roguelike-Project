# UI/RaceInfo Script res://ui/scripts/raceHBoxContainer.gd
extends Node

var selected_button: TextureButton = null
var race_to_save: String = ""  # Variable to track the selected race

func _ready():
	# Connect signals for all race buttons and pass the correct button as an argument
	$humanslot.connect("pressed", Callable(self, "_on_race_button_pressed").bind($humanslot, "human"))
	$dwarfslot.connect("pressed", Callable(self, "_on_race_button_pressed").bind($dwarfslot, "dwarf"))
	$elfslot.connect("pressed", Callable(self, "_on_race_button_pressed").bind($elfslot, "elf"))
	$orcslot.connect("pressed", Callable(self, "_on_race_button_pressed").bind($orcslot, "orc"))

func _on_race_button_pressed(button: TextureButton, race: String):
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

	# Update the selected race and save to JSON
	race_to_save = race
	update_character_race_in_json(race_to_save)

# Function to update the race in the JSON file without erasing other values
func update_character_race_in_json(selected_race: String):
	var json_path = "user://saves/character_template.json"
	var file = FileAccess.open(json_path, FileAccess.READ_WRITE)

	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)

		if parse_result == OK:
			var data = json.data
			# Update the race inside the character key
			if data.has("character"):
				data["character"]["race"] = selected_race
			else:
				data["character"] = { "race": selected_race }

			# Reopen the file in write mode to overwrite its content
			file = FileAccess.open(json_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(data, "\t"))  # Save the updated data back to the file
			file.close()
		else:
			print("Failed to parse character_template.json:", parse_result)
	else:
		print("Failed to open character_template.json for reading.")

