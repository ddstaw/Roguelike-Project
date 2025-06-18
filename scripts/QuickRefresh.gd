extends Control

@onready var realm_label = $RealmLabel  # ✅ Make sure this matches the actual node

func _ready():
	# Ensure the label exists
	if realm_label == null:
		print("❌ ERROR: RealmLabel is missing!")
		return

	# ✅ Get realm name from JSON
	var realm_name = get_current_realm_name()

	# ✅ Set the text and make it invisible at start
	realm_label.text = realm_name
	realm_label.modulate.a = 0.0  # Start hidden

	# ✅ Start transition
	fade_in()

func fade_in():
	var tween = create_tween()
	tween.tween_property(realm_label, "modulate:a", 1.0, 0.5)  # Fade in text
	await tween.finished
	await get_tree().create_timer(1.5).timeout  # Hold for 1.5s before fade out
	fade_out()

func fade_out():
	var tween = create_tween()
	tween.tween_property(realm_label, "modulate:a", 0.0, 0.5)  # Fade out text
	await tween.finished

	# ✅ Switch back to world map
	SceneManager.set_play_scene("res://scenes/play/WorldMapTravel.tscn")

func get_current_realm_name() -> String:
	var placement_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_worldmap_placement_path())

	if placement_data.has("character_position"):
		var current_realm = placement_data["character_position"].get("current_realm", "worldmap")

		# ✅ If in a city, fetch the city name from worldmap_placementX.json
		if current_realm == "citymap" and placement_data["character_position"].has("citymap"):
			return placement_data["character_position"]["citymap"].get("name", "Unknown Location")

		# ✅ If in worldmap, fetch the world name from basemapdataX.json
		if current_realm == "worldmap":
			return LoadHandlerSingleton.get_world_name()

	print("❌ ERROR: Could not determine realm name!")
	return "Unknown Location"  # Fallback name
