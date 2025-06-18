extends Node

# Function to load the world name from current_world_name.JSON
func load_world_name() -> String:
	var file = FileAccess.open("user://worldgen/current_world_name.json", FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_data)

		if error == OK:
			var data_dict = json.data
			return data_dict.get("world_name", "Unknown World")
		else:
			print("Error parsing current_world_name.JSON")
	else:
		print("Error loading current_world_name.JSON")

	return "Unknown World"

# Function to save the world name to current_world_name.JSON
func save_world_name(world_name: String):
	var data_dict = { "world_name": world_name }
	var json = JSON.new()
	var json_string = json.stringify(data_dict, "\t")

	var file = FileAccess.open("user://worldgen/current_world_name.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("World name saved successfully: ", world_name)
	else:
		print("Error saving world name to current_world_name.JSON")

# Function to generate a random world name and save it
func generate_world_name():
	var file = FileAccess.open("res://data/world_name_components.json", FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_data)

		if error == OK:
			var data_dict = json.data
			var prefixes = data_dict["prefixes"]
			var suffixes = data_dict["suffixes"]
			var regions = data_dict["regions"]

			var prefix = prefixes[randi() % prefixes.size()]
			var suffix = suffixes[randi() % suffixes.size()]
			var region = regions[randi() % regions.size()]

			var world_name = "%s%s %s" % [prefix, suffix, region]
			save_world_name(world_name)
			update_world_name_label()
		else:
			print("Error parsing world name components JSON")
	else:
		print("Error loading world name components JSON")

# Function to update the label with the current world name
func update_world_name_label():
	var world_name = load_world_name()
	var label = get_node("../Control/WorldNameLabel")
	if label:
		label.text = world_name
		assign_font_styling(label)
	else:
		print("WorldNameLabel not found")

# Function to apply font styling to the world name label
func assign_font_styling(label: Label):
	var font = ResourceLoader.load("res://ui/FreeMonoBold.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 32)

	var color = Color(1, 1, 1)
	label.add_theme_color_override("font_color", color)
