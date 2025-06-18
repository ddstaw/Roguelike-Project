extends Node

# Array to track the selected buttons
var selected_buttons: Array = []
var max_selections: int = 3  # Maximum number of selections allowed
var skills_to_save: Array = []  # Array to track selected skills

func _ready():
	# Connect signals for all skill buttons and pass the correct button as an argument
	$Pslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Pslot, "Pskill"))
	$BFslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($BFslot, "BFskill"))
	$DSslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($DSslot, "DSskill"))
	$Bowslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Bowslot, "Bowskill"))
	$Firslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Firslot, "Firskill"))
	$Athslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Athslot, "Athskill"))
	$Skuslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Skuslot, "Skuskill"))
	$Acslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Acslot, "Acskill"))
	$Erslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Erslot, "Erskill"))
	$Frslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Frslot, "Frskill"))
	$Coslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Coslot, "Coskill"))
	$Taslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Taslot, "Taskill"))
	$Blslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Blslot, "Blslot"))
	$BoFlslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($BoFlslot, "BoFlskill"))
	$Meslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Meslot, "Meskill"))
	$Alslot.connect("pressed", Callable(self, "_on_skill_button_pressed").bind($Alslot, "Alskill"))

func _on_skill_button_pressed(button: TextureButton, skill: String):
	# If the button is already selected, deselect it
	if button in selected_buttons:
		selected_buttons.erase(button)
		button.modulate = Color(0.2, 0.2, 0.2)  # Muted color to indicate deselection
		skills_to_save.erase(skill)  # Remove the skill from the list
	else:
		# If less than max selections, select the button
		if selected_buttons.size() < max_selections:
			selected_buttons.append(button)
			button.modulate = Color(0.4, 0.6, 1.0)  # Blue color to indicate selection
			skills_to_save.append(skill)  # Add the skill to the list
		else:
			print("You can only select up to three skills.")

	# Mutate the other buttons based on the current selection state
	update_button_states()

	# Save the selected skills
	update_skills_in_json(skills_to_save)

func update_button_states():
	# Iterate over all children to update their states
	for child in get_children():
		if child is TextureButton:
			if child in selected_buttons:
				child.modulate = Color(0.4, 0.6, 1.0)  # Blue color for selected buttons
				child.disabled = false  # Ensure selected buttons remain interactive
			else:
				# Fade out unselected buttons only if the max selections are reached
				child.modulate = Color(0.2, 0.2, 0.2) if selected_buttons.size() >= max_selections else Color(1, 1, 1)
				child.disabled = selected_buttons.size() >= max_selections  # Disable unselected buttons if max selected

# Function to update the selected skills in the JSON file without erasing other values
func update_skills_in_json(selected_skills: Array):
	var json_path = "user://saves/character_template.json"
	var file = FileAccess.open(json_path, FileAccess.READ_WRITE)

	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)

		if parse_result == OK:
			var data = json.data

			# Ensure the skills dictionary exists in the JSON structure
			if not data.has("skills"):
				data["skills"] = {
					"pugilism": false,
					"bruteforce": false,
					"deftstriking": false,
					"bowmanship": false,
					"firearms": false,
					"athletics": false,
					"skullduggery": false,
					"acumen": false,
					"erudition": false,
					"frontiersmanship": false,
					"construction": false,
					"tailoring": false,
					"blacksmithing": false,
					"bowery": false,
					"alchemy": false,
					"metallurgy": false
				}

			# Set all skills to false initially to reset any previous selections
			for skill in data["skills"]:
				data["skills"][skill] = false

			# Update the skills dictionary with selected skills set to true
			for skill in selected_skills:
				if skill == "Pskill":
					data["skills"]["pugilism"] = true
				elif skill == "BFskill":
					data["skills"]["bruteforce"] = true
				elif skill == "DSskill":
					data["skills"]["deftstriking"] = true
				elif skill == "Bowskill":
					data["skills"]["bowmanship"] = true
				elif skill == "Firskill":
					data["skills"]["firearms"] = true
				elif skill == "Athskill":
					data["skills"]["athletics"] = true
				elif skill == "Skuskill":
					data["skills"]["skullduggery"] = true
				elif skill == "Acskill":
					data["skills"]["acumen"] = true
				elif skill == "Erskill":
					data["skills"]["erudition"] = true
				elif skill == "Frskill":
					data["skills"]["frontiersmanship"] = true
				elif skill == "Coskill":
					data["skills"]["construction"] = true
				elif skill == "Taskill":
					data["skills"]["tailoring"] = true
				elif skill == "Blslot":
					data["skills"]["blacksmithing"] = true
				elif skill == "BoFlskill":
					data["skills"]["bowery"] = true
				elif skill == "Meskill":
					data["skills"]["metallurgy"] = true
				elif skill == "Alskill":
					data["skills"]["alchemy"] = true

			# Reopen the file in write mode to overwrite its content
			file = FileAccess.open(json_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(data, "\t"))  # Save the updated data back to the file
			file.close()
		else:
			print("Failed to parse character_template.json:", parse_result)
	else:
		print("Failed to open character_template.json for reading.")
