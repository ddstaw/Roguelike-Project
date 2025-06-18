extends Node

var current_chunk_coords: Vector2i
var player_local_tile: Vector2i


# Stores the path of the previous scene
var previous_scene_path: String = ""  

# Store the current play scene
var current_play_scene_path: String = ""

# A stack to manage scene navigation
var scene_stack: Array = []

func set_play_scene(scene_path: String) -> void:
	# Only change the scene if it's different from the current one
	if get_tree().current_scene.get_scene_file_path() != scene_path:
		print("Switching to play scene:", scene_path)
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Already in the play scene:", scene_path)

# Function to change scenes and store the previous one
func change_scene_to_file(new_scene_path: String):
	if get_tree().current_scene != null:
		# Save the current scene path before changing
		previous_scene_path = get_tree().current_scene.get_scene_file_path()
		print("Setting previous scene to:", previous_scene_path)  # Debug print

		# Push current scene to the stack
		scene_stack.append(previous_scene_path)

	# Change to the new scene
	get_tree().change_scene_to_file(new_scene_path)

# Function to go back to the previous scene
func go_back_to_previous_scene():
	if scene_stack.size() > 0:
		# Pop the last scene path from the stack
		previous_scene_path = scene_stack.pop_back()
		print("Going back to previous scene:", previous_scene_path)  # Debug print
		get_tree().change_scene_to_file(previous_scene_path)
	else:
		print("No previous scene to go back to!")  # Debug if no previous scene

# Function to return to the current play scene (world map or local map)
func return_to_play_scene():
	if current_play_scene_path != "":
		print("Returning to play scene:", current_play_scene_path)  # Debug print
		get_tree().change_scene_to_file(current_play_scene_path)
	else:
		print("No play scene set, falling back to previous scene.")
		go_back_to_previous_scene()

func transition_to_chunk(new_chunk_id: String, new_tile_pos: Vector2i):
	var placement = LoadHandlerSingleton.load_temp_localmap_placement()
	placement["local_map"]["current_chunk_id"] = new_chunk_id
	placement["local_map"]["grid_position_local"] = {
		"x": new_tile_pos.x,
		"y": new_tile_pos.y
	}
	LoadHandlerSingleton.save_temp_placement(placement)

	current_play_scene_path = "res://scenes/play/LocalMap.tscn"
	change_scene_to_file("res://scenes/play/ChunkToChunkRefresh.tscn")

func transition_to_world_map():
	# Save whatever you need first
	LoadHandlerSingleton.save_all_local_data()

	current_play_scene_path = "res://scenes/play/WorldMapTravel.tscn"
	change_scene_to_file("res://scenes/play/LocaltoWorldRefresh.tscn")
