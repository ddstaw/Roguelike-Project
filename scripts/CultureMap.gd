extends Control

# Function to apply font styling to the world name label
func apply_font_styling(label: Label):
	var font = ResourceLoader.load("res://ui/FreeMonoBold.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 32)

	var color = Color(1, 1, 1)
	label.add_theme_color_override("font_color", color)
	label.visible = true  # Ensure the label is visible

# Function to apply font styling to the log messages
func apply_font_styling_for_log(label: Label):
	var font = ResourceLoader.load("res://ui/FreeMonoBold.ttf")
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", 16)  # Smaller font size for the log

	var color = Color(1, 1, 1)
	label.add_theme_color_override("font_color", color)
	label.visible = true  # Ensure the label is visible

	# Ensure the label uses the full width of its container
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Allow the label to expand horizontally

	# Set a max width for the label (this should be the width of the panel)
	label.custom_minimum_size = Vector2(300, 0)  # Example width, adjust as needed

# Function to update the world name label from the JSON file
func update_world_name_label():
	var file = FileAccess.open("user://worldgen/playing_map.json", FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_data)
		
		if error == OK:
			var data_dict = json.data[0]
			if data_dict.has("world_name"):
				var world_name = data_dict["world_name"]
				var label = get_node("WorldNameLabel")
				if label:
					label.text = world_name
					apply_font_styling(label)
					print("World name updated to: ", world_name)
				else:
					print("WorldNameLabel not found.")
			else:
				print("World name not found in the data dictionary.")
		else:
			print("Error parsing JSON for world name.")
	else:
		print("Error loading world name JSON file.")

# Function to add a message to the log
func add_message_to_log(message_text: String):
	var log_vbox = get_node("MessageLogControl/MessageLogPanel/MessageLogScroll/MessageLogVBox")
	if log_vbox:
		var new_message_label = Label.new()
		new_message_label.text = message_text
		apply_font_styling_for_log(new_message_label)
		log_vbox.add_child(new_message_label)
		print("Added message to log: ", message_text)
	else:
		print("MessageLogVBox not found.")

# Function to load the map and update the world name
func load_map():
	add_message_to_log("Loading map...")
	await get_tree().process_frame  # Give time for the map to load

	# Get the MapControl/WorldTextureRect node and call init_map_display on it
	var map_display = get_node("MapControl/SubViewportContainer/SubViewport/WorldTextureRect")
	
	if map_display:
		map_display.init_map_display()
	else:
		print("WorldTextureRect node not found!")

	update_world_name_label()
	add_message_to_log("Map loaded - ready to place settlements")

# Function to handle the Proceed button press
func _on_ProceedButton_pressed():
	# Code to proceed with placing settlements (you can implement this next)
	print("Proceeding with settlement placement...")
	# Hide the window after proceeding
	get_node("PlaceSettlementsWindow").visible = false

# Function to handle the Back to Map Generator button press
func _on_BackToMapGen_pressed():
	# Code to go back to map generator (you can implement this next)
	print("Returning to the map generator...")
	# Hide the window after returning
	get_node("PlaceSettlementsWindow").visible = false

# Function to display the MapGeneratedWindow after settlement placement is complete
func show_map_generated_window():
	var map_generated_window = get_node("MapGeneratedWindow")
	if map_generated_window:
		map_generated_window.visible = true
		print("MapGeneratedWindow is now visible.")
	else:
		print("MapGeneratedWindow node not found!")

# Defer the map loading to ensure nodes are ready
func _ready():
	call_deferred("load_map")

	var window = get_node("PlaceSettlementsWindow")
	if window:
		var vbox = window.get_node("VBoxContainer")
		if vbox:
			vbox.get_node("ProceedButton").connect("pressed", Callable(self, "_on_ProceedButton_pressed"))
			vbox.get_node("BackToMapGen").connect("pressed", Callable(self, "_on_BackToMapGen_pressed"))
		else:
			print("VBoxContainer node not found!")
	else:
		print("PlaceSettlementsWindow node not found!")

# Ensure MapGeneratedWindow is hidden at the start
	var map_generated_window = get_node("MapGeneratedWindow")
	if map_generated_window:
		map_generated_window.visible = false
	else:
		print("MapGeneratedWindow node not found!")
