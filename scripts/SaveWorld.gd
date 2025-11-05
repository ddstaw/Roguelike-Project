# res://scenes/SaveWorld.tscn Parent script - res://scripts/SaveWorld.gd
extends Node2D

# Variables to hold the button nodes
var save_slot_button_1: Button
var save_slot_button_2: Button
var save_slot_button_3: Button

func _ready():
	# Directly assign the buttons using their node paths
	save_slot_button_1 = get_node("SaveSlot1")
	save_slot_button_2 = get_node("SaveSlot2")
	save_slot_button_3 = get_node("SaveSlot3")
	refresh_save_slot_info()

	# Load and display information for each save slot
	load_save_slot_info(save_slot_button_1, "user://saves/save1/world/basemapdata1.json")
	load_save_slot_info(save_slot_button_2, "user://saves/save2/world/basemapdata2.json")
	load_save_slot_info(save_slot_button_3, "user://saves/save3/world/basemapdata3.json")

func refresh_save_slot_info():
	# Load and update the save slot information
	load_save_slot_info(get_node("SaveSlot1"), "user://saves/save1/world/basemapdata1.json")
	load_save_slot_info(get_node("SaveSlot2"), "user://saves/save2/world/basemapdata2.json")
	load_save_slot_info(get_node("SaveSlot3"), "user://saves/save3/world/basemapdata3.json")

func load_save_slot_info(button: Button, file_path: String) -> void:
	# Load the JSON data for the save slot
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		var json = JSON.new()  # Create an instance of the JSON class
		var error = json.parse(json_data)
		file.close()

		# Check if parsing was successful
		if error == OK:
			var data = json.data
			if data.size() > 0:
				var world_info = data[0]  # Access the first element of the array
				var world_name = world_info.get("world_name", "Unknown World")
				var date_created = world_info.get("date_created", "Unknown Date")

				# Set the button text
				button.text = world_name + "\n" + date_created
			else:
				button.text = "No Data Available"
		else:
			button.text = "Failed to Load (Parse Error)"
	else:
		button.text = "Failed to Load (File Access Error)"
