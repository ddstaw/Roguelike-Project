extends CharacterBody2D

# 🕒 Held movement timing
var is_moving := false
var held_direction := Vector2i.ZERO
var move_repeat_delay := 0.25  # Delay before repeat starts
var move_repeat_rate := 0.1    # Time between repeated steps
var move_timer := 0.0
var last_grid_position := Vector2i(-1, -1)


signal fov_updated(tiles)


func _ready():
	var looks = LoadHandlerSingleton.load_player_looks()
	if looks != null:
		apply_appearance(looks)

func _process(delta):
	if is_moving:
		move_timer -= delta
		if move_timer <= 0:
			move_player(held_direction)
			move_timer = move_repeat_rate


func apply_appearance(data: Dictionary) -> void:
	set_sprite_texture($BaseSprite, data.get("base", ""))
	set_sprite_texture($ArmorSprite, data.get("armor", ""))
	set_sprite_texture($CapeSprite, data.get("cape", ""))
	set_sprite_texture($HatSprite, data.get("hat", ""))
	set_sprite_texture($MainWeaponSprite, data.get("main_weapon", ""))
	set_sprite_texture($OffhandSprite, data.get("offhand", ""))

func set_sprite_texture(sprite: Sprite2D, path: String) -> void:
	if path != "":
		sprite.texture = load(path)
	else:
		sprite.texture = null

const TILE_SIZE = 88  # Change this if needed to match your tiles

func _unhandled_input(event):
	if event.is_pressed():
		if event.is_action("interact"):
			handle_interact()
		elif event.is_action("interact_egress"):  # 👈 Add this
			handle_egress_check()
		elif event.is_action("up_move"):
			start_held_move(Vector2i(0, -1))
		elif event.is_action("down_move"):
			start_held_move(Vector2i(0, 1))
		elif event.is_action("left_move"):
			start_held_move(Vector2i(-1, 0))
		elif event.is_action("right_move"):
			start_held_move(Vector2i(1, 0))
		elif event.is_action("upleft_move"):
			start_held_move(Vector2i(-1, -1))
		elif event.is_action("upright_move"):
			start_held_move(Vector2i(1, -1))
		elif event.is_action("downleft_move"):
			start_held_move(Vector2i(-1, 1))
		elif event.is_action("downright_move"):
			start_held_move(Vector2i(1, 1))
		elif event.is_action("rest_select"):
			rest_player()

	elif event.is_released():
		is_moving = false
		held_direction = Vector2.ZERO


func move_player(dir: Vector2i):
	var target_pos = position + Vector2(dir * TILE_SIZE)
	var target_tile = Vector2i(round(target_pos.x / TILE_SIZE), round(target_pos.y / TILE_SIZE))

	var local_map = get_tree().root.get_node("LocalMap")
	if local_map == null:
		print("❌ Cannot find LocalMap!")
		return

	# 🧭 Check for chunk transition BEFORE anything else
	if local_map.check_for_chunk_transition(target_tile):
		print("📦 Chunk transition triggered — skipping local movement.")
		return  # ⛔ Skip movement if chunk transition occurs (blocked or successful)

	# 🚪 Check for closed door and try to open it
	var tile_dict = local_map.get_tile_chunk().get("tile_grid", {})
	var target_key = "%d_%d" % [target_tile.x, target_tile.y]

	if tile_dict.has(target_key):
		var tile_data = tile_dict[target_key]
		var tile_type = tile_data.get("tile", "")
		if Constants.is_door(tile_type):
			var state = tile_data.get("state", {})
			if not state.get("is_open", false):
				open_door_at(target_tile)
				local_map.rebuild_walkability()
				return  # Stop movement for this turn; just open the door
	# 🔍 Get walkability after any door changes
	var walkability_grid = local_map.walkability_grid

	# 🛑 Bounds + walkability check
	if target_tile.y >= 0 and target_tile.y < walkability_grid.size():
		if target_tile.x >= 0 and target_tile.x < walkability_grid[0].size():
			var cell_data = walkability_grid[target_tile.y][target_tile.x]
			if not cell_data["walkable"]:
				print("🚫 Movement blocked at:", target_tile, "| Terrain or object is not walkable!")
				return

	# ✅ Actually move the player
	position = target_pos
	for pos in local_map.current_visible_tiles.keys():
		local_map.light_overlay.dirty_tiles[pos] = true

	# 🔁 Update FOV if needed
	var current_grid_pos = Vector2i(round(position.x / TILE_SIZE), round(position.y / TILE_SIZE))
	if current_grid_pos != last_grid_position:
		last_grid_position = current_grid_pos
		local_map.update_fov_from_player(current_grid_pos)

	# 🌞 Recalculate sunlight
	if local_map.has_method("calculate_sunlight_levels"):
		local_map.calculate_sunlight_levels()

	# ⏳ Time passes
	TimeManager.pass_minutes(1)

	# 📊 Refresh HUD and stats
	local_map.update_time_label()
	local_map.update_local_flavor_image()
	local_map.update_date_label()
	local_map.update_local_progress_bars()
	apply_movement_stat_effects()
	local_map.update_object_visibility(current_grid_pos)
	print("📍 Player moved to local tile:", current_grid_pos)  # 🆕 Add this!


func start_held_move(dir: Vector2i):
	move_player(dir)  # Immediate step
	held_direction = dir
	is_moving = true
	move_timer = move_repeat_delay  # Wait before repeat kicks in

func rest_player():
	var stats_data = LoadHandlerSingleton.get_combat_stats()
	var stats = stats_data.get("combat_stats", {})

	# Gently restore stats on rest
	stats["fatigue"]["current"] = min(stats["fatigue"]["current"] + 5, stats["fatigue"]["max"])
	stats["stamina"]["current"] = min(stats["stamina"]["current"] + 5, stats["stamina"]["max"])
	stats["sanity"]["current"] = min(stats["sanity"]["current"] + 2, stats["sanity"]["max"])
	stats["hunger"]["current"] = max(stats["hunger"]["current"] - 2, 0)

	# Save updated stats
	LoadHandlerSingleton.save_combat_stats(stats_data)

	# Advance time by e.g. 30 minutes
	TimeManager.pass_minutes(30)

	# 🌞 Force full light texture update (if lighting conditions changed)
	if get_tree().root.has_node("LocalMap"):
		var local_map = get_tree().root.get_node("LocalMap")
		for y in range(local_map.walkability_grid.size()):
			for x in range(local_map.walkability_grid[y].size()):
				local_map.light_overlay.dirty_tiles[Vector2i(x, y)] = true

	# Refresh HUD
	if get_tree().root.has_node("LocalMap"):
		var local_map = get_tree().root.get_node("LocalMap")
		
		# ✅ Update light levels
		local_map.calculate_sunlight_levels()

		# ✅ Refresh object visibility (this is the fix)
		var grid_pos := Vector2i(position.x / TILE_SIZE, position.y / TILE_SIZE)
		local_map.update_object_visibility(grid_pos)
		
		local_map.update_time_label()
		local_map.update_local_flavor_image()
		local_map.update_date_label()
		local_map.update_local_progress_bars()

	print("🛌 Player rested. Stats restored. Time advanced.")

func apply_movement_stat_effects():
	var combat_stats_data = LoadHandlerSingleton.get_combat_stats()
	var stats = combat_stats_data.get("combat_stats", {})

	stats["hunger"]["current"] = max(stats["hunger"]["current"] - 0.1, 0)
	stats["fatigue"]["current"] = max(stats["fatigue"]["current"] - 0.1, 0)

	# Save it
	LoadHandlerSingleton.save_combat_stats(combat_stats_data)
	
func open_door_at(pos: Vector2i):
	var local_map = get_tree().root.get_node("LocalMap")
	if local_map == null:
		print("❌ Cannot find LocalMap!")
		return

	var tile_chunk = local_map.get_tile_chunk()
	var tile_dict = tile_chunk.get("tile_grid", {})
	var key = "%d_%d" % [pos.x, pos.y]

	if not tile_dict.has(key):
		print("❌ No tile found at", key)
		return

	var tile_info = tile_dict[key]
	if typeof(tile_info.get("state", null)) != TYPE_DICTIONARY:
		tile_info["state"] = {}

	var current_tile = tile_info.get("tile", "")
	if Constants.DOOR_PAIRS.has(current_tile):
		tile_info["tile"] = Constants.DOOR_PAIRS[current_tile]

	tile_info["state"]["is_open"] = true
	tile_dict[key] = tile_info

	# ✅ Update the in-memory chunk
	local_map.current_tile_chunk = tile_chunk

	# 💾 Save updated tile chunk to disk
	LoadHandlerSingleton.save_chunked_tile_chunk(local_map.get_current_chunk_id(), tile_chunk)

	local_map.rebuild_walkability()
	local_map.update_tile_at(pos)

	print("🚪 Door opened at:", pos)

func close_door_at(pos: Vector2i):
	var local_map = get_tree().root.get_node("LocalMap")
	if local_map == null:
		print("❌ Cannot find LocalMap!")
		return

	var tile_chunk = local_map.get_tile_chunk()
	var tile_dict = tile_chunk.get("tile_grid", {})
	var key = "%d_%d" % [pos.x, pos.y]

	if not tile_dict.has(key):
		print("❌ No tile found at", key)
		return

	var tile_info = tile_dict[key]
	if typeof(tile_info.get("state", null)) != TYPE_DICTIONARY:
		tile_info["state"] = {}

	var current_tile = tile_info.get("tile", "")
	if Constants.DOOR_PAIRS.has(current_tile):
		tile_info["tile"] = Constants.DOOR_PAIRS[current_tile]

	tile_info["state"]["is_open"] = false
	tile_dict[key] = tile_info

	# ✅ Update the in-memory chunk
	local_map.current_tile_chunk = tile_chunk

	# 💾 Save updated tile chunk to disk
	LoadHandlerSingleton.save_chunked_tile_chunk(local_map.get_current_chunk_id(), tile_chunk)

	local_map.rebuild_walkability()
	local_map.update_tile_at(pos)

	print("🚪 Door closed at:", pos)

func handle_interact():
	var player_tile = Vector2i(position.x / TILE_SIZE, position.y / TILE_SIZE)
	var directions = [
		Vector2i(0, -1), Vector2i(0, 1),
		Vector2i(-1, 0), Vector2i(1, 0)
	]

	var local_map = get_tree().root.get_node("LocalMap")
	if local_map == null:
		print("❌ Cannot find LocalMap!")
		return

	var tile_dict = local_map.get_tile_chunk().get("tile_grid", {})
	var object_dict = local_map.get_object_chunk()
	if object_dict.has("objects"):
		object_dict = object_dict["objects"]
	var found_interaction = false

	# 🚪 Priority 1: Doors
	for dir in directions:
		var check_pos = player_tile + dir
		var key = "%d_%d" % [check_pos.x, check_pos.y]
		if tile_dict.has(key):
			var tile_data = tile_dict[key]
			var tile_type = tile_data.get("tile", "")
			var tile_state = tile_data.get("state", {})

			if Constants.is_door(tile_type):
				if tile_state.get("is_open", false):
					close_door_at(check_pos)
				else:
					open_door_at(check_pos)
				found_interaction = true
				break

	# 🕯️ Priority 2: Candelabra toggle
	if not found_interaction:
		for dir in directions:
			var check_pos = player_tile + dir
			var result = Constants.find_object_at(object_dict, check_pos.x, check_pos.y, true)

			if not result.is_empty() and result["data"].get("type", "") == "candelabra":
				var obj = result["data"]
				var state = obj.get("state", {})
				state["is_lit"] = not state.get("is_lit", false)
				obj["state"] = state

				var obj_id = result["id"]
				object_dict[obj_id] = obj
				LoadHandlerSingleton.save_chunked_object_chunk(local_map.get_current_chunk_id(), object_dict)
				local_map.update_object_at(check_pos)

				print("🕯️ Toggled candelabra at", check_pos, "→", state["is_lit"])
				found_interaction = true
				break
				
func change_z_level(new_z: int, new_pos: Vector2i):
	# Load and prepare temp placement
	var placement_data = LoadHandlerSingleton.load_temp_placement()

	if not placement_data.has("local_map"):
		placement_data["local_map"] = {}

	placement_data["local_map"]["z_level"] = new_z
	placement_data["local_map"]["spawn_pos"] = { "x": new_pos.x, "y": new_pos.y }
	placement_data["local_map"]["grid_position_local"] = { "x": new_pos.x, "y": new_pos.y }  # ✅ Sync actual position

	LoadHandlerSingleton.save_temp_placement(placement_data)

	# Debug confirmation
	var confirm_data = LoadHandlerSingleton.load_temp_placement()
	print("💾 Z-level set to:", confirm_data.get("local_map", {}).get("z_level", "missing"))
	print("📍 Intended spawn point:", confirm_data.get("local_map", {}).get("spawn_pos", "missing"))
	print("📍 Grid position set to:", confirm_data.get("local_map", {}).get("grid_position_local", "missing"))

	# Trigger smooth transition
	var SceneManager = get_node("/root/SceneManager")
	SceneManager.current_play_scene_path = "res://scenes/play/LocalMap.tscn"
	SceneManager.change_scene_to_file("res://scenes/play/ChunkToChunkRefresh.tscn")

func handle_egress_check():
	var local_map = get_tree().root.get_node("LocalMap")
	if local_map == null:
		print("❌ Cannot find LocalMap!")
		return

	var egress_data = local_map.get_egress_for_current_position(last_grid_position)
	if egress_data.is_empty():
		print("🚫 No egress point found at current tile.")
		return

	var new_z = egress_data.get("target_z", null)
	var pos = egress_data.get("position", null)

	if new_z == null or pos == null:
		print("⚠️ Egress data incomplete. target_z or position missing.")
		return

	var new_pos = Vector2i(pos["x"], pos["y"])
	change_z_level(new_z, new_pos)
