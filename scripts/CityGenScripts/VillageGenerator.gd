extends Node

# Define the grid size for the village
const GRID_SIZE = 12
const MAX_TAVERNS = 4  # Maximum number of taverns allowed
const MAX_SLUMCHURCHES = 2  # Maximum number of slum churches
const MIN_SLUMCHURCHES = 1  # Minimum number of slum churches
const MAX_SLUMWORKHOUSES = 6  # Maximum number of slum workhouses
const MAX_COURTHOUSES = 1  # Maximum number of courthouses
const MAX_MANORS = 2  # Maximum number of manors allowed


# Paths to assets for different districts (biomes)
const V_GATE = "res://assets/worldmap-graphics/city-tiles/87x87-gate.png"
const V_TOWNCENTER = "res://assets/worldmap-graphics/city-tiles/87x87-vil-center.png"
const V_CHURCH = "res://assets/worldmap-graphics/city-tiles/87x87-vil-church.png"
const V_COURTHOUSE = "res://assets/worldmap-graphics/city-tiles/village/87x87-vch-1.png"
const V_TAVERN = "res://assets/worldmap-graphics/city-tiles/village/87x87-vt.png"
const V_MANOR = "res://assets/worldmap-graphics/city-tiles/village/87x87-vm-1.png"
const V_SLUMCHURCH = "res://assets/worldmap-graphics/city-tiles/village/87x87-vsc-1.png"
const V_SLUMWORKHOUSE = "res://assets/worldmap-graphics/city-tiles/village/87x87-vsw-1.png"

# Arrays of randomized tiles
const V_SLUMS = [
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vs-1.png",
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vs-2.png",
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vs-3.png",
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vs-4.png",
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vs-5.png",
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vs-6.png"
]

const V_COMMERCIAL = [
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vc-1.png",
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vc-2.png"
]

const V_RESIDENCE = [
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vr-1.png",
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vr-2.png",
	"res://assets/worldmap-graphics/city-tiles/village/87x87-vr-3.png"
]

# Placeholder for village grid
var biomes_grid = []
var names_grid = []
var tiles_grid = []
var bad_part_of_town_quadrant = 0  # This will store which quarter is the "bad part of town"
var transitional_area_quadrant = 0  # This will store the adjacent "transitional" area
var rich_quarter = 0  # This will store which quarter is the rich quarter
var trade_quarter = 0  # This will store which quarter is the trade quarter
var tavern_count = 0  # Track the number of taverns placed
var slumchurch_count = 0  # Track the number of slum churches placed
var slumworkhouse_count = 0  # Track the number of slum workhouses placed
var courthouse_count = 0  # Track the number of courthouses placed
var manor_count = 0  # Track the number of manors placed


# Main generate function called by the dispatcher
func generate(city_name: String):
	print("Generating village for city: ", city_name)
	
	# Initialize the grids
	initialize_grid()
	
	# Designate one quarter of the village as the "bad part of town" and its adjoining transitional area
	designate_quarters()

	# Step 1: Place unique biomes
	place_unique_biomes()
	
	# Step 2: Fill surrounding areas with appropriate biomes
	fill_surrounding_biomes()
	
	# Step 3: Randomize the remaining areas of the grid
	randomize_remaining_biomes()
	
	# Step 4: Save the generated village grid to the appropriate JSON file
	save_village_grid(city_name)

# Initializes the empty village grid
func initialize_grid():
	biomes_grid = []
	names_grid = []
	tiles_grid = []
	tavern_count = 0  # Reset tavern count
	slumchurch_count = 0  # Reset slum church count
	slumworkhouse_count = 0  # Reset slum workhouse count
	courthouse_count = 0  # Reset courthouse count
	for i in range(GRID_SIZE):
		var biome_row = []
		var name_row = []
		var tile_row = []
		for j in range(GRID_SIZE):
			biome_row.append("")  # Initialize with empty strings for biomes
			name_row.append("cell_" + str(i) + "_" + str(j))  # Assign default cell names
			tile_row.append("")  # Initialize with empty strings for tiles
		biomes_grid.append(biome_row)
		names_grid.append(name_row)
		tiles_grid.append(tile_row)

func designate_quarters():
	bad_part_of_town_quadrant = randi_range(1, 4)  # Randomly choose the bad part of town
	# The transitional area will always be an adjacent (not diagonal) quadrant
	if bad_part_of_town_quadrant == 1:
		transitional_area_quadrant = 2  # Top-right is adjacent to top-left
	elif bad_part_of_town_quadrant == 2:
		transitional_area_quadrant = 1  # Top-left is adjacent to top-right
	elif bad_part_of_town_quadrant == 3:
		transitional_area_quadrant = 4  # Bottom-right is adjacent to bottom-left
	else:
		transitional_area_quadrant = 3  # Bottom-left is adjacent to bottom-right

	# Designate the trade quarter to be adjacent to the town center
	trade_quarter = randi_range(1, 4)
	while trade_quarter == bad_part_of_town_quadrant or trade_quarter == transitional_area_quadrant:
		trade_quarter = randi_range(1, 4)

	# Designate the rich quarter to be different from the bad and trade quarters
	rich_quarter = randi_range(1, 4)
	while rich_quarter == bad_part_of_town_quadrant or rich_quarter == trade_quarter or rich_quarter == transitional_area_quadrant:
		rich_quarter = randi_range(1, 4)

	print("Bad part of town quadrant: ", bad_part_of_town_quadrant)
	print("Transitional area quadrant: ", transitional_area_quadrant)
	print("Trade quarter: ", trade_quarter)
	print("Rich quarter: ", rich_quarter)


func place_unique_biomes():
	# Place the gate at the bottom center of the grid
	biomes_grid[GRID_SIZE - 1][GRID_SIZE / 2] = "village-gate"
	tiles_grid[GRID_SIZE - 1][GRID_SIZE / 2] = V_GATE
	
	# Place the town center in the middle of the village
	biomes_grid[GRID_SIZE / 2][GRID_SIZE / 2] = "village-center"
	tiles_grid[GRID_SIZE / 2][GRID_SIZE / 2] = V_TOWNCENTER
	
	# Place 1-3 churches in random locations, outside of the bad part of town
	var num_churches = randi_range(1, 3)
	for i in range(num_churches):
		var placed = false
		while not placed:
			var rand_x = randi_range(0, GRID_SIZE - 1)
			var rand_y = randi_range(0, GRID_SIZE - 1)
			if biomes_grid[rand_y][rand_x] == "" and not is_in_bad_or_transitional_area(rand_y, rand_x):
				biomes_grid[rand_y][rand_x] = "village-church"
				tiles_grid[rand_y][rand_x] = V_CHURCH
				placed = true
	
		# Declare 'placed' before the courthouse placement to avoid scoping issues
		placed = false
		# Place exactly 1 courthouse near the town center
		if courthouse_count < MAX_COURTHOUSES:
			while not placed and courthouse_count < MAX_COURTHOUSES:
				var rand_x = randi_range(GRID_SIZE / 2 - 1, GRID_SIZE / 2 + 1)
				var rand_y = randi_range(GRID_SIZE / 2 - 1, GRID_SIZE / 2 + 1)
				if biomes_grid[rand_y][rand_x] == "":
					biomes_grid[rand_y][rand_x] = "village-courthouse"
					tiles_grid[rand_y][rand_x] = V_COURTHOUSE
					courthouse_count += 1
					placed = true

		# Place 1-2 manors near the center of the village, but outside the bad and transitional areas
		while manor_count < MAX_MANORS:
			placed = false
			while not placed:
				var rand_x = randi_range(GRID_SIZE / 2 - 2, GRID_SIZE / 2 + 2)
				var rand_y = randi_range(GRID_SIZE / 2 - 2, GRID_SIZE / 2 + 2)
				if biomes_grid[rand_y][rand_x] == "" and not is_in_bad_or_transitional_area(rand_y, rand_x):
					biomes_grid[rand_y][rand_x] = "village-manor"
					tiles_grid[rand_y][rand_x] = V_MANOR
					manor_count += 1
					placed = true

# Fills the trade quarter and rich quarter with appropriate biomes
func fill_surrounding_biomes():
	# Fill trade quarter mostly with commercial districts
	fill_quarter_with_commercial(trade_quarter, 0.7)  # 70% commercial in trade quarter
	
	# Fill rich quarter with a few commercial areas and mostly residential
	fill_quarter_with_commercial(rich_quarter, 0.2)  # 20% commercial in rich quarter

	# Fill the bad part of town with slums, slum churches, and slum workhouses
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if biomes_grid[i][j] == "" and is_in_bad_part_of_town(i, j):
				var rand_biome = choose_slum_biome()
				biomes_grid[i][j] = rand_biome
				tiles_grid[i][j] = assign_tile(rand_biome)

# Fills a designated quarter with a mix of commercial and residential areas
func fill_quarter_with_commercial(quarter: int, commercial_probability: float):
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if biomes_grid[i][j] == "" and is_in_quarter(quarter, i, j):
				var biome = choose_biome(["village-commercial", "village-residence"], [commercial_probability, 1 - commercial_probability], i, j)
				biomes_grid[i][j] = biome
				tiles_grid[i][j] = assign_tile(biome)

# Randomizes the rest of the village grid with residence, slums, and commercial areas
func randomize_remaining_biomes():
	for i in range(GRID_SIZE):
		for j in range(GRID_SIZE):
			if biomes_grid[i][j] == "":
				biomes_grid[i][j] = random_biome(i, j)
				tiles_grid[i][j] = assign_tile(biomes_grid[i][j])

# Checks if a grid location is in a specific quarter
func is_in_quarter(quarter: int, row: int, col: int) -> bool:
	match quarter:
		1:  # Top-left quadrant
			return row < GRID_SIZE / 2 and col < GRID_SIZE / 2
		2:  # Top-right quadrant
			return row < GRID_SIZE / 2 and col >= GRID_SIZE / 2
		3:  # Bottom-left quadrant
			return row >= GRID_SIZE / 2 and col < GRID_SIZE / 2
		4:  # Bottom-right quadrant
			return row >= GRID_SIZE / 2 and col >= GRID_SIZE / 2
	return false


# Returns a slum-specific biome
func choose_slum_biome() -> String:
	# Ensure at least 1 slumchurch is generated
	if slumchurch_count < MIN_SLUMCHURCHES:
		slumchurch_count += 1
		return "village-slumchurch"
	elif slumchurch_count < MAX_SLUMCHURCHES and randf() < 0.2:
		slumchurch_count += 1
		return "village-slumchurch"
	elif slumworkhouse_count < MAX_SLUMWORKHOUSES and randf() < 0.4:
		slumworkhouse_count += 1
		return "village-slumworkhouse"
	else:
		return "village-slums"

# Helper function to choose a biome based on chances, with tavern limits enforced and spaced out
func choose_biome(biomes: Array, chances: Array, row: int, col: int) -> String:
	var rand = randf()
	var cumulative = 0.0
	for i in range(biomes.size()):
		if biomes[i] == "village-tavern" and tavern_count >= MAX_TAVERNS:
			continue  # Skip tavern if we've reached the max count
		
		if biomes[i] == "village-tavern" and tavern_is_adjacent(row, col):
			continue  # Skip if there's already a tavern adjacent

		cumulative += chances[i]
		if rand <= cumulative:
			if biomes[i] == "village-tavern":
				tavern_count += 1  # Increment tavern count when a tavern is placed
			return biomes[i]
	return biomes[0]  # Default fallback

# Update how choose_biome is called in random_biome()
func random_biome(row: int, col: int) -> String:
	# Check if the location is in the "bad part of town" or transitional area
	if is_in_bad_part_of_town(row, col):
		return choose_slum_biome()
	elif is_in_transitional_area(row, col):
		return choose_biome(["village-residence", "village-slums", "village-tavern"], [0.4, 0.4, 0.2], row, col)
	
	# Else use default randomization for other parts of the village
	return choose_biome(["village-residence", "village-commercial", "village-tavern"], [0.6, 0.3, 0.1], row, col)


# Checks if a tavern is adjacent to a given location
func tavern_is_adjacent(row: int, col: int) -> bool:
	var adjacent_offsets = [
		Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0),
		Vector2(1, 1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, -1)
	]
	
	for offset in adjacent_offsets:
		var check_row = row + int(offset.x)
		var check_col = col + int(offset.y)
		
		if check_row >= 0 and check_row < GRID_SIZE and check_col >= 0 and check_col < GRID_SIZE:
			if biomes_grid[check_row][check_col] == "village-tavern":
				return true  # Tavern found adjacent
	return false

# Checks if a grid location is in the bad part of town
func is_in_bad_part_of_town(row: int, col: int) -> bool:
	match bad_part_of_town_quadrant:
		1:  # Top-left quadrant
			return row < GRID_SIZE / 2 and col < GRID_SIZE / 2
		2:  # Top-right quadrant
			return row < GRID_SIZE / 2 and col >= GRID_SIZE / 2
		3:  # Bottom-left quadrant
			return row >= GRID_SIZE / 2 and col < GRID_SIZE / 2
		4:  # Bottom-right quadrant
			return row >= GRID_SIZE / 2 and col >= GRID_SIZE / 2
	return false

# Checks if a grid location is in the transitional area
func is_in_transitional_area(row: int, col: int) -> bool:
	match transitional_area_quadrant:
		1:  # Top-left quadrant
			return row < GRID_SIZE / 2 and col < GRID_SIZE / 2
		2:  # Top-right quadrant
			return row < GRID_SIZE / 2 and col >= GRID_SIZE / 2
		3:  # Bottom-left quadrant
			return row >= GRID_SIZE / 2 and col < GRID_SIZE / 2
		4:  # Bottom-right quadrant
			return row >= GRID_SIZE / 2 and col >= GRID_SIZE / 2
	return false

# Checks if a grid location is in either the bad part or transitional area
func is_in_bad_or_transitional_area(row: int, col: int) -> bool:
	return is_in_bad_part_of_town(row, col) or is_in_transitional_area(row, col)

# Assigns tile paths based on the biome type
func assign_tile(biome: String) -> String:
	match biome:
		"village-slums":
			return get_random_slum_tile()
		"village-slumworkhouse":
			return V_SLUMWORKHOUSE
		"village-slumchurch":
			return V_SLUMCHURCH
		"village-residence":
			return get_random_residential_tile()
		"village-commercial":
			return get_random_commercial_tile()
		"village-gate":
			return V_GATE
		"village-center":
			return V_TOWNCENTER
		"village-church":
			return V_CHURCH
		"village-courthouse":
			return V_COURTHOUSE
		"village-manor":
			return V_MANOR
		"village-tavern":
			return V_TAVERN
		_:
			return ""  # Default if no match found

# Returns a random slum tile from the array
func get_random_slum_tile() -> String:
	return V_SLUMS[randi_range(0, V_SLUMS.size() - 1)]

# Returns a random commercial tile from the array
func get_random_commercial_tile() -> String:
	return V_COMMERCIAL[randi_range(0, V_COMMERCIAL.size() - 1)]

# Returns a random residential tile from the array
func get_random_residential_tile() -> String:
	return V_RESIDENCE[randi_range(0, V_RESIDENCE.size() - 1)]

# Saves the generated village grid as a JSON file
func save_village_grid(city_name: String):
	var save_path = LoadHandlerSingleton.get_save_file_path() + "chunks/" + city_name.replace(" ", "_") + "_grid.json"
	
	var village_data = {
		"grid": {
			"biomes": biomes_grid,
			"names": names_grid,
			"tiles": tiles_grid
		},
		"world_name": "Village - " + city_name
	}
	
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(village_data, "\t"))
		save_file.close()
		print("Village grid saved to: ", save_path)
	else:
		print("Error saving village grid.")
