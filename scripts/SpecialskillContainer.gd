#UI/SkillContainer Script res://scripts/SpecialskillContainer.gd
extends Node

# Array to track the selected buttons
var selected_buttons: Array = []
var max_selections: int = 2  # Maximum number of selections allowed
var magicktech_to_save: Array = []  # Array to track selected magicktech

func _ready():
	# Connect signals for all skill buttons and pass the correct button as an argument
	$MagickContainer1/Pyroslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($MagickContainer1/Pyroslot, "Pyroskill"))
	$MagickContainer1/Cyroslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($MagickContainer1/Cyroslot, "Cyroskill"))
	$MagickContainer1/Fulslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($MagickContainer1/Fulslot, "Fulskill"))
	$MagickContainer1/Venslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($MagickContainer1/Venslot, "Venskill"))
	$MagickContainer2/Glamslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($MagickContainer2/Glamslot, "Glamskill"))
	$MagickContainer2/Necslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($MagickContainer2/Necslot, "Necskill"))
	$MagickContainer2/Vitoslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($MagickContainer2/Vitoslot, "Vitoskill"))
	$MagickContainer2/Enslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($MagickContainer2/Enslot, "Enskill"))
	$TechContainer/Gunslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($TechContainer/Gunslot, "Gunskill"))
	$TechContainer/Tinkslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($TechContainer/Tinkslot, "Tinkskill"))
	$TechContainer/Chemslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($TechContainer/Chemslot, "Chemskill"))
	$TechContainer/Expslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($TechContainer/Expslot, "Expskill"))
	$TechContainer/Robslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($TechContainer/Robslot, "Robskill"))

func _on_skill_button_pressed(button: TextureButton, skill: String):
	# If the button is already selected, deselect it
	if button in selected_buttons:
		selected_buttons.erase(button)
		button.modulate = Color(1, 1, 1)  # Reset color to normal
		magicktech_to_save.erase(skill)  # Remove the skill from the list
	else:
		# If less than max selections, select the button
		if selected_buttons.size() < max_selections:
			selected_buttons.append(button)
			button.modulate = Color(0.6, 0.6, 1)  # Blue tint to indicate selection
			magicktech_to_save.append(skill)  # Add the skill to the list
		else:
			print("You can only select up to two magicktech.")

	# Update the button states visually
	update_button_states()

	# Save the selected magicktech
	update_magicktech_in_json(magicktech_to_save)

func update_button_states():
	# Iterate over all relevant children to update their states
	var buttons = [
		$MagickContainer1/Pyroslot, $MagickContainer1/Cyroslot, $MagickContainer1/Fulslot, $MagickContainer1/Venslot,
		$MagickContainer2/Glamslot, $MagickContainer2/Necslot, $MagickContainer2/Vitoslot, $MagickContainer2/Enslot,
		$TechContainer/Gunslot, $TechContainer/Tinkslot, $TechContainer/Chemslot, $TechContainer/Expslot, $TechContainer/Robslot
	]

	for button in buttons:
		if button in selected_buttons:
			button.modulate = Color(0.6, 0.6, 1)  # Blue tint for selected buttons
		else:
			# Mute unselected buttons significantly when the max selections are reached
			button.modulate = Color(0.3, 0.3, 0.3) if selected_buttons.size() >= max_selections else Color(1, 1, 1)

# Function to update the selected magicktech in the JSON file without erasing other values
func update_magicktech_in_json(selected_magicktech: Array):
	var json_path = "user://saves/character_template.json"
	var file = FileAccess.open(json_path, FileAccess.READ_WRITE)

	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)

		if parse_result == OK:
			var data = json.data

			# Ensure the magicktech dictionary exists in the JSON structure
			if not data.has("magicktech"):
				data["magicktech"] = {
					"chem": false,
					"cyro": false,
					"ench": false,
					"exp": false,
					"fulm": false,
					"glam": false,
					"guns": false,
					"necr": false,
					"pyro": false,
					"robo": false,
					"thau": false,
					"tink": false,
					"veno": false,
					"vito": false,
					"wand": false
				}

			# Set all magicktech to false initially to reset any previous selections
			for magicktech in data["magicktech"]:
				data["magicktech"][magicktech] = false

			# Update the magicktech dictionary with selected magicktech set to true
			for magicktech in selected_magicktech:
				if magicktech == "Pyroskill":
					data["magicktech"]["pyro"] = true
				elif magicktech == "Cyroskill":
					data["magicktech"]["cyro"] = true
				elif magicktech == "Fulskill":
					data["magicktech"]["fulm"] = true
				elif magicktech == "Venskill":
					data["magicktech"]["veno"] = true
				elif magicktech == "Glamskill":
					data["magicktech"]["glam"] = true
				elif magicktech == "Necskill":
					data["magicktech"]["necr"] = true
				elif magicktech == "Vitoskill":
					data["magicktech"]["vito"] = true
				elif magicktech == "Enskill":
					data["magicktech"]["ench"] = true
				elif magicktech == "Thasskill":
					data["magicktech"]["thau"] = true
				elif magicktech == "Wandskill":
					data["magicktech"]["wand"] = true
				elif magicktech == "Gunskill":
					data["magicktech"]["guns"] = true
				elif magicktech == "Tinkskill":
					data["magicktech"]["tink"] = true
				elif magicktech == "Chemskill":
					data["magicktech"]["chem"] = true
				elif magicktech == "Expskill":
					data["magicktech"]["exp"] = true
				elif magicktech == "Robskill":
					data["magicktech"]["robo"] = true

			# Reopen the file in write mode to overwrite its content
			file = FileAccess.open(json_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(data, "\t"))  # Save the updated data back to the file
			file.close()
		else:
			print("Failed to parse character_template.json:", parse_result)
	else:
		print("Failed to open character_template.json for reading.")
