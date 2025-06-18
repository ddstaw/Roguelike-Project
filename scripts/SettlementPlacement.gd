extends Node

var culture_map: Node = null
const GRID_SIZE = 12  # Define the grid size here

# Preload road and bridge tiles
var tile_road = preload("res://assets/graphics/36x36-road.png")
var tile_bridge = preload("res://assets/graphics/36x36-bridge.png")

# Settlement limits
const MAX_VILLAGES = 4
const MAX_ELF_HAVENS = 2
const MAX_DWARF_CITIES = 2
const MAX_OLD_CITIES = 2
const MAX_CAPITAL_CITIES = 1
const MAX_PASSES = 1  # Only one pass per direction

# Pass tiles
const TILE_NORTHPASS = "res://assets/graphics/36x36-northpass.png"
const TILE_SOUTHPASS = "res://assets/graphics/36x36-southpass.png"
const TILE_WESTPASS = "res://assets/graphics/36x36-westpass.png"
const TILE_EASTPASS = "res://assets/graphics/36x36-eastpass.png"

# Track placement of each settlement type
var village_count = 0
var elf_haven_count = 0
var dwarf_city_count = 0
var old_city_count = 0
var capital_city_count = 0

# Track placement of passes
var northpass_count = 0
var southpass_count = 0
var westpass_count = 0
var eastpass_count = 0

var settlement_positions = []  # To track placed settlements

func _ready():
	# Get the reference to the CultureMap node
	culture_map = get_node("/root/CultureMap")  # Update with your exact node path if necessary

func begin_settlement_placement():
	# Message to log
	if culture_map:
		var log_vbox = culture_map.get_node("MessageLogControl/MessageLogPanel/MessageLogScroll/MessageLogVBox")
		if log_vbox:
			var new_message_label = Label.new()
			new_message_label.text = "Settlement placement process started."
			culture_map.apply_font_styling_for_log(new_message_label)  # Apply the log styling
			log_vbox.add_child(new_message_label)
		else:
			print("MessageLogVBox not found!")
	else:
		print("CultureMap node not found!")

##### json code
func load_original_map_data() -> Dictionary:
	var file = FileAccess.open("user://worldgen/playing_map.json", FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()

		var json = JSON.new()
		var error = json.parse(json_data)

		if error == OK:
			return json.data[0]
		else:
			print("Error parsing JSON data: ", json.get_error_message())
			return {}
	else:
		print("Error opening the file.")
		return {}

# Function to create a copy of the map data and modify it
func create_settlement_map_data(original_data: Dictionary) -> Dictionary:
	# Create a deep copy of the original data to work with
	var settlement_data = original_data.duplicate(true)

	if settlement_data.has("grid"):
		var biomes = settlement_data["grid"]["biomes"]
		var tiles = settlement_data["grid"]["tiles"]
		var names = settlement_data["grid"]["names"]

		# Ensure at least one of each type is placed
		place_initial_settlements(biomes, tiles, names)
		
		# Place passes at hardcoded positions
		place_passes(biomes, tiles)

		# Place additional settlements based on the remaining capacity
		for y in range(GRID_SIZE):
			for x in range(GRID_SIZE):
				var biome = biomes[y][x]

				# Skip already placed settlements
				if tiles[y][x] != "":
					continue
				
				# Rule: Capital City
				if biome == "grass" or biome == "forest":
					if x > 2 and x < GRID_SIZE - 3 and y > 2 and y < GRID_SIZE - 3:
						if capital_city_count < MAX_CAPITAL_CITIES and randf() < 0.1:
							place_settlement(biomes, tiles, "capitalcity", "res://assets/graphics/36x36-capitalcity.png", ["grass", "forest"], 5.0)
				
				# Rule: Dwarf City
				elif biome == "mountains":
					if dwarf_city_count < MAX_DWARF_CITIES and randf() < 0.15:
						place_settlement(biomes, tiles, "dwarfcity", "res://assets/graphics/36x36-dwarfcity.png", ["mountains"], 3.0)
				
				# Rule: Elf Haven
				elif biome == "forest":
					if elf_haven_count < MAX_ELF_HAVENS and randf() < 0.2:
						place_settlement(biomes, tiles, "elfhaven", "res://assets/graphics/36x36-elfhaven.png", ["forest"], 4.0)
				
				# Rule: Old City
				elif biome == "mountains" or biome == "forest":
					if old_city_count < MAX_OLD_CITIES and randf() < 0.2:
						place_settlement(biomes, tiles, "oldcity", "res://assets/graphics/36x36-oldcity.png", ["mountains", "forest"], 4.0)
				
				# Rule: Small Village
				else:
					if village_count < MAX_VILLAGES and randf() < 0.3:
						place_settlement(biomes, tiles, "village", "res://assets/graphics/36x36-village.png", ["grass", "forest"], 3.0)

		# Connect all settlements with roads and bridges
		connect_settlements_with_roads(biomes, tiles)
	# Perform forced placement if needed
		if village_count < 2:
			force_village_placement(biomes, tiles)

	return settlement_data
	
func place_passes(biomes, tiles):
	# Place NorthPass at (0, 6)
	biomes[0][6] = "northpass"
	tiles[0][6] = TILE_NORTHPASS
	settlement_positions.append(Vector2(0, 6))
	
	# Place SouthPass at (11, 6)
	biomes[GRID_SIZE - 1][6] = "southpass"
	tiles[GRID_SIZE - 1][6] = TILE_SOUTHPASS
	settlement_positions.append(Vector2(GRID_SIZE - 1, 6))
	
	# Place WestPass at (6, 0)
	biomes[6][0] = "westpass"
	tiles[6][0] = TILE_WESTPASS
	settlement_positions.append(Vector2(6, 0))
	
	# Place EastPass at (6, 11)
	biomes[6][GRID_SIZE - 1] = "eastpass"
	tiles[6][GRID_SIZE - 1] = TILE_EASTPASS
	settlement_positions.append(Vector2(6, GRID_SIZE - 1))

# Function to connect settlements with roads
func connect_settlements_with_roads(biomes, tiles):
	var settlements = []
	
	# Collect all settlements positions
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if biomes[y][x] in ["capitalcity", "dwarfcity", "elfhaven", "oldcity", "village", "northpass", "southpass", "westpass", "eastpass"]:
				settlements.append(Vector2(x, y))
	
	# Start connecting settlements
	while settlements.size() > 1:
		var current = settlements.pop_front()
		var nearest = settlements[0]
		var min_distance = calculate_distance(current.x, current.y, nearest.x, nearest.y)
		
		# Find the nearest settlement
		for settlement in settlements:
			var distance = calculate_distance(current.x, current.y, settlement.x, settlement.y)
			if distance < min_distance:
				min_distance = distance
				nearest = settlement
		
		# Connect the current settlement with the nearest settlement
		connect_two_points(biomes, tiles, current, nearest)

# Function to connect two points with roads or bridges (cardinal directions only)
func connect_two_points(biomes, tiles, start: Vector2, end: Vector2):
	var x1 = start.x
	var y1 = start.y
	var x2 = end.x
	var y2 = end.y

	# Connect horizontally first
	while x1 != x2:
		if x1 < x2:
			x1 += 1
		elif x1 > x2:
			x1 -= 1
		
		if biomes[y1][x1] not in ["capitalcity", "dwarfcity", "elfhaven", "oldcity", "village", "northpass", "southpass", "westpass", "eastpass", "road", "bridge"]:
			if biomes[y1][x1] == "ocean":
				biomes[y1][x1] = "bridge"
				tiles[y1][x1] = "res://assets/graphics/36x36-bridge.png"  # Store the file path as a string
			else:
				biomes[y1][x1] = "road"
				tiles[y1][x1] = "res://assets/graphics/36x36-road.png"  # Store the file path as a string

	# Then connect vertically
	while y1 != y2:
		if y1 < y2:
			y1 += 1
		elif y1 > y2:
			y1 -= 1
		
		if biomes[y1][x1] not in ["capitalcity", "dwarfcity", "elfhaven", "oldcity", "village", "northpass", "southpass", "westpass", "eastpass", "road", "bridge"]:
			if biomes[y1][x1] == "ocean":
				biomes[y1][x1] = "bridge"
				tiles[y1][x1] = "res://assets/graphics/36x36-bridge.png"  # Store the file path as a string
			else:
				biomes[y1][x1] = "road"
				tiles[y1][x1] = "res://assets/graphics/36x36-road.png"  # Store the file path as a string

func calculate_distance(x1: int, y1: int, x2: int, y2: int) -> float:
	return sqrt(pow(x2 - x1, 2) + pow(y2 - y1, 2))

# Function to ensure at least one of each settlement type is placed
func place_initial_settlements(biomes, tiles, names):
	# Ensure placement of one capital city
	if capital_city_count < 1:
		place_settlement(biomes, tiles, "capitalcity", "res://assets/graphics/36x36-capitalcity.png", ["grass", "forest"], 5.0)

	# Ensure placement of one dwarf city
	if dwarf_city_count < 1:
		place_settlement(biomes, tiles, "dwarfcity", "res://assets/graphics/36x36-dwarfcity.png", ["mountains"], 3.0)

	# Ensure placement of one elf haven
	if elf_haven_count < 1:
		place_settlement(biomes, tiles, "elfhaven", "res://assets/graphics/36x36-elfhaven.png", ["forest"], 4.0)

	# Ensure placement of one old city
	if old_city_count < 1:
		place_settlement(biomes, tiles, "oldcity", "res://assets/graphics/36x36-oldcity.png", ["mountains", "forest"], 4.0)

	# Ensure placement of one small village
	if village_count < 3:
		place_settlement(biomes, tiles, "village", "res://assets/graphics/36x36-village.png", ["grass", "forest"], 3.0,)

# Modified place_settlement function
func place_settlement(biomes, tiles, biome_type, tile_path, allowed_biomes: Array, min_distance: float = 3.0):
	var attempts = 0
	
	while attempts < 100:  # Attempt placement until the maximum attempts are reached
		var x = randi() % GRID_SIZE
		var y = randi() % GRID_SIZE
		
		if biomes[y][x] in allowed_biomes:
			var can_place = true
			
			# Check the distance from other settlements
			for pos in settlement_positions:
				if calculate_distance(pos.x, pos.y, x, y) < min_distance:
					can_place = false
					break

			if can_place:
				biomes[y][x] = biome_type
				tiles[y][x] = tile_path
				settlement_positions.append(Vector2(x, y))

				match biome_type:
					"village":
						village_count += 1
					"elfhaven":
						elf_haven_count += 1
					"dwarfcity":
						dwarf_city_count += 1
					"oldcity":
						old_city_count += 1
					"capitalcity":
						capital_city_count += 1
					"northpass":
						northpass_count += 1
					"southpass":
						southpass_count += 1
					"westpass":
						westpass_count += 1
					"eastpass":
						eastpass_count += 1

				return  # Exit once the settlement is placed

		attempts += 1

func force_village_placement(biomes, tiles):
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if biomes[y][x] in ["ocean", "mountains", "forest"]:
				biomes[y][x] = "village"
				tiles[y][x] = "res://assets/graphics/36x36-village.png"
				settlement_positions.append(Vector2(x, y))
				village_count += 1
				return  # Exit once we've forced a placement

# Function to save the modified map data to a new file
func save_settlement_map_data(settlement_data: Dictionary):
	var json = JSON.new()
	var data_to_save = [settlement_data]
	var json_string = json.stringify(data_to_save, "\t")
	
	var file = FileAccess.open("user://worldgen/playing_map_settlements.json", FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Settlement map data saved successfully.")
	else:
		print("Error saving the settlement map data.")

# Function to start the settlement placement process
func place_settlements():
	var original_data = load_original_map_data()
	if original_data.size() == 0:
		return

	var settlement_data = create_settlement_map_data(original_data)
	save_settlement_map_data(settlement_data)

	# Optionally add a message to the log (assuming you have a method to do this)
	if culture_map:
		var log_vbox = culture_map.get_node("MessageLogControl/MessageLogPanel/MessageLogScroll/MessageLogVBox")
		if log_vbox:
			var new_message_label = Label.new()
			new_message_label.text = "Settlements Placed & Roads Built"
			culture_map.apply_font_styling_for_log(new_message_label)  # Apply the log styling
			log_vbox.add_child(new_message_label)
		else:
			print("MessageLogVBox not found!")
	else:
		print("CultureMap node not found!")
	# Call to reload the map display
	reload_map_display()

# Function to reload the map display
func reload_map_display():
	var map_display = culture_map.get_node("MapControl/SubViewportContainer/SubViewport/WorldTextureRect")
	if map_display:
		map_display.init_map_display("user://worldgen/playing_map_settlements.json")
	else:
		print("WorldTextureRect node not found!")
				
	$"/root/CultureMap".show_map_generated_window()
