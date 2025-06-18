extends Node

const TEXTURE_WOODBOTTOM_WINDOW = preload("res://assets/localmap-graphics/woodwallbottomwindow.png")
const TEXTURE_WOOD_WINDOW_SIDE = preload("res://assets/localmap-graphics/woodwallsidewindow.png")
const TEXTURE_GRASS = preload("res://assets/localmap-graphics/grass.png")
const TEXTURE_PATH = preload("res://assets/localmap-graphics/path.png")
const TEXTURE_WOOD_FLOOR = preload("res://assets/localmap-graphics/woodfloor.png")
const TEXTURE_WOOD_WALL = preload("res://assets/localmap-graphics/woodwallside.png")
const TEXTURE_DOOR = preload("res://assets/localmap-graphics/wooddoor.png")
const TEXTURE_CHEST = preload("res://assets/localmap-graphics/woodchest.png")
const TEXTURE_BED = preload("res://assets/localmap-graphics/bed.png")
const TEXTURE_WOOD_WALL_BOTTOM = preload("res://assets/localmap-graphics/woodwallbottom.png")
const TEXTURE_TREE = preload("res://assets/localmap-graphics/tree.png")
const TEXTURE_BUSH = preload("res://assets/localmap-graphics/bush.png")

const ROOM_SIZES = [
	Vector2(2,2), Vector2(3,3), Vector2(3,1),
	Vector2(1,3), Vector2(3,2), Vector2(2,3)
]

func generate_house():
	var main_room = ROOM_SIZES.pick_random()
	var width = int(main_room.x)
	var height = int(main_room.y)

	var layout_padding = 5  
	var house_layout = []
	for x in range(width + 9 + layout_padding * 2):
		house_layout.append([])
		for y in range(height + 9 + layout_padding * 2):
			house_layout[x].append(null)

	var start_x = layout_padding + 2
	var start_y = layout_padding + 2
	place_room(house_layout, start_x, start_y, width, height)

	# 🚀 Generate extra rooms 
	var num_extra_rooms = randi_range(4, 8)
	var room_positions = [Vector2(start_x, start_y)]
	var extra_room_count = 1  

	var directions = [Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0), Vector2(0, -1)]
	var failed_positions = {}  
	var max_attempts = 10  
	var attempt_count = 0

	while extra_room_count < num_extra_rooms and attempt_count < max_attempts:
		var extra_room = ROOM_SIZES.pick_random()
		var base_room = room_positions[randi() % room_positions.size()]

		for attach_dir in directions:
			var attach_x = base_room.x + attach_dir.x * (int(extra_room.x))
			var attach_y = base_room.y + attach_dir.y * (int(extra_room.y))
			var attach_pos = Vector2(attach_x, attach_y)

			if attach_pos in failed_positions:
				continue

			if is_area_clear(house_layout, attach_x, attach_y, int(extra_room.x), int(extra_room.y)):
				place_room(house_layout, attach_x, attach_y, int(extra_room.x), int(extra_room.y))
				room_positions.append(Vector2(attach_x, attach_y))
				extra_room_count += 1
				attempt_count = 0  
				break  
			else:
				failed_positions[attach_pos] = true  

		attempt_count += 1
	if get_tree():
		await get_tree().process_frame  # 🚀 Allow rendering while generating

	var forced_attempts = 0
	while extra_room_count < 4 and forced_attempts < 3:
		var forced_room = ROOM_SIZES.pick_random()
		var force_x = start_x + randi_range(-4, 4)
		var force_y = start_y + randi_range(-4, 4)

		if is_area_clear(house_layout, force_x, force_y, int(forced_room.x), int(forced_room.y)):
			place_room(house_layout, force_x, force_y, int(forced_room.x), int(forced_room.y))
			room_positions.append(Vector2(force_x, force_y))
			extra_room_count += 1

		forced_attempts += 1
	if get_tree():
		await get_tree().process_frame  

	house_layout = add_walls(house_layout)
	if get_tree():
		await get_tree().process_frame  

	house_layout = add_doors(house_layout)
	if get_tree():
		await get_tree().process_frame  

	house_layout = windowgen(house_layout)
	if get_tree():
		await get_tree().process_frame  

	house_layout = fix_rooms_and_connect(house_layout)
	if get_tree():
		await get_tree().process_frame  

	house_layout = replace_null_tiles(house_layout)
	if get_tree():
		await get_tree().process_frame  

	house_layout = replace_walls_with_bottom_variant(house_layout)  # 🔥 FINAL STEP
	if get_tree():
		await get_tree().process_frame  

	return house_layout

func replace_walls_with_bottom_variant(house):
	var width = house.size()
	var height = house[0].size()

	for x in range(width):
		for y in range(height - 1):  # Avoid out-of-bounds checking below
			if house[x][y] == TEXTURE_WOOD_WALL:
				var below_tile = house[x][y + 1]
				
				# ✅ If the tile below is one of the valid ground tiles, replace the wall
				if below_tile in [TEXTURE_PATH, TEXTURE_GRASS, TEXTURE_BUSH, TEXTURE_TREE, TEXTURE_WOOD_FLOOR]:
					house[x][y] = TEXTURE_WOOD_WALL_BOTTOM  # 🔥 Convert to bottom variant

	return house


func place_room(house, x, y, width, height):
	for i in range(width):
		for j in range(height):
			var nx = x + i
			var ny = y + j

			# ✅ If it's an empty space OR an existing wall, convert it into a floor
			if is_within_bounds(house, nx, ny) and (house[nx][ny] == null or house[nx][ny] == TEXTURE_WOOD_WALL):
				house[nx][ny] = TEXTURE_WOOD_FLOOR
				
func pick_random_direction():
	var directions = [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]
	directions.shuffle()
	return directions[0]

func is_within_bounds(house, x, y):
	return x >= 0 and y >= 0 and x < house.size() and y < house[0].size()

func has_other_possible_entry(house, floor_tile):
	for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:  # Cardinal directions only
		var nx = floor_tile.x + dir.x
		var ny = floor_tile.y + dir.y
		if is_within_bounds(house, nx, ny) and house[nx][ny] == TEXTURE_DOOR:
			return true  # ✅ Found another door nearby

	return false  # ❌ No other door found


func is_area_clear(house, x, y, width, height):
	var boundary_padding = 2  # 🚨 Prevent rooms from touching the absolute boundary
	var room_padding = 1  # ✅ Allow rooms to be 1 tile apart (prevents double walls)
	
	var max_x = house.size() - width - boundary_padding
	var max_y = house[0].size() - height - boundary_padding

	# 🚨 Prevent rooms from touching the **absolute boundary**
	if x < boundary_padding or y < boundary_padding or x > max_x or y > max_y:
		return false

	var has_valid_edge_connection = false

	# ✅ Prevent **overlapping** and **double wall issues**
	for i in range(-room_padding, width + room_padding):
		for j in range(-room_padding, height + room_padding):
			var nx = x + i
			var ny = y + j

			if is_within_bounds(house, nx, ny):
				# 🚨 If there's already a room **OR** wall, reject placement
				if house[nx][ny] == TEXTURE_WOOD_FLOOR or house[nx][ny] == TEXTURE_WOOD_WALL:
					return false  

				# ✅ Ensure at least **one** valid edge connection
				if (is_within_bounds(house, nx + 1, ny) and house[nx + 1][ny] == TEXTURE_WOOD_FLOOR) or \
				   (is_within_bounds(house, nx - 1, ny) and house[nx - 1][ny] == TEXTURE_WOOD_FLOOR) or \
				   (is_within_bounds(house, nx, ny + 1) and house[nx][ny + 1] == TEXTURE_WOOD_FLOOR) or \
				   (is_within_bounds(house, nx, ny - 1) and house[nx][ny - 1] == TEXTURE_WOOD_FLOOR):
					has_valid_edge_connection = true

	# ✅ Allow isolated rooms **sometimes** (40% chance) for variety
	if not has_valid_edge_connection and randf() < 0.4:
		return true  

	return has_valid_edge_connection  


func add_walls(house):
	var width = house.size()
	var height = house[0].size()

	# ✅ Place Walls, Keeping Diagonal Walls
	for x in range(width):
		for y in range(height):
			if house[x][y] == TEXTURE_WOOD_FLOOR:
				for dir in [
					Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1),  # Cardinal
					Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)  # Diagonal
				]:
					var nx = x + dir.x
					var ny = y + dir.y
					if is_within_bounds(house, nx, ny) and house[nx][ny] == null:
						house[nx][ny] = TEXTURE_WOOD_WALL

	return house

func add_doors(house):
	var width = house.size()
	var height = house[0].size()
	var visited = {}
	var exterior_door_added = false
	var all_rooms = []

	# ✅ Step 1: Find all rooms using flood fill
	for x in range(width):
		for y in range(height):
			if house[x][y] == TEXTURE_WOOD_FLOOR and not visited.has(Vector2(x, y)):
				var room_tiles = flood_fill(house, x, y, visited)
				all_rooms.append(room_tiles)

	# ✅ Step 2: Ensure every room connects to another room
	for room in all_rooms:
		var connected = false
		for tile in room:
			var x = int(tile.x)
			var y = int(tile.y)

			# Check walls around this floor tile
			for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:  # Left, Right, Up, Down
				var nx = x + dir.x
				var ny = y + dir.y

				# 🚀 Ensure we're within bounds and it's a wall
				if is_within_bounds(house, nx, ny) and house[nx][ny] == TEXTURE_WOOD_WALL:
					
					# ✅ Check if there's ANOTHER wall in the same direction (invalid)
					var beyond_nx = nx + dir.x
					var beyond_ny = ny + dir.y
					if is_within_bounds(house, beyond_nx, beyond_ny) and house[beyond_nx][beyond_ny] == TEXTURE_WOOD_WALL:
						continue  # 🚫 Skip this door placement, it's invalid

					# ✅ If the wall is valid, check if it separates two rooms
					for neighbor_dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
						var nnx = nx + neighbor_dir.x
						var nny = ny + neighbor_dir.y
						if is_within_bounds(house, nnx, nny) and house[nnx][nny] == TEXTURE_WOOD_FLOOR:
							house[nx][ny] = TEXTURE_DOOR  # ✅ Place door
							connected = true
							break
				if connected:
					break
			if connected:
				break

	# ✅ Step 3: Ensure at least one **exterior** door
	var door_exists = false
	for x in range(width):
		for y in range(height):
			if house[x][y] == TEXTURE_DOOR:
				door_exists = true  # ✅ A door already exists
				break
	
	# 🚀 If no doors exist, add one
	if not door_exists:
			for x in range(1, width - 1):
				for y in range(1, height - 1):
					if house[x][y] == TEXTURE_WOOD_WALL and is_exterior_wall(house, x, y):
						for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
							var nx = x + dir.x
							var ny = y + dir.y
							if is_within_bounds(house, nx, ny) and house[nx][ny] in [TEXTURE_PATH, TEXTURE_GRASS, TEXTURE_BUSH]:
								house[x][y] = TEXTURE_DOOR
								exterior_door_added = true
								break
					if exterior_door_added:
						break
				if exterior_door_added:
					break
	# ✅ FINAL STEP: Make sure every room has access to an exterior door
	house = ensure_all_rooms_have_access(house)
	
	return house





func replace_null_tiles(house):
	var width = house.size()
	var height = house[0].size()

	for x in range(width):
		for y in range(height):
			if house[x][y] == null:
				var rand_val = randi() % 100  # Randomize tile placement

				if rand_val < 60:  # ✅ 60% chance for path (default)
					house[x][y] = TEXTURE_PATH
				elif rand_val < 85:  # ✅ 25% chance for grass
					house[x][y] = TEXTURE_GRASS
				elif rand_val < 95:  # ✅ 10% chance for bushes
					house[x][y] = TEXTURE_BUSH
				else:  # ✅ 5% chance for a tree (rare)
					house[x][y] = TEXTURE_TREE

	return house


func flood_fill(house, x, y, visited):
	var stack = [Vector2(x, y)]
	var room_tiles = []

	while stack.size() > 0:
		var tile = stack.pop_back()
		if visited.has(tile):
			continue
		visited[tile] = true
		room_tiles.append(tile)

		for dir in [
			Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1),  
			Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)
		]:
			var nx = tile.x + dir.x
			var ny = tile.y + dir.y
			if is_within_bounds(house, nx, ny) and house[nx][ny] == TEXTURE_WOOD_FLOOR and not visited.has(Vector2(nx, ny)):
				stack.append(Vector2(nx, ny))

	return room_tiles


func fix_rooms_and_connect(house):
	var width = house.size()
	var height = house[0].size()
	var visited = {}

	var all_rooms = []
	for x in range(width):
		for y in range(height):
			if house[x][y] == TEXTURE_WOOD_FLOOR and not visited.has(Vector2(x, y)):
				var room_tiles = flood_fill(house, x, y, visited)
				
				# 🚨 REMOVE **TINY** ROOMS TO PREVENT JUNK
				if room_tiles.size() > 3:  # ⬅ Small rooms under 3 tiles are discarded
					all_rooms.append(room_tiles)
				else:
					# ✅ Convert tiny rooms to normal floors to prevent weird gaps
					for tile in room_tiles:
						house[int(tile.x)][int(tile.y)] = TEXTURE_WOOD_FLOOR

	# ✅ Ensure rooms are connected
	for i in range(all_rooms.size() - 1):
		var room1 = all_rooms[i]
		var room2 = all_rooms[i + 1]
		var closest_tile1 = null
		var closest_tile2 = null
		var min_distance = 99999

		for tile1 in room1:
			for tile2 in room2:
				var dist = tile1.distance_to(tile2)
				if dist < min_distance:
					min_distance = dist
					closest_tile1 = tile1
					closest_tile2 = tile2

		#if closest_tile1 and closest_tile2:
			#carve_passage(house, closest_tile1, closest_tile2)

	return house

func carve_passage(house, start, end):
	var start_x = int(start.x)
	var start_y = int(start.y)
	var end_x = int(end.x)
	var end_y = int(end.y)

	# ✅ First, connect horizontally
	for x in range(min(start_x, end_x), max(start_x, end_x) + 1):
		if is_within_bounds(house, x, start_y) and house[x][start_y] != TEXTURE_WOOD_WALL:
			house[x][start_y] = TEXTURE_WOOD_FLOOR

	# ✅ Then, connect vertically
	for y in range(min(start_y, end_y), max(start_y, end_y) + 1):
		if is_within_bounds(house, end_x, y) and house[end_x][y] != TEXTURE_WOOD_WALL:
			house[end_x][y] = TEXTURE_WOOD_FLOOR

	return house


func has_floor_neighbor(house, x, y):
	var width = house.size()
	var height = house[0].size()

	for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		var nx = x + dir.x
		var ny = y + dir.y

		if nx >= 0 and ny >= 0 and nx < width and ny < height:
			if house[nx][ny] == TEXTURE_WOOD_FLOOR:
				return true

	return false


func windowgen(house):
	if house == null or not house is Array or house.size() == 0:
		print("ERROR: House data is missing or not initialized in windowgen()!")
		return house  # Prevents crash

	var width = house.size()
	var height = house[0].size() if width > 0 else 0

	if height == 0:
		print("ERROR: House array is malformed in windowgen()!")
		return house

	# ✅ Now, safely loop through `house`
	for x in range(width):
		for y in range(height):
			if house[x][y] == TEXTURE_WOOD_WALL and is_exterior_wall(house, x, y):
				if has_floor_neighbor(house, x, y) and randi() % 100 < 20:
					house[x][y] = TEXTURE_WOOD_WINDOW_SIDE
					
	return house


func is_exterior_wall(house, x, y):
	# ✅ If there’s empty space (path, grass, bush, tree) nearby, it's an exterior wall
	for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		var nx = x + dir.x
		var ny = y + dir.y
		if is_within_bounds(house, nx, ny) and house[nx][ny] in [TEXTURE_PATH, TEXTURE_GRASS, TEXTURE_BUSH, TEXTURE_TREE]:
			return true  # ✅ This wall touches the outside
	return false  # 🚫 Internal wall—NO doors or windows here

func ensure_all_rooms_have_access(house):
	var width = house.size()
	var height = house[0].size()
	var visited = {}

	# ✅ Step 1: Flood fill from all exterior doors
	var start_positions = []
	for x in range(width):
		for y in range(height):
			if house[x][y] == TEXTURE_DOOR and is_exterior_door(house, x, y):
				start_positions.append(Vector2(x, y))

	# ✅ Step 2: Mark all connected rooms
	for start_pos in start_positions:
		flood_fill(house, start_pos.x, start_pos.y, visited)

	# 🚨 Step 3: Find truly isolated rooms
	var isolated_rooms = []
	for x in range(width):
		for y in range(height):
			if house[x][y] == TEXTURE_WOOD_FLOOR and not visited.has(Vector2(x, y)):
				isolated_rooms.append(Vector2(x, y))

	# 🔥 Step 4: Connect each isolated room to the nearest connected area
	for isolated in isolated_rooms:
		var best_wall = find_closest_reachable_tile(house, isolated, visited)
		if best_wall:
			house[best_wall.x][best_wall.y] = TEXTURE_DOOR  # ✅ Break the wall to ensure connectivity
			print("DEBUG: Fixed isolation by placing door at ", best_wall)

	# ✅ Step 5: **Rerun flood fill after door placement**
	visited.clear()  # Reset visited to ensure full connectivity
	for start_pos in start_positions:
		flood_fill(house, start_pos.x, start_pos.y, visited)

	return house



func find_closest_door(house, start):
	var width = house.size()
	var height = house[0].size()

	var closest_door = null
	var min_distance = 99999

	for x in range(width):
		for y in range(height):
			if house[x][y] == TEXTURE_DOOR:
				var dist = start.distance_to(Vector2(x, y))
				if dist < min_distance:
					min_distance = dist
					closest_door = Vector2(x, y)

	return closest_door


func is_exterior_door(house, x, y):
	for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		var nx = x + dir.x
		var ny = y + dir.y
		if is_within_bounds(house, nx, ny) and house[nx][ny] in [TEXTURE_PATH, TEXTURE_GRASS, TEXTURE_BUSH, TEXTURE_TREE]:
			return true  # ✅ This door leads outside
	return false  # 🚫 This is just an internal door

func find_closest_reachable_tile(house, start, visited):
	var width = house.size()
	var height = house[0].size()

	var best_wall = null
	var min_distance = 99999

	for x in range(width):
		for y in range(height):
			if house[x][y] == TEXTURE_WOOD_WALL:  # ✅ Ensure it's a wall separating rooms
				# Check if this wall has a floor on one side and a visited tile on the other
				var has_connected_side = false
				var has_isolated_side = false
				var wall_position = Vector2(x, y)

				for dir in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
					var nx = x + dir.x
					var ny = y + dir.y
					if is_within_bounds(house, nx, ny):
						if house[nx][ny] == TEXTURE_WOOD_FLOOR:
							if visited.has(Vector2(nx, ny)):
								has_connected_side = true
							else:
								has_isolated_side = true

				# ✅ Only consider walls that actually separate a connected and an isolated room
				if has_connected_side and has_isolated_side:
					var dist = start.distance_to(wall_position)
					if dist < min_distance:
						min_distance = dist
						best_wall = wall_position

	return best_wall  # ✅ Always returns a separating wall, not a random tile!


