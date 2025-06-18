extends Button

# Path to the character template JSON file
var character_template_path = "user://saves/character_template.json"

# Path to the Character Background Scene
var background_scene_path = "res://scenes/CharacterBackground.tscn"

func _ready():
	# Correct way to connect button signal in Godot 4.x
	connect("pressed", Callable(self, "_on_button_pressed"))
	print("Button signal connected.")

# Function that runs when the button is pressed
func _on_button_pressed():
	print("Button pressed! Starting aptitude determination and scene change...")

	# Load the character template data
	var character_data = load_character_template(character_template_path)
	if character_data:
		# Calculate aptitudes based on the current skills and magicktech
		var aptitudes = calculate_aptitudes(character_data)
		# Update the aptitudes in the character data
		character_data["aptitudes"]["magic"] = aptitudes["magic"]
		character_data["aptitudes"]["technology"] = aptitudes["technology"]

		# Save the updated character data back to the JSON file
		if save_character_template(character_template_path, character_data):
			print("Updated aptitudes:", aptitudes)
		else:
			print("Error: Failed to save updated aptitudes.")

		# Attempt to change the scene to CharacterBackground.tscn after saving the data
		if ResourceLoader.exists(background_scene_path):
			var scene_change_result = get_tree().change_scene_to_file(background_scene_path)
			if scene_change_result != OK:
				print("Error: Failed to change scene. Scene change result:", scene_change_result)
			else:
				print("Scene change successful.")
		else:
			print("Error: Scene file does not exist at path:", background_scene_path)
	else:
		print("Error: Could not load character data.")

# Function to load the character template JSON file
func load_character_template(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)
		file.close()

		if parse_result == OK:
			print("Successfully loaded character data.")
			return json.data
		else:
			print("JSON parsing error:", json.error_string)
			return {}
	else:
		print("Failed to open character template file:", file_path)
		return {}

# Function to save the updated character template JSON file
func save_character_template(file_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json = JSON.new()
		file.store_string(json.stringify(data, "\t", true))
		file.close()
		print("Successfully saved updated character data.")
		return true
	else:
		print("Failed to open file for writing:", file_path)
		return false

# Function to calculate aptitudes based on magicktech and skills
func calculate_aptitudes(character_data: Dictionary) -> Dictionary:
	# Updated magic skills list to include fulm and cyro
	var magic_skills = ["pyro", "vito", "necr", "thau", "ench", "glam", "veno", "fulm", "cyro"]
	var technology_skills = ["robo", "guns", "tink", "chem", "exp"]

	var magic_aptitude = 0
	var technology_aptitude = 0

	# Check magicktech skills
	for skill in character_data["magicktech"]:
		if character_data["magicktech"][skill] == true:
			if skill in magic_skills:
				magic_aptitude += 1
			elif skill in technology_skills:
				technology_aptitude += 1

	# Debug print statements to confirm correct aptitude values
	print("Magic Aptitude:", magic_aptitude, "Technology Aptitude:", technology_aptitude)

	return {"magic": magic_aptitude, "technology": technology_aptitude}
