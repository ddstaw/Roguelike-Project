extends TextureRect

var portraits = []  # Array to store the paths of portraits
var current_index = 0  # Current index of the portrait being displayed

@onready var change_port_arrow = $UI/ChangePortArrow  # Update this path if necessary

# Function to load portraits based on race and sex
func load_portraits(race: String, sex: String):
	var path = "res://ui/p/%s/%s/" % [race, sex]
	portraits.clear()  # Clear the current list of portraits

	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()  # Start listing the directory contents
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".png"):
				portraits.append(path + file_name)  # Add the portrait path to the array
			file_name = dir.get_next()
		dir.list_dir_end()  # End directory listing
	else:
		print("Failed to open directory: ", path)

	# Display the first portrait if available
	if portraits.size() > 0:
		self.texture = load(portraits[0])
		current_index = 0
	else:
		self.texture = null  # Clear the texture if no portraits are found
		current_index = 0

# Function to cycle to the next portrait
func cycle_next_portrait():
	if portraits.size() > 0:
		current_index = (current_index + 1) % portraits.size()  # Loop through the portraits
		self.texture = load(portraits[current_index])
	else:
		print("No portraits available to cycle through.")
