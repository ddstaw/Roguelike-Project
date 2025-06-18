extends Control

# Preload resources
var tile_forest = preload("res://assets/graphics/36x36-forest.png")
var tile_mountains = preload("res://assets/graphics/36x36-mountains.png")
var tile_grass = preload("res://assets/graphics/36x36-grass.png")
var tile_ocean = preload("res://assets/graphics/36x36-ocean.png")
var loaded_tiles = {}

# Size constants
const TILE_SIZE = 36
const GRID_SIZE = 12  # 12x12 grid
const VIEWPORT_SIZE = 216  # 216x216 pixels viewbox
const GRID_TOTAL_SIZE = GRID_SIZE * TILE_SIZE  # 432x432 pixels for the full grid

# Movement speed
const MOVE_SPEED = 10  # Pixels per keypress

# Variable to hold the grid data
var grid_data = []
var grid_position = Vector2(0, 0)  # Track the position of the grid

# Variable to hold the reference to RandomizerNode
var randomizer = null
# Variable to hold world name
var world_name_generator = null

func _ready():
	randomizer = get_node("RandomizerNode")
	world_name_generator = get_node("WorldNameGeneratorNode")
	load_grid_data()
	create_grid()
	world_name_generator.update_world_name_label()

func _process(delta):
	handle_input()

# Lazy load a tile
func lazy_load_tile(tile_path: String) -> Texture:
	if loaded_tiles.has(tile_path):
		return loaded_tiles[tile_path]
	else:
		var texture = load(tile_path)
		loaded_tiles[tile_path] = texture
		return texture

# Function to load and parse the JSON file
func load_grid_data():
	var file = FileAccess.open("user://worldgen/current_map.json", FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()  # Close the file after reading
		
		var json = JSON.new()
		var error = json.parse(json_data)
		
		if error == OK:
			var data_dict = json.data
			if data_dict.has("grid"):
				grid_data = data_dict["grid"]
			else:
				grid_data = []
				print("No grid found in JSON.")
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_data, " at line ", json.get_error_line())
	else:
		print("Error loading JSON file.")

# Function to create a grid of tiles
func create_grid():
	var viewport = get_node("Control/SubViewportContainer/SubViewport/GridTextureRect")
	
	if not viewport:
		print("Viewport is not found. Check the node path.")
		return
	
	# Clear previous grid by removing all children of GridTextureRect
	for child in viewport.get_children():
		child.queue_free()
	
	if grid_data.is_empty():
		print("Grid data is empty. Check the JSON content.")
		return
	
	var grid_info = grid_data[0]
	var tiles = grid_info.get("tiles", [])
	
	var names = []
	if grid_info.has("names"):
		names = grid_info["names"]

	var biomes = []
	if grid_info.has("biomes"):
		biomes = grid_info["biomes"]
	
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var tile_path = tiles[y][x]
			if not tile_path.begins_with("res://"):
				tile_path = "res://assets/graphics/" + tile_path
			
			var cell_name = "Unnamed"
			if names.size() > y and names[y].size() > x:
				cell_name = names[y][x]

			var biome_type = "Unknown"
			if biomes.size() > y and biomes[y].size() > x:
				biome_type = biomes[y][x]
			
			var texture_rect = TextureRect.new()
			texture_rect.texture = load(tile_path)
			texture_rect.size = Vector2(TILE_SIZE, TILE_SIZE)
			texture_rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			
			viewport.add_child(texture_rect)

	update_grid_position()

# Function to update the grid's position
func update_grid_position():
	var viewport = get_node("Control/SubViewportContainer/SubViewport/GridTextureRect")
	viewport.position = grid_position

# Function to handle input for panning
func handle_input():
	var moved = false
	
	if Input.is_action_pressed("ui_left"):
		grid_position.x += MOVE_SPEED
		moved = true
	if Input.is_action_pressed("ui_right"):
		grid_position.x -= MOVE_SPEED
		moved = true
	if Input.is_action_pressed("ui_up"):
		grid_position.y += MOVE_SPEED
		moved = true
	if Input.is_action_pressed("ui_down"):
		grid_position.y -= MOVE_SPEED
		moved = true
	
	# Clamp the grid position to prevent moving out of bounds
	grid_position.x = clamp(grid_position.x, VIEWPORT_SIZE - GRID_TOTAL_SIZE, 0)
	grid_position.y = clamp(grid_position.y, VIEWPORT_SIZE - GRID_TOTAL_SIZE, 0)
	
	if moved:
		update_grid_position()

