extends Button

# Declare the signal properly
signal name_updated

# Load name data from JSON
var name_data: Dictionary = {}

func _ready():
	load_name_data()
	connect("pressed", Callable(self, "_on_randomize_pressed"))

# Load the name data from the JSON file
func load_name_data():
	var file = FileAccess.open("res://data/player_name_components.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			name_data = json.data
		else:
			print("Error parsing name data JSON:", error)
		file.close()
	else:
		print("Error: Could not open name data JSON file.")

# Function to handle random name generation and update JSON
func _on_randomize_pressed():
	var current_race = get_current_race()
	var current_sex = get_current_sex()
	var key = current_race + " " + current_sex

	# Check if key exists in name_data and generate random names
	if key in name_data:
		var first_names = name_data[key][0].get("First", [])
		var last_prefix = name_data[key][0].get("Last Prefix", [])
		var last_suffix = name_data[key][0].get("Last Suffix", [])

		if first_names.size() > 0 and last_prefix.size() > 0 and last_suffix.size() > 0:
			var random_first = first_names[randi() % first_names.size()]
			var random_last = last_prefix[randi() % last_prefix.size()] + last_suffix[randi() % last_suffix.size()]

			# Construct the random name
			var random_name = random_first + " " + random_last

			# Update the JSON with the random name
			update_name_in_json(random_name)
			emit_signal("name_updated")  # Signal that the name was updated
		else:
			print("Error: Name data arrays are empty for key:", key)
	else:
		print("Error: Name data not found for key:", key)

# Retrieve the current race from the JSON file
func get_current_race() -> String:
	var file = FileAccess.open("user://saves/character_template.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK and json.data.has("character"):
			var race = json.data["character"].get("race", "human")  # Default to "human"
			file.close()
			return race
	print("Error reading race from JSON.")
	return "human"

# Retrieve the current sex from the JSON file
func get_current_sex() -> String:
	var file = FileAccess.open("user://saves/character_template.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK and json.data.has("character"):
			var sex = json.data["character"].get("sex", "male")  # Default to "male"
			file.close()
			return sex
	print("Error reading sex from JSON.")
	return "male"

# Update the JSON with the generated name
func update_name_in_json(new_name: String):
	var json_path = "user://saves/character_template.json"
	var file = FileAccess.open(json_path, FileAccess.READ_WRITE)
	
	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)

		if parse_result == OK:
			var data = json.data
			if data.has("character"):
				data["character"]["name"] = new_name
			else:
				data["character"] = { "name": new_name }

			# Close the file and reopen in WRITE mode to overwrite the content
			file.close()
			file = FileAccess.open(json_path, FileAccess.WRITE)  # Reopen to overwrite content
			file.store_string(JSON.stringify(data, "\t"))  # Save the updated data back to the file
			file.close()
		else:
			print("Failed to parse character_template.json:", parse_result)
	else:
		print("Failed to open character_template.json for updating.")

# Seed random number generator
func _init():
	randomize()
