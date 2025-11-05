extends Button

@onready var popup_scene_local = preload("res://ui/scenes/PopupWorldtoLocal.tscn")
@onready var popup_world_to_city = preload("res://ui/scenes/PopupWorldtoCity.tscn")
@onready var popup_city_to_world = preload("res://ui/scenes/PopupExitCity.tscn")
@onready var popup_hub_entry = preload("res://ui/scenes/PopupHubEntry.tscn")  # ✅ NEW

func _ready():
	connect("pressed", Callable(self, "_on_Button_pressed"))

func _on_Button_pressed():
	var player_position = LoadHandlerSingleton.get_player_position()
	if player_position == Vector2(-1, -1):
		print("❌ Error: Unable to retrieve player position.")
		return

	var current_realm = LoadHandlerSingleton.get_current_realm()
	if current_realm == "worldmap":
		handle_worldmap_proceed(player_position)
	elif current_realm == "citymap":
		handle_citymap_proceed(player_position)


# 🌍 Handles Proceed on the World Map
func handle_worldmap_proceed(player_position: Vector2):
	var biome_name = LoadHandlerSingleton.get_biome_name(player_position)
	print("Biome at current position:", biome_name)

	# 🏪 ✅ Static Hub entries (Tradepost, Fort, Guildhall, etc.)
	if biome_name in ["tradepost", "fort", "guildhall"]:
		print("🏪 Detected static hub biome:", biome_name)
		show_hub_entry_popup(biome_name)
		return

	# 🏙️ City/Village/Passage entries
	if biome_name in ["village", "capitalcity", "dwarfcity", "elfhaven", "oldcity", 
		"northpass", "eastpass", "westpass", "southpass"]:
		show_city_entry_popup()
	else:
		show_local_map_popup()


# 🏙️ Handles Proceed within a City Map
func handle_citymap_proceed(player_position: Vector2):
	var biome_name = LoadHandlerSingleton.get_biome_name(player_position)
	print("🏙️ Biome at current position in citymap:", biome_name)

	if biome_name == "village-gate":
		show_city_exit_popup()
	else:
		show_local_map_popup()


# ✅ Popup Spawners
func show_city_exit_popup():
	var popup = popup_city_to_world.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.show()

func show_city_entry_popup():
	var popup = popup_world_to_city.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.show()

func show_local_map_popup():
	var popup = popup_scene_local.instantiate()
	popup.explore_selected.connect(_on_Explore_Selected)
	get_tree().current_scene.add_child(popup)
	popup.show()

func show_hub_entry_popup(biome_name: String):
	var popup = popup_hub_entry.instantiate()
	get_tree().current_scene.add_child(popup)
	popup.set_meta("hub_biome", biome_name)
	popup.show()
	print("✅ Hub entry popup shown for:", biome_name)


# ✅ Helper: city lookup (unchanged)
func get_city_at_position(player_position: Vector2) -> String:
	var city_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_citydata_path())
	if city_data.has("city_data"):
		for city_name in city_data["city_data"].keys():
			var city_info = city_data["city_data"][city_name]
			var city_position = parse_position(city_info["worldmap-location"])
			if city_position == player_position:
				return city_name
	var village_name = LoadHandlerSingleton.villages.get(player_position, "")
	if village_name != "":
		return village_name
	return "Unknown City"

func parse_position(position_str: String) -> Vector2:
	position_str = position_str.trim_prefix("(").trim_suffix(")")
	var pos = position_str.split(",")
	return Vector2(pos[0].to_int(), pos[1].to_int())

func _on_Explore_Selected():
	print("Explore option selected!")
