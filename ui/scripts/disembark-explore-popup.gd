extends Window

@onready var findsome_label = $findsomelabel
@onready var explorebust_label = $VBoxContainer/explorebustlabel
@onready var explore_button = $VBoxContainer/ExploreProceedButton
@onready var nevermind_button = $VBoxContainer/NevermindButton

func _ready():
	print("🗺️ Explore pop-up opened. Checking tile exploration data...")

	# ✅ Step 1: Get the current tile key
	var player_position = LoadHandlerSingleton.get_player_position()
	var player_realm = LoadHandlerSingleton.get_current_realm()
	var tile_key = player_realm + "_" + str(player_position.x) + "_" + str(player_position.y)

	# ✅ Step 2: Load tiledata.json for this realm
	var tile_data_path = LoadHandlerSingleton.get_tile_data_path()
	var tile_data = LoadHandlerSingleton.load_json_file(tile_data_path)

	# ✅ Step 3: Check if this tile has exploration data
	if tile_data.has("tiles") and tile_data["tiles"].has(tile_key):
		var tile_info = tile_data["tiles"][tile_key]

		# ✅ Step 4: Check how many times it's been explored today
		var current_date = LoadHandlerSingleton.get_date_name()
		var times_explored = tile_info.get("times_explored", 0)
		var last_explored = tile_info.get("last_explored_date", null)

		if last_explored == current_date and times_explored >= 2:
			# 🚫 Exploration limit reached
			findsome_label.text = "Finding someplace new..."
			explorebust_label.text = "...but you can't seem to find \nanywhere worth exploring...\n...maybe tomorrow?"
			explore_button.hide()  # Hide the proceed button
		else:
			# ✅ Exploration is possible
			findsome_label.text = "Finding someplace new..."
			explorebust_label.text = "...You found a place"
			explore_button.show()  # Ensure the proceed button is visible
	else:
		# 🚫 No data found (shouldn't happen, but failsafe)
		findsome_label.text = "Something went wrong..."
		explorebust_label.text = "No valid exploration data for this tile."
		explore_button.hide()

	# ✅ Ensure "Nevermind" button always works
	nevermind_button.connect("pressed", Callable(self, "_on_Nevermind_pressed"))
	explore_button.connect("pressed", Callable(self, "_on_ExploreProceed_pressed"))

func _on_Nevermind_pressed():
	queue_free()  # ✅ Close the pop-up

func _on_ExploreProceed_pressed():
	print("🚀 Proceeding to explore! Updating tile exploration data...")

	# ✅ Step 1: Get the current tile key
	var player_position = LoadHandlerSingleton.get_player_position()
	var player_realm = LoadHandlerSingleton.get_current_realm()
	var tile_key = player_realm + "_" + str(player_position.x) + "_" + str(player_position.y)

	# ✅ Step 2: Load tiledata.json
	var tile_data_path = LoadHandlerSingleton.get_tile_data_path()
	var tile_data = LoadHandlerSingleton.load_json_file(tile_data_path)

	# ✅ Step 3: Check if this tile exists
	if tile_data.has("tiles") and tile_data["tiles"].has(tile_key):
		var tile_info = tile_data["tiles"][tile_key]

		# ✅ Step 4: Update exploration data
		var current_date = LoadHandlerSingleton.get_date_name()
		
		# If first time exploring today, reset count
		if tile_info.get("last_explored_date", null) != current_date:
			tile_info["times_explored"] = 0  # Reset daily count

		# Increase exploration count
		tile_info["times_explored"] += 1
		tile_info["last_explored_date"] = current_date

		# ✅ Save updated data
		tile_data["tiles"][tile_key] = tile_info
		LoadHandlerSingleton.save_json_file(tile_data_path, tile_data)
		print("✅ Exploration data updated for:", tile_key)
		
		# ✅ NEW: Save exploration context to entry_context1.json
		var entry_context := {
			"entry_type": "explore",
			"realm": player_realm,
			"realm_position": { "x": int(player_position.x), "y": int(player_position.y) },
			"investigation_id": ""  # Leave blank for now
		}
		LoadHandlerSingleton.save_entry_context(entry_context)
		# ✅ Load LocalMap.tscn (adjust path if needed)
		get_tree().change_scene_to_file("res://scenes/play/WorldtoLocalRefresh.tscn")
	else:
		print("❌ ERROR: Tile data missing for", tile_key)
		queue_free()

