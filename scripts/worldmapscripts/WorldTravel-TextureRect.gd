extends TextureRect

# Preload resources
var tile_forest = preload("res://assets/worldmap-graphics/tiles/87x87-forest.png")
var tile_mountains = preload("res://assets/worldmap-graphics/tiles/87x87-mountains.png")
var tile_grass = preload("res://assets/worldmap-graphics/tiles/87x87-grass.png")
var tile_ocean = preload("res://assets/worldmap-graphics/tiles/87x87-ocean.png")
var loaded_tiles = {}
var player_character_node: TextureRect = null  # Reference to the current player character node


# Size constants
const TILE_SIZE = 87
const GRID_SIZE = 12  # 12x12 grid

# Variable to hold the grid data
var grid_data = {}
var tile_positions = {}
var player_position = {}

func _ready():
	# Initialize the map display using the singleton
	print("Initializing map display...")
	init_map_display()
	
# Lazy load a tile
func lazy_load_tile(tile_path: String) -> Texture:
	if loaded_tiles.has(tile_path):
		return loaded_tiles[tile_path]
	else:
		var texture = load(tile_path)
		loaded_tiles[tile_path] = texture
		return texture

# Function to initialize the map display
func init_map_display():
	# Use the singleton to load player position and grid data
	player_position = LoadHandlerSingleton.get_player_position()
	grid_data = LoadHandlerSingleton.get_grid_data()

	if grid_data.size() == 0:
		print("Grid data is empty. Check the JSON content.")
		return

	# Create and display the grid
	create_grid()
	display_player_character(player_position)
	update_map_markers()

 # Function to create a grid of tiles
func create_grid():
	var viewport = self  # Reference to the TextureRect itself

	# Clear previous grid by removing all children of WorldTextureRect
	for child in viewport.get_children():
		child.queue_free()

	if grid_data.size() == 0:
		print("Grid data is empty. Check the JSON content.")
		return

	var tiles = grid_data.get("tiles", [])

	# Check if tiles is correctly structured
	if tiles.size() == 0 or tiles.size() < GRID_SIZE or tiles[0].size() < GRID_SIZE:
		print("Error: Grid data structure is incorrect.")
		return

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile_path = tiles[y][x]
			if not tile_path.begins_with("res://"):
				tile_path = "res://assets/graphics/" + tile_path

			var texture_rect = TextureRect.new()
			texture_rect.texture = lazy_load_tile(tile_path)
			texture_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			texture_rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			tile_positions[texture_rect] = Vector2(x, y)
			viewport.add_child(texture_rect)
			
func display_player_character(player_position: Vector2):
	if player_position == Vector2(-1, -1):  # Check for invalid position
		print("Invalid player position.")
		return

	# Remove the old player character if it exists
	if player_character_node:
		player_character_node.queue_free()  # Removes the current player character node

	# Create a new TextureRect for the player character
	player_character_node = TextureRect.new()
	player_character_node.texture = preload("res://assets/worldmap-graphics/active/87x87-player-world-map.png")
	player_character_node.size = Vector2(TILE_SIZE, TILE_SIZE)

	var x = int(player_position.x)
	var y = int(player_position.y)
	player_character_node.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)

	player_character_node.z_index = 10  # ✅ Higher than all map markers

	add_child(player_character_node)  # Add the new player character node to the scene
	print("Goofy Player character displayed at:", player_character_node.position)
	

	# Inside WorldTravel-TextureRect.gd
func remove_player_character():
	if has_node("PlayerCharacter"):  # Adjust the node path as necessary
		var player_character = get_node("PlayerCharacter")
		player_character.queue_free()  # This will remove the player character from the scene
		print("Player character removed.")
	else:
		print("No player character found to remove.")

func update_map_markers():
	var investigations = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_investigate_localmaps_path())
	var remembered_places = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_remembered_localmaps_path())

	# ✅ Get the player's current realm
	var player_realm = LoadHandlerSingleton.get_current_realm()
	var player_realm_name = null  # Some city realms have unique names

	if player_realm == "citymap":
		var placement_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_worldmap_placement_path())

		if placement_data and placement_data.has("character_position"):
			var citymap_data = placement_data["character_position"].get("citymap", {})
			player_realm_name = citymap_data.get("name", null)  # ✅ Get the city name

	var tile_markers = {}

	# ✅ Step 1: Check for Investigations
	if investigations and investigations.has("investigate"):
		for inv_key in investigations["investigate"].keys():
			var inv = investigations["investigate"][inv_key]

			# ✅ Only show markers for investigations in the same realm
			if inv["realm"] == player_realm and inv.get("realm_name", null) == player_realm_name:
				var pos = Vector2(inv["grid_position"]["x"], inv["grid_position"]["y"])
				if pos not in tile_markers:
					tile_markers[pos] = {"investigation": false, "remembered": false}
				tile_markers[pos]["investigation"] = true  # ✅ Mark this tile as having an investigation

	# ✅ Step 2: Check for Remembered Places
	if remembered_places and remembered_places.has("remembered_places"):
		for place_key in remembered_places["remembered_places"].keys():
			var place = remembered_places["remembered_places"][place_key]

			# ✅ Only show markers for remembered places in the same realm
			if place["realm"] == player_realm and place.get("realm_name", null) == player_realm_name:
				var pos = Vector2(place["grid_position"]["x"], place["grid_position"]["y"])
				if pos not in tile_markers:
					tile_markers[pos] = {"investigation": false, "remembered": false}
				tile_markers[pos]["remembered"] = true  # ✅ Mark this tile as having a remembered place

	# ✅ Step 3: Overlay Icons on Relevant Tiles (Only in the Correct Realm)
	for pos in tile_markers.keys():
		if tile_markers[pos]["investigation"]:
			place_marker(pos, "res://assets/worldmap-special/87x87-event.png", Vector2(0, 0), 2)  # Centered, z_index 2
		if tile_markers[pos]["remembered"]:
			place_marker(pos, "res://assets/worldmap-special/87x87-rp.png", Vector2(10, -10), 3)  # Offset, z_index 3

func place_marker(tile_position: Vector2, texture_path: String, offset: Vector2, layer: int):
	var marker = TextureRect.new()
	marker.texture = load(texture_path)
	marker.size = Vector2(TILE_SIZE, TILE_SIZE)
	marker.position = (tile_position * TILE_SIZE) + offset  # ✅ Position correctly
	marker.z_index = layer  # ✅ Different z_index ensures proper layering

	add_child(marker)  # ✅ Add the marker to the scene
