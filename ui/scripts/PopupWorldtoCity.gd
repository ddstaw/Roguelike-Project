# res://ui/scenes/PopupWorldtoCity.tscn parent node script - res://ui/scenes/PopupWorldtoLocal.gd
extends Window

@onready var city_name_label = $citynamelabel
@onready var yes_button = $VBoxContainer/YesEnterButton
@onready var no_button = $VBoxContainer/NoDontButton

signal enter_selected(city_name: String)

var worldmap_json_path: String = LoadHandlerSingleton.get_worldmap_placement_path()
var city_data_json_path: String = LoadHandlerSingleton.get_citydata_path()
var city_name: String = "Unknown City"

func _ready():
	# ✅ Get the city name directly from LoadHandlerSingleton
	city_name = LoadHandlerSingleton.get_current_city_name()

	# ✅ If no city found, use a fallback name
	if city_name == "":
		city_name = "Unknown Settlement"

	# ✅ Update the label dynamically
	city_name_label.text = city_name.to_upper()

	# ✅ Button connections
	yes_button.connect("pressed", Callable(self, "_on_Yes_Pressed"))
	no_button.connect("pressed", Callable(self, "_on_No_Pressed"))
	connect("close_requested", Callable(self, "_on_Close_Pressed"))


func set_city_name(name: String):
	if name == "":
		name = "Unknown Settlement"  # ✅ Fallback name if city is not found

	city_name = name
	city_name_label.text = name.to_upper() # ✅ Update label

func _on_Yes_Pressed():
	update_worldmap_json()
	LoadHandlerSingleton.trigger_map_reload()
	get_tree().change_scene_to_file("res://scenes/play/QuickRefresh.tscn")
	queue_free()

# ✅ Function to update citymap data based on worldmap position
func update_worldmap_json():
	var worldmap_data = LoadHandlerSingleton.load_json_file(worldmap_json_path)
	var city_data = LoadHandlerSingleton.load_json_file(city_data_json_path)

	if not worldmap_data or not worldmap_data.has("character_position"):
		print("❌ ERROR: Failed to load WorldMap_PlacementX.json!")
		return

	if not city_data or not city_data.has("city_data"):
		print("❌ ERROR: Failed to load City_DataX.json!")
		return

	# ✅ Get the current worldmap grid_position
	var worldmap_position = worldmap_data["character_position"]["worldmap"].get("grid_position", null)

	if not worldmap_position:
		print("❌ ERROR: No grid_position found in worldmap!")
		return

	var worldmap_x = int(worldmap_position["x"])
	var worldmap_y = int(worldmap_position["y"])

	print("🔍 Player is at worldmap grid:", worldmap_x, worldmap_y)

	# ✅ Find which city matches this grid_position
	var matched_city_name = ""
	var matched_city_data = null

	for city_name in city_data["city_data"]:
		var city_info = city_data["city_data"][city_name]
		var city_position = parse_position(city_info["worldmap-location"])

		if city_position.x == worldmap_x and city_position.y == worldmap_y:
			matched_city_name = city_name
			matched_city_data = city_info
			break

	if matched_city_name == "":
		print("❌ ERROR: No city found at this worldmap location!")
		return

	print("✅ Matched city:", matched_city_name)

	# ✅ Update citymap data
	worldmap_data["character_position"]["current_realm"] = "citymap"
	worldmap_data["character_position"]["citymap"] = {
		"name": matched_city_name,
		"city_grid": matched_city_data["city_grid"],
		"grid_position": { "x": 6, "y": 11 },  # Fixed target position
		"biome": "village-gate",
		"cell_name": "cell_6_11"
	}

	# ✅ Save the updated worldmap JSON
	save_json(worldmap_json_path, worldmap_data)

	print("✅ Entered city:", matched_city_name, "| WorldMap JSON updated!")

func parse_position(position_str: String) -> Vector2:
	if position_str.is_empty():
		print("❌ ERROR: Empty city position string!")
		return Vector2(-1, -1)

	# ✅ Remove parentheses and split safely
	position_str = position_str.strip_edges().trim_prefix("(").trim_suffix(")")
	var pos = position_str.split(",")

	if pos.size() < 2:
		print("❌ ERROR: Invalid position format!", position_str)
		return Vector2(-1, -1)

	return Vector2(pos[0].to_int(), pos[1].to_int())

func save_json(path: String, data: Dictionary):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		print("❌ ERROR: Unable to open file for writing!", path)
		return

	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("✅ JSON Saved Successfully:", path)

# ✅ If "Perhaps Not" is pressed, just close the popup
func _on_No_Pressed():
	queue_free()  # ✅ Closes the popup

func _on_Close_Pressed():
	queue_free()  # ✅ Closes the window properly
