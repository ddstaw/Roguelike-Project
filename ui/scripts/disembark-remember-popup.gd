extends Window

func _ready():
	$VBoxContainer/BackButton.connect("pressed", Callable(self, "_on_Back_pressed"))
	connect("close_requested", Callable(self, "_on_Close_pressed"))  # Handles "X" button
	
	# 🔎 Check for remembered places when this pop-up opens
	var location = get_current_location()
	var remembered_places = get_relevant_remembered_places(location["realm"], location["grid_position"])
	display_remembered_places(remembered_places)


func _on_Back_pressed():
	print("🔙 Returning to previous pop-up...")  # Debugging log

	var popup_scene = load("res://ui/scenes/PopupWorldtoLocal.tscn")  # ✅ Load previous pop-up
	var popup_instance = popup_scene.instantiate()
	get_parent().add_child(popup_instance)  # ✅ Show it in scene tree

	queue_free()  # ✅ Close this pop-up

func _on_Close_pressed():
	print("❌ Closing all pop-ups...")  # Debugging log
	queue_free()  # ✅ Shut down this pop-up (no reopening)
	
func get_current_location() -> Dictionary:
	var placement_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_worldmap_placement_path())  # ✅ Load worldmap placement JSON

	print("🌍 DEBUG: placement_data =", placement_data)  # 🔎 Debugging log

	var current_realm = "worldmap"  # Default to worldmap if not found
	var grid_position = Vector2(-1, -1)  # Default to invalid position

	# ✅ Ensure "character_position" exists
	if placement_data and "character_position" in placement_data:
		var character_position = placement_data["character_position"]

		# ✅ Get current realm (e.g., "worldmap", "citymap", "dungeon")
		current_realm = character_position.get("current_realm", "worldmap")

		# ✅ Ensure we have realm data before accessing "grid_position"
		if current_realm in character_position and "grid_position" in character_position[current_realm]:
			var pos = character_position[current_realm]["grid_position"]
			grid_position = Vector2(pos.x, pos.y)

	else:
		print("❌ ERROR: 'character_position' missing from worldmap placement JSON!")

	return {"realm": current_realm, "grid_position": grid_position}

func get_relevant_remembered_places(current_realm: String, grid_position: Vector2) -> Array:
	var remembered_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_remembered_localmaps_path())  # Load remembered places JSON
	var relevant_places = []

	if remembered_data and remembered_data.has("remembered_places"):
		var places = remembered_data["remembered_places"]

		# Loop through all remembered places
		for key in places.keys():
			var place = places[key]
			var realm_matches = (place["realm"] == current_realm)
			var grid_matches = (place["grid_position"].x == grid_position.x and place["grid_position"].y == grid_position.y)

			# If both realm and grid position match, add to the relevant remembered places list
			if realm_matches and grid_matches:
				relevant_places.append({
					"display_name": place["display_name"],  # ✅ Show proper name
					"key": key  # Store the key to identify the place
				})

	return relevant_places

func display_remembered_places(remembered_places: Array):
	# Clear any previous buttons (in case this is reloaded dynamically)
	for child in $VBoxContainer.get_children():
		if child is Button and child.name != "BackButton":  # Don't remove the Back button
			child.queue_free()

	if remembered_places.size() == 0:
		$VBoxContainer/Nothinglabel.show()  # ✅ Show "Nothing remembered here." message
	else:
		$VBoxContainer/Nothinglabel.hide()  # ❌ Hide the message if places exist

		# 🔄 Generate buttons dynamically (ONLY showing the display name)
		for place in remembered_places:
			var button = Button.new()
			button.text = place["display_name"]  # ✅ Shows the proper name
			button.name = "Remembered_" + place["key"]  # Unique button name
			button.connect("pressed", Callable(self, "_on_RememberedPlaceSelected").bind(place["key"]))
			$VBoxContainer.add_child(button)  # ✅ Add button to the UI dynamically

func _on_RememberedPlaceSelected(place_key: String):
	print("📍 Remembered place selected:", place_key)

	# ✅ Load remembered data
	var remembered_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_remembered_localmaps_path())

	if remembered_data and remembered_data.has("remembered_places") and remembered_data["remembered_places"].has(place_key):
		var place_data = remembered_data["remembered_places"][place_key]

		# ✅ Create entry_context1.json
		var entry_context = {
			"entry_type": "remembered",
			"remembered_key": place_key,  # 🔥 This is the important addition
			"realm": place_data.get("realm", "worldmap"),
			"realm_position": place_data.get("grid_position", { "x": -1, "y": -1 }),
			"investigation_id": ""  # Keep blank unless it’s an investigate-type
		}
		LoadHandlerSingleton.save_entry_context(entry_context)
		print("✅ Saved entry context for remembered place:", entry_context)

		# ✅ Switch to interstitial scene
		get_tree().change_scene_to_file("res://scenes/play/WorldtoLocalRefresh.tscn")
	else:
		print("❌ ERROR: Could not find data for remembered place:", place_key)
