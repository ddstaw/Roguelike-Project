# NameInput Script res://ui/scripts/NameEntry.gd
extends LineEdit

# Path to the JSON file
@export var save_path = "user://saves/character_template.json"

# Store the original colors for resetting
var original_text_color = null
var original_border_color = null
var last_known_name = ""  # Track the last known name to detect changes

func _ready():
	connect("text_submitted", Callable(self, "_on_line_edit_text_entered"))

	# Save the original colors to reset after flashing
	original_text_color = self.get_theme_color("font_color", "LineEdit")
	original_border_color = self.get_theme_color("border_color", "LineEdit")

	# Initialize the last known name and start checking for changes
	last_known_name = get_current_name()
	check_name_update()  # Start the check function

func _on_line_edit_text_entered(new_text: String):
	var file = FileAccess.open(save_path, FileAccess.READ_WRITE)
	var json = JSON.new()
	var existing_data = {}

	# Read the existing data if the file is accessible
	if file:
		var data = file.get_as_text()
		var error = json.parse(data)
		if error == OK:
			existing_data = json.data
		file.close()
	else:
		print("Failed to open file for reading: ", save_path)
	
	# Update the character name inside the character key without altering other fields
	if existing_data.has("character"):
		existing_data["character"]["name"] = new_text
	else:
		existing_data["character"] = { "name": new_text }

	# Open the file for writing without clearing existing fields
	file = FileAccess.open(save_path, FileAccess.WRITE_READ)
	if file:
		# Rewind the file to the beginning before overwriting it
		file.seek(0)
		file.store_string(JSON.stringify(existing_data, "\t"))  # Save the updated data back to the file
		file.close()

		# Change text color to green as feedback
		self.add_theme_color_override("font_color", Color(0, 1, 0))  # Green color

		# Optional: Flash the background to indicate a successful save
		flash_background()
	else:
		print("Failed to open file for writing: ", save_path)

# Function to flash the border color briefly
func flash_background():
	var flash_color = Color(0, 1, 0, 0.5)  # Green color with some transparency

	# Briefly change the border color and reset it after a delay
	self.add_theme_color_override("border_color", flash_color)
	await get_tree().create_timer(0.5).timeout
	self.add_theme_color_override("border_color", original_border_color)

	# Reset text color to original
	self.add_theme_color_override("font_color", original_text_color)

# Check periodically if the name in the JSON has changed
func check_name_update():
	# Read the current name from the JSON
	var current_name = get_current_name()
	if current_name != last_known_name:
		last_known_name = current_name
		self.text = current_name  # Update the LineEdit text with the new name

	# Continue checking every 0.5 seconds
	await get_tree().create_timer(0.5).timeout
	check_name_update()

# Helper function to get the current name from the JSON
func get_current_name() -> String:
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK and json.data.has("character"):
			file.close()
			return json.data["character"].get("name", "")  # Return the name, defaulting to an empty string if not found
	file.close()
	return ""  # Default to an empty string if the JSON couldn't be read
