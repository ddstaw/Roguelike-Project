extends Window

@onready var yes_button = $VBoxContainer/YesExitButton
@onready var no_button = $VBoxContainer/NoCancelButton

func _ready():
	yes_button.connect("pressed", Callable(self, "_on_Yes_Exit_Pressed"))
	no_button.connect("pressed", Callable(self, "_on_No_Cancel_Pressed"))
	connect("close_requested", Callable(self, "_on_No_Cancel_Pressed"))

func _on_Yes_Exit_Pressed():
	update_worldmap_json()
	LoadHandlerSingleton.trigger_map_reload()
	get_tree().change_scene_to_file("res://scenes/play/QuickRefresh.tscn")
	queue_free()

func _on_No_Cancel_Pressed():
	queue_free()  # Just close the popup

# ✅ Update JSON to move the player back to worldmap
func update_worldmap_json():
	var worldmap_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_worldmap_placement_path())

	if not worldmap_data or not worldmap_data.has("character_position"):
		print("❌ ERROR: Failed to load WorldMap_PlacementX.json!")
		return

	# ✅ Only change the realm—don't touch worldmap variables
	worldmap_data["character_position"]["current_realm"] = "worldmap"

	# ✅ Save the updated worldmap JSON
	var file = FileAccess.open(LoadHandlerSingleton.get_worldmap_placement_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(worldmap_data, "\t"))
		file.close()
		print("✅ JSON Updated: Player returned to worldmap, NO worldmap values changed.")
	else:
		print("❌ ERROR: Failed to save JSON!")
		
# ✅ Quick scene refresh to force the player character to reappear properly
func quick_refresh_scene():
	print("🔄 Triggering quick scene refresh...")
	var current_scene = get_tree().current_scene
	var transition_scene = preload("res://scenes/play/QuickRefresh.tscn").instantiate()

	get_tree().current_scene.add_child(transition_scene)  # Add transition screen

	await get_tree().create_timer(0.5).timeout  # Small delay to prevent flicker
	get_tree().change_scene_to_file("res://scenes/play/WorldMapTravel.tscn")  # Reload map
