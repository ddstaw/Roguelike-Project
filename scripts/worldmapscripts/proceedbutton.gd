extends Button

@onready var popup_scene_local = preload("res://ui/scenes/PopupWorldtoLocal.tscn")
@onready var popup_world_to_city = preload("res://ui/scenes/PopupWorldtoCity.tscn")  # City Entry Popup
@onready var popup_city_to_world = preload("res://ui/scenes/PopupExitCity.tscn")  # City Exit Popup


func _ready():
	connect("pressed", Callable(self, "_on_Button_pressed"))

func _on_Button_pressed():
	var player_position = LoadHandlerSingleton.get_player_position()
	if player_position == Vector2(-1, -1):
		print("Error: Unable to retrieve player position.")
		return
	
	# ✅ Check current realm
	var current_realm = LoadHandlerSingleton.get_current_realm()
	
	# 🌍 If we're in worldmap, determine if it's a city entry
	if current_realm == "worldmap":
		handle_worldmap_proceed(player_position)
	elif current_realm == "citymap":
		handle_citymap_proceed(player_position)

# ✅ Handle proceed button in the worldmap (entering a city)
func handle_worldmap_proceed(player_position: Vector2):
	var biome_name = LoadHandlerSingleton.get_biome_name(player_position)
	print("Biome at current position:", biome_name)  # Debugging

	# 🚀 Check if the tile is a city, village, or passage
	if biome_name in ["village", "capitalcity", "dwarfcity", "elfhaven", "oldcity", "northpass", "eastpass", "westpass", "southpass"]:
		show_city_entry_popup()
	else:
		show_local_map_popup()

func handle_citymap_proceed(player_position: Vector2):
	var biome_name = LoadHandlerSingleton.get_biome_name(player_position)
	print("🏙️ Biome at current position in citymap:", biome_name)  # Debugging

	# 🚪 If we are at the city gate, show exit popup
	if biome_name == "village-gate":
		show_city_exit_popup()

	# 🏙️ For all other city biomes, open the local map pop-up
	else:
		show_local_map_popup()


# ✅ City Exit Popup
func show_city_exit_popup():
	var popup = popup_city_to_world.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.show()

func show_city_entry_popup():
	var popup = popup_world_to_city.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.show()  # ✅ Now it handles everything internally

func get_city_at_position(player_position: Vector2) -> String:
	var city_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_citydata_path())

	# ✅ Check city_data first
	if city_data.has("city_data"):
		for city_name in city_data["city_data"].keys():
			var city_info = city_data["city_data"][city_name]
			var city_position = parse_position(city_info["worldmap-location"])
			if city_position == player_position:
				return city_name  # ✅ Found a city at this position
	
	# ✅ If no city found, check if it's a village
	var village_name = LoadHandlerSingleton.villages.get(player_position, "")
	if village_name != "":
		return village_name  # ✅ Found a village

	return "Unknown City"  # ✅ Fallback


# Helper function to convert the "worldmap-location" string to Vector2
func parse_position(position_str: String) -> Vector2:
	position_str = position_str.trim_prefix("(").trim_suffix(")")
	var pos = position_str.split(",")
	return Vector2(pos[0].to_int(), pos[1].to_int())

func show_local_map_popup():
	var popup = popup_scene_local.instantiate()
	popup.explore_selected.connect(_on_Explore_Selected)  # ✅ Connect signal
	get_tree().current_scene.add_child(popup)
	popup.show()


# ✅ New function to handle "Explore" selection
func _on_Explore_Selected():
	print("Explore option selected!")  # ✅ Debug
