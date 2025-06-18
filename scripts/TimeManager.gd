extends Node

# Flavor file paths based on time of day
const MORNING_FLAVOR = "res://assets/worldmap-graphics/flavor/mo.png"
const AFTERNOON_FLAVOR = "res://assets/worldmap-graphics/flavor/af.png"
const EVENING_FLAVOR = "res://assets/worldmap-graphics/flavor/ee.png"
const LATE_NIGHT_FLAVOR = "res://assets/worldmap-graphics/flavor/le.png"
# ⬇️ Flavor file paths for Local Map (NEW!)
const LOCAL_MORNING_FLAVOR = "res://assets/localmap-graphics/ui-buttons/mo.png"
const LOCAL_AFTERNOON_FLAVOR = "res://assets/localmap-graphics/ui-buttons/af.png"
const LOCAL_EVENING_FLAVOR = "res://assets/localmap-graphics/ui-buttons/ee.png"
const LOCAL_LATE_NIGHT_FLAVOR = "res://assets/localmap-graphics/ui-buttons/le.png"


# Function to print the time and date from the JSON file
func print_time_and_date():
	var time_data = LoadHandlerSingleton.get_time_and_date()  # Load the time and date data
	if time_data != null:
		var gametime = time_data.get("gametime", "Unknown time")
		var gamedate = time_data.get("gamedate", "Unknown date")
		print("Game Time: ", gametime)
		print("Game Date: ", gamedate)
	else:
		print("Failed to load time and date.")

func pass_two_hours():
	var time_data = LoadHandlerSingleton.get_time_and_date()  # Load the time and date data

	if time_data != null:
		var time_string = time_data["gametime"]  # Get the current game time (e.g., "6:00 AM")
		
		# Use the helper function to update the time
		var new_time = TimeManager.update_time_by_hours(time_string, 2)
		time_data["gametime"] = new_time

		# Update miltime based on the new gametime
		time_data["miltime"] = convert_to_military_time(new_time)
		
		# Save the updated time data
		save_time_data(time_data)
		
		# Immediately update gametime flavor after changing time
		update_gametime_flavor2(time_data)

		# Update the displayed time in the UI
		var world_map_control = get_node("/root/WorldMapTravel")  # Adjust the node path if necessary
		if world_map_control:
			world_map_control.update_time_label()  # Update the label after the time change
		else:
			print("Error: WorldMapTravel node not found.")

func convert_to_military_time(time_string: String) -> String:
	# Remove any leading/trailing whitespace
	time_string = time_string.strip_edges()
	
	# Check if the time string has an AM/PM suffix
	if time_string.ends_with("AM"):
		var time_parts = time_string.substr(0, time_string.length() - 2).split(":")
		var hour = int(time_parts[0])
		var minute = int(time_parts[1])
		
		# Format hour to 2 digits, ensuring AM times are in 24-hour format
		if hour == 12:  # Midnight case
			return "0000"
		else:
			return str(hour).pad_zeros(2) + str(minute).pad_zeros(2)

	elif time_string.ends_with("PM"):
		var time_parts = time_string.substr(0, time_string.length() - 2).split(":")
		var hour = int(time_parts[0])
		var minute = int(time_parts[1])
		
		# Convert PM times
		if hour == 12:  # Noon case
			return "1200"
		else:
			return str(hour + 12).pad_zeros(2) + str(minute).pad_zeros(2)

	return ""  # Return empty string for invalid time formats

# Function to save the updated time data
func save_time_data(time_data: Dictionary) -> void:
	var path = LoadHandlerSingleton.get_save_file_path() + "globaldata/timedate" + str(LoadHandlerSingleton.get_save_slot()) + ".json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	
	if file != null:
		var json_string = JSON.stringify(time_data, "\t", true)  # Save data with indentation for formatting
		file.store_string(json_string)
		file.close()
		print("Time data saved successfully to path: ", path)
	else:
		print("Error: Unable to save time data.")
		
# Helper function to get the time file path (depending on the save slot)
func get_time_file_path() -> String:
	return LoadHandlerSingleton.get_save_file_path() + "globaldata/timedate" + str(LoadHandlerSingleton.get_save_slot()) + ".json"

func update_time_by_hours(current_time_string: String, hours_to_add: int) -> String:
	var time_parts = current_time_string.strip_edges().split(" ")
	var period = time_parts[1]  # "AM" or "PM"
	var time_digits = time_parts[0].split(":")
	
	var current_hour = int(time_digits[0])
	var current_minute = int(time_digits[1])
	
	# Add hours and handle overflow into the next period
	current_hour += hours_to_add
	
	# Normalize hours into a 12-hour format and determine new period
	while current_hour >= 12:
		if current_hour > 12:
			current_hour -= 12
		
		# Toggle AM/PM when hitting 12
		if current_hour == 12:
			period = "PM" if period == "AM" else "AM"
			break  # Exit after toggling to prevent infinite loop

	# Handle the case when current_hour equals 12 (noon)
	if current_hour == 12:
		# If we are at noon, keep period as is
		pass
	elif current_hour == 0:
		current_hour = 12  # Midnight should be displayed as 12 AM

	# Ensure two-digit minutes
	var padded_minute = str(current_minute).pad_zeros(2)

	# Construct final time string with space before AM/PM
	return str(current_hour) + ":" + padded_minute + " " + period


func update_gametime_flavor2(time_data: Dictionary) -> void:
	print("update_gametime_flavor called")

	var military_time = time_data["miltime"]
	print("Current military time:", military_time)

	# Extract hours from military time
	var hour = int(military_time.substr(0, 2))

	# Determine flavor paths
	var flavor_image_path = ""
	var local_flavor_image_path = ""
	var gametimetype = ""

	if hour >= 5 and hour < 12:
		flavor_image_path = MORNING_FLAVOR
		local_flavor_image_path = LOCAL_MORNING_FLAVOR
		gametimetype = "Morning"
	elif hour >= 12 and hour < 17:
		flavor_image_path = AFTERNOON_FLAVOR
		local_flavor_image_path = LOCAL_AFTERNOON_FLAVOR
		gametimetype = "Afternoon"
	elif hour >= 17 and hour < 23:
		flavor_image_path = EVENING_FLAVOR
		local_flavor_image_path = LOCAL_EVENING_FLAVOR
		gametimetype = "Evening"
	else:
		flavor_image_path = LATE_NIGHT_FLAVOR
		local_flavor_image_path = LOCAL_LATE_NIGHT_FLAVOR
		gametimetype = "Late Night"

	print("Flavor image path determined:", flavor_image_path)

	# Check if anything has changed
	var changed := false

	if time_data.get("gametimeflavor", "") != flavor_image_path:
		time_data["gametimeflavor"] = flavor_image_path
		changed = true
		print("Flavor image updated successfully to:", flavor_image_path)

	if time_data.get("gametimeflavorlocal", "") != local_flavor_image_path:
		time_data["gametimeflavorlocal"] = local_flavor_image_path
		changed = true
		print("Local flavor image updated successfully to:", local_flavor_image_path)

	if time_data.get("gametimetype", "") != gametimetype:
		time_data["gametimetype"] = gametimetype
		changed = true
		print("Gametimetype updated successfully to:", gametimetype)

	# Update worldmap UI if needed
	if changed:
		var world_map_control = get_node("/root/WorldMapTravel")
		if world_map_control:
			world_map_control.update_gametime_flavor()
		else:
			print("Error: WorldMapTravel node not found.")

		save_time_data(time_data)
	else:
		print("No update needed for flavor image or gametimetype.")

# Adjusted function to return total minutes without conversion
func get_total_minutes(hour: int, minute: int, period: String) -> int:
	if period == "PM" and hour != 12:
		hour += 12  # Convert PM hours to 24-hour format
	elif period == "AM" and hour == 12:
		hour = 0  # Midnight (12 AM) is 0 hours in 24-hour format
	return hour * 60 + minute  # Return total minutes

func pass_minutes(mins: int):
	var time_data = LoadHandlerSingleton.get_time_and_date()
	if time_data == null:
		print("⛔ Cannot pass minutes: time data missing.")
		return

	var current_time = time_data["gametime"]
	var time_parts = current_time.strip_edges().split(" ")
	var period = time_parts[1]  # "AM" or "PM"
	var hour_min = time_parts[0].split(":")
	var hour = int(hour_min[0])
	var minute = int(hour_min[1])

	# Convert to 24-hour format
	if period == "PM" and hour != 12:
		hour += 12
	elif period == "AM" and hour == 12:
		hour = 0

	# Add minutes
	var total_minutes = hour * 60 + minute + mins
	hour = (total_minutes / 60) % 24
	minute = total_minutes % 60

	# Convert back to 12-hour format
	var new_period = "AM"
	if hour >= 12:
		new_period = "PM"
	if hour > 12:
		hour -= 12
	elif hour == 0:
		hour = 12

	var new_time = str(hour) + ":" + str(minute).pad_zeros(2) + " " + new_period
	time_data["gametime"] = new_time
	time_data["miltime"] = convert_to_military_time(new_time)

	update_gametime_flavor2(time_data)
	save_time_data(time_data)


func _ready():
	# Initialization code only if needed, but no automatic printing
	pass
