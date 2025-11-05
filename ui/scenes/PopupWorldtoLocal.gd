#res://ui/scenes/PopupWorldtoLocal.tscn parent node script res://ui/scenes/PopupWorldtoLocal.gd
extends Window

signal explore_selected  # ✅ Signal to inform ProceedButton that Explore was chosen

func _ready():
	$VBoxContainer/ExploreButton.connect("pressed", Callable(self, "_on_Explore_pressed"))
	$VBoxContainer/RememberButton.connect("pressed", Callable(self, "_on_Remember_pressed"))
	$VBoxContainer/InvestigateButton.connect("pressed", Callable(self, "_on_Investigate_pressed"))
	connect("close_requested", Callable(self, "_on_Close_pressed"))  # ✅ Handle "X" button

func _on_Explore_pressed():
	print("🚀 Explore button pressed! Checking tiledata.json...")

	# ✅ Step 1: Get the correct tiledata.json path
	var tile_data_path = LoadHandlerSingleton.get_tile_data_path()
	var tile_data = LoadHandlerSingleton.load_json_file(tile_data_path)

	# ✅ Step 2: Ensure "tiles" dictionary exists
	if not tile_data.has("tiles"):
		tile_data["tiles"] = {}

	# ✅ Step 3: Get the player's current realm and grid position
	var player_position = LoadHandlerSingleton.get_player_position()
	var player_realm = LoadHandlerSingleton.get_current_realm()

	# ✅ Step 4: Generate a unique tile key (Realm + Grid Position)
	var tile_key = player_realm + "_" + str(player_position.x) + "_" + str(player_position.y)

	# ✅ Step 5: If this tile does NOT exist in tiledata.json, create an entry
	if not tile_data["tiles"].has(tile_key):
		print("🌱 New tile detected! Storing adjacent tile info for:", tile_key)

		# ✅ Check adjacent tiles (N, S, E, W)
		var adjacent_tiles = {
			"north": LoadHandlerSingleton.get_biome_name(Vector2(player_position.x, player_position.y - 1)),
			"south": LoadHandlerSingleton.get_biome_name(Vector2(player_position.x, player_position.y + 1)),
			"east": LoadHandlerSingleton.get_biome_name(Vector2(player_position.x + 1, player_position.y)),
			"west": LoadHandlerSingleton.get_biome_name(Vector2(player_position.x - 1, player_position.y))
		}

		# ✅ Store tile data with adjacent tile info
		var new_tile_entry = {
			"grid_position": player_position,  # Save grid position
			"realm": player_realm,  # Save realm type
			"biome": LoadHandlerSingleton.get_biome_name(player_position),
			"adjacent_tiles": adjacent_tiles,  # Store adjacent biome types
			"last_explored_date": null,
			"times_explored": 0
		}

		# ✅ Store in tiledata.json
		tile_data["tiles"][tile_key] = new_tile_entry
		LoadHandlerSingleton.save_json_file(tile_data_path, tile_data)
		print("✅ Tile info saved with adjacent data:", tile_key)

	# ✅ Step 6: Load `disembark-explore-popup.tscn` (Now we are ready to explore)
	print("🎒 Opening Explore Popup...")
	var explore_popup_scene = load("res://ui/scenes/disembark-explore-popup.tscn")
	var explore_popup_instance = explore_popup_scene.instantiate()
	get_tree().current_scene.add_child(explore_popup_instance)

	# ✅ Step 7: Close the current pop-up
	queue_free()


func _on_Cancel_pressed():
	queue_free()  # ✅ Simply close the pop-up
	
func _on_Close_pressed():
	queue_free()  # ✅ Close window when "X" is clicked

func _on_Remember_pressed():
	print("Opening Remember Pop-Up...")  # Debugging log

	var popup_scene = load("res://ui/scenes/disembark-remember-popup.tscn")  # ✅ Load the Investigate Pop-Up Scene
	var popup_instance = popup_scene.instantiate()
	get_parent().add_child(popup_instance)  # ✅ Display it in the same scene tree
	queue_free()  # ✅ Close the current pop-up

func _on_Investigate_pressed():
	print("Opening Investigation Pop-Up...")  # Debugging log

	var popup_scene = load("res://ui/scenes/disembark-invest-popup.tscn")  # ✅ Load the Investigate Pop-Up Scene
	var popup_instance = popup_scene.instantiate()
	get_parent().add_child(popup_instance)  # ✅ Display it in the same scene tree
	queue_free()  # ✅ Close the current pop-up
