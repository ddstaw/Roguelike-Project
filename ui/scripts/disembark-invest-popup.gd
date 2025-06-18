extends Window

func _ready():
	$VBoxContainer/BackButton.connect("pressed", Callable(self, "_on_Back_pressed"))
	connect("close_requested", Callable(self, "_on_Close_pressed"))  # Handles "X" button
	
	# 🔎 Check for investigations when this pop-up opens
	var location = get_current_location()
	var investigations = get_relevant_investigations(location["realm"], location["grid_position"])
	display_investigations(investigations)

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

# Get unresolved investigations that match the current location
func get_relevant_investigations(current_realm: String, grid_position: Vector2) -> Array:
	var investigate_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_investigate_localmaps_path())  # Load investigate data
	var relevant_investigations = []

	if investigate_data and investigate_data.has("investigate"):
		var investigations = investigate_data["investigate"]

		# Loop through all investigations
		for key in investigations.keys():
			var investigation = investigations[key]
			var realm_matches = (investigation["realm"] == current_realm)
			var grid_matches = (investigation["grid_position"].x == grid_position.x and investigation["grid_position"].y == grid_position.y)

			# If both realm and grid position match, add to the relevant investigations list
			if realm_matches and grid_matches and investigation["resolved"] == "N":
				relevant_investigations.append({
					"name": investigation["name"],
					"type": investigation["type"],
					"key": key  # We store the key to identify the investigation
				})

	return relevant_investigations

func display_investigations(investigations: Array):
	# Clear any previous buttons (in case this is reloaded dynamically)
	for child in $VBoxContainer.get_children():
		if child is Button and child.name != "BackButton":  # Don't remove the Back button
			child.queue_free()

	if investigations.size() == 0:
		$VBoxContainer/Nothinglabel.show()  # ✅ Show "Nothing to investigate" message
	else:
		$VBoxContainer/Nothinglabel.hide()  # ❌ Hide the message if investigations exist

		# 🔄 Generate buttons dynamically
		for investigation in investigations:
			var button = Button.new()
			button.text = investigation["name"]
			button.name = "Investigation_" + investigation["key"]  # Give each button a unique name
			button.connect("pressed", Callable(self, "_on_InvestigationSelected").bind(investigation["key"]))
			$VBoxContainer.add_child(button)  # ✅ Add button to the UI dynamically

func _on_InvestigationSelected(investigation_key: String):
	print("🕵️ Investigation selected:", investigation_key)

	# ✅ Load investigate data
	var investigate_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_investigate_localmaps_path())

	if investigate_data and investigate_data.has("investigate") and investigate_data["investigate"].has(investigation_key):
		var investigation = investigate_data["investigate"][investigation_key]

		# ✅ Create entry_context1.json
		var entry_context = {
			"entry_type": "investigation",
			"investigation_id": investigation.get("type", ""),
			"realm": investigation.get("realm", "worldmap"),
			"realm_position": investigation.get("grid_position", { "x": -1, "y": -1 })
		}

		LoadHandlerSingleton.save_entry_context(entry_context)
		print("✅ Saved entry context for investigation:", entry_context)

		# ✅ Switch to interstitial scene
		get_tree().change_scene_to_file("res://scenes/play/WorldtoLocalRefresh.tscn")
	else:
		print("❌ ERROR: Could not find investigation data for:", investigation_key)
