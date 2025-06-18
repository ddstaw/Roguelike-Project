extends TextureRect

# Preload resources
var tile_forest = preload("res://assets/graphics/36x36-forest.png")
var tile_mountains = preload("res://assets/graphics/36x36-mountains.png")
var tile_grass = preload("res://assets/graphics/36x36-grass.png")
var tile_ocean = preload("res://assets/graphics/36x36-ocean.png")
var loaded_tiles = {}

# Size constants
const TILE_SIZE = 36
const GRID_SIZE = 12  # 12x12 grid
const VIEWPORT_SIZE = 432  # 432x432 pixels viewbox
const GRID_TOTAL_SIZE = GRID_SIZE * TILE_SIZE  # 432x432 pixels for the full grid

# Variable to hold the grid data
var grid_data = {}

# Lazy load a tile
func lazy_load_tile(tile_path: String) -> Texture:
	if loaded_tiles.has(tile_path):
		return loaded_tiles[tile_path]
	else:
		var texture = load(tile_path)
		loaded_tiles[tile_path] = texture
		return texture

# Function to load and parse the JSON file
func load_grid_data(json_path: String):
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()  # Close the file after reading

		var json = JSON.new()
		var error = json.parse(json_data)

		if error == OK:
			var data_dict = json.data[0]
			if data_dict.has("grid"):
				grid_data = data_dict["grid"]
			else:
				grid_data = {}
				print("No grid found in JSON.")
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_data, " at line ", json.get_error_line())
	else:
		print("Error loading JSON file.")


# Function to create a grid of tiles
func create_grid():
	var viewport = self  # Reference to the TextureRect itself

	# Clear previous grid by removing all children of WorldTextureRect
	for child in viewport.get_children():
		child.queue_free()

	if grid_data.size() == 0:
		print("Grid data is empty. Check the JSON content.")
		return

	var biomes = grid_data.get("biomes", [])
	var tiles = grid_data.get("tiles", [])
	var names = grid_data.get("names", [])

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile_path = tiles[y][x]
			if not tile_path.begins_with("res://"):
				tile_path = "res://assets/graphics/" + tile_path

			var texture_rect = TextureRect.new()
			texture_rect.texture = lazy_load_tile(tile_path)
			texture_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			texture_rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)

			viewport.add_child(texture_rect)

# Function to initialize the map display
func init_map_display(json_path: String = "user://worldgen/playing_map.json"):
	load_grid_data(json_path)
	create_grid()
