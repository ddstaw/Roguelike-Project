extends CharacterBody2D

# 🕒 Held movement timing
var is_moving := false
var held_direction := Vector2i.ZERO
var move_repeat_delay := 0.25  # Delay before repeat starts
var move_repeat_rate := 0.1    # Time between repeated steps
var move_timer := 0.0
var last_grid_position := Vector2i(-1, -1)
var travel_log_control: Node = null
var interaction_mode := false
var interaction_origin: Vector2i = Vector2i(-1, -1)  # where the player stood when entering mode


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
			
func set_travel_log(log_node: Node):
	travel_log_control = log_node

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
	# 🔒 Interception while in interaction targeting mode
	if interaction_mode and event.is_pressed():
		var dir := _dir_from_event(event)
		if dir != Vector2i.ZERO:
			get_viewport().set_input_as_handled()
			_try_interact_in_direction(dir)
			return

		# Cancel interaction mode with another "interact" (E) or Esc
		if event.is_action("interact") or event.is_action("ui_cancel"):
			get_viewport().set_input_as_handled()
			_exit_interaction_mode(true)
			return

	# Normal controls when NOT in interaction mode
	if event.is_pressed():
		if event.is_action("interact"):
			get_viewport().set_input_as_handled()
			_enter_interaction_mode()
			return

		elif event.is_action("interact_egress"):
			handle_egress_check()

		elif event.is_action("toggle_inventory"):
			#print("fishbowl: Opening Inventory_LocalPlay.tscn")
			handle_inventory_toggle()

		# Movement & rest
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

func _dir_from_event(event) -> Vector2i:
	# Map the same actions you use for movement
	if event.is_action("up_move"): return Vector2i(0, -1)
	if event.is_action("down_move"): return Vector2i(0, 1)
	if event.is_action("left_move"): return Vector2i(-1, 0)
	if event.is_action("right_move"): return Vector2i(1, 0)
	if event.is_action("upleft_move"): return Vector2i(-1, -1)
	if event.is_action("upright_move"): return Vector2i(1, -1)
	if event.is_action("downleft_move"): return Vector2i(-1, 1)
	if event.is_action("downright_move"): return Vector2i(1, 1)
	return Vector2i.ZERO

func _enter_interaction_mode():
	interaction_mode = true
	interaction_origin = Vector2i(round(position.x / TILE_SIZE), round(position.y / TILE_SIZE))
	if travel_log_control:
		travel_log_control.add_message_to_log("You wish to interact with something? — press a direction to target, or press E again to cancel.")

func _exit_interaction_mode(cancelled: bool = false) -> void:
	interaction_mode = false
	interaction_origin = Vector2i(-1, -1)
	if cancelled and travel_log_control:
		travel_log_control.add_message_to_log("You decide not to interact with anything.")

func _try_interact_in_direction(dir: Vector2i):
	var origin := Vector2i(round(position.x / TILE_SIZE), round(position.y / TILE_SIZE))
	var target := origin + dir

	# Priority 1: doors
	if toggle_door_at(target):
		_exit_interaction_mode()
		return

	# Priority 2: candelabra (or other lightables)
	if toggle_candelabra_at(target):
		_exit_interaction_mode()
		return
	
	# Priority 3: object-based interactions (beds, chests, mounts, etc.)
	var object_data := _get_object_data_at(target)
	if not object_data.is_empty():
		NodeInteractionHandler.travel_log_control = travel_log_control
		NodeInteractionHandler.handle_object_interaction(target, object_data)
		_exit_interaction_mode()
		return
	
	# Priority 4: NPC-based interactions
	var npc_data = _get_npc_data_at(target)
	if npc_data.size() > 0:
		NodeInteractionHandler.travel_log_control = travel_log_control
		NodeInteractionHandler.handle_npc_interaction(target, npc_data)
		_exit_interaction_mode()
		return
	
	var tile_type := _get_tile_type_at(target)
	#print("Detected tile_type:", tile_type, "at", target)
	var tile_data := NodeInteractionHandler.get_tile_interaction_data(tile_type)
	var category: String = tile_data.get("category", "none") as String

	if category != "none":
		NodeInteractionHandler.travel_log_control = travel_log_control
		NodeInteractionHandler.handle_interaction(target, tile_data)
		_exit_interaction_mode()
		return

	travel_log_control.add_message_to_log("… There’s nothing you can interact with there.")
	_exit_interaction_mode()

func _get_object_data_at(pos: Vector2i) -> Dictionary:
	var local_map = get_tree().root.get_node_or_null("LocalMap")
	if not local_map:
		return {}

	var object_chunk = local_map.get_object_chunk() as Dictionary
	if object_chunk.has("objects"):
		var objects = object_chunk["objects"] as Dictionary
		var result = Constants.find_object_at(objects, pos.x, pos.y, true)
		if typeof(result) == TYPE_DICTIONARY and not result.is_empty():
			return result.get("data", {})
	return {}

func _get_npc_data_at(pos: Vector2i) -> Dictionary:
	# 🔑 Get the current chunk
	var chunk_id := LoadHandlerSingleton.get_current_chunk_id()
	var npc_chunk: Dictionary = LoadHandlerSingleton.get_npcs_in_chunk(chunk_id)

	if npc_chunk.is_empty():
		return {}

	# 🔎 Look through NPCs in this chunk
	for npc_id in npc_chunk.keys():
		var npc: Dictionary = npc_chunk[npc_id]  # ✅ Force type as Dictionary
		if not npc.has("position"):
			continue

		var npc_pos := Vector2i(
			int(npc["position"].get("x", -1)),
			int(npc["position"].get("y", -1))
		)

		if npc_pos == pos:
			return npc  # ✅ Return this specific NPC entry

	return {}



func is_interactable_object_at(pos: Vector2i, type_name: String) -> bool:
	var local_map := get_tree().root.get_node("LocalMap")
	if local_map == null:
		return false

	var object_chunk := local_map.get_object_chunk() as Dictionary
	if not object_chunk.has("objects"):
		return false

	var objects := object_chunk["objects"] as Dictionary
	var result := Constants.find_object_at(objects, pos.x, pos.y, true)

	if result.is_empty():
		return false

	var obj := result["data"] as Dictionary
	return obj.get("type", "") == type_name

func _get_tile_type_at(pos: Vector2i) -> String:
	var local_map := get_tree().root.get_node("LocalMap")
	if local_map == null:
		return ""

	var tile_chunk: Dictionary = local_map.get_tile_chunk()
	var tile_dict: Dictionary = tile_chunk.get("tile_grid", {}) as Dictionary
	var key := "%d_%d" % [pos.x, pos.y]
	if not tile_dict.has(key):
		return ""

	var tile_data: Dictionary = tile_dict.get(key, {}) as Dictionary
	return tile_data.get("tile", "") as String


func handle_inventory_toggle():
	var placement_data = LoadHandlerSingleton.load_temp_placement()

	if not placement_data.has("local_map"):
		placement_data["local_map"] = {}

	var grid_pos = Vector2i(position.x / TILE_SIZE, position.y / TILE_SIZE)
	placement_data["local_map"]["grid_position_local"] = {
		"x": grid_pos.x,
		"y": grid_pos.y
	}

	LoadHandlerSingleton.save_temp_placement(placement_data)

	#print("💾 [Inventory Toggle] Saved grid_position_local:", grid_pos)
	get_tree().change_scene_to_file("res://scenes/play/Inventory_LocalPlay.tscn")


func move_player(dir: Vector2i):
	var target_pos = position + Vector2(dir * TILE_SIZE)
	var target_tile = Vector2i(round(target_pos.x / TILE_SIZE), round(target_pos.y / TILE_SIZE))

	var local_map = get_tree().root.get_node("LocalMap")
	if local_map == null:
		#print("❌ Cannot find LocalMap!")
		return

	# 1) 🧭 Chunk transition BEFORE anything else
	if local_map.check_for_chunk_transition(target_tile):
		#print("📦 Chunk transition triggered — skipping local movement.")
		return  # ⛔ Skip movement if chunk transition occurs (blocked or successful)

	# 2) 🚪 Door bump: only open if it's a CLOSED door, then consume the turn
	var tile_dict = local_map.get_tile_chunk().get("tile_grid", {})
	var target_key = "%d_%d" % [target_tile.x, target_tile.y]
	if tile_dict.has(target_key):
		var tile_data = tile_dict[target_key]
		var tile_type = tile_data.get("tile", "")
		if Constants.is_door(tile_type):
			var state = tile_data.get("state", {})
			if not state.get("is_open", false):
				# Use unified helper; it logs + updates + rebuilds
				if toggle_door_at(target_tile):
					return  # consume the turn on door open

	# 3) 🔍 Walkability after any door changes
	var walkability_grid = local_map.walkability_grid

	# 4) 🛑 Bounds + walkability check
	if target_tile.y >= 0 and target_tile.y < walkability_grid.size():
		if target_tile.x >= 0 and target_tile.x < walkability_grid[0].size():
			var cell_data = walkability_grid[target_tile.y][target_tile.x]
			if not cell_data["walkable"]:
				#print("🚫 Movement blocked at:", target_tile, "| Terrain or object is not walkable!")
				if travel_log_control:
					travel_log_control.add_message_to_log("Something is blocking your movement.")
				return

	# 5) ✅ Actually move the player
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
	TurnManager.end_player_turn(1)


	# 📊 Refresh HUD and stats
	local_map.update_time_label()
	local_map.update_local_flavor_image()
	local_map.update_date_label()
	local_map.update_local_progress_bars()
	apply_movement_stat_effects()
	local_map.update_object_visibility(current_grid_pos)
	#print("📍 Player moved to local tile:", current_grid_pos)


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
	TurnManager.end_player_turn(30)
	#WeatherManager.process_weather_cycle()
	#EventEngine.trigger_random_events()
	#BuffSystem.process_player_buffs()

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

	#print("🛌 Player rested. Stats restored. Time advanced.")

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
		#print("❌ Cannot find LocalMap!")
		return

	var tile_chunk = local_map.get_tile_chunk()
	var tile_dict = tile_chunk.get("tile_grid", {})
	var key = "%d_%d" % [pos.x, pos.y]

	if not tile_dict.has(key):
		#print("❌ No tile found at", key)
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

	#print("🚪 Door opened at:", pos)

func close_door_at(pos: Vector2i):
	var local_map = get_tree().root.get_node("LocalMap")
	if local_map == null:
		#print("❌ Cannot find LocalMap!")
		return

	var tile_chunk = local_map.get_tile_chunk()
	var tile_dict = tile_chunk.get("tile_grid", {})
	var key = "%d_%d" % [pos.x, pos.y]

	if not tile_dict.has(key):
		#print("❌ No tile found at", key)
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

	#print("🚪 Door closed at:", pos)

func toggle_door_at(pos: Vector2i) -> bool:
	var local_map = get_tree().root.get_node("LocalMap")
	if local_map == null:
		return false

	var tile_chunk = local_map.get_tile_chunk()
	var tile_dict = tile_chunk.get("tile_grid", {})
	var key = "%d_%d" % [pos.x, pos.y]
	if not tile_dict.has(key):
		return false

	var tile_data = tile_dict[key]
	var tile_type = tile_data.get("tile", "")
	var tile_state = tile_data.get("state", {})

	if not Constants.is_door(tile_type):
		return false

	if tile_state.get("is_open", false):
		close_door_at(pos)
		if travel_log_control:
			travel_log_control.add_message_to_log("You close the door.")
	else:
		open_door_at(pos)
		if travel_log_control:
			travel_log_control.add_message_to_log("You open the door.")
	return true


func toggle_candelabra_at(pos: Vector2i) -> bool:
	var local_map = get_tree().root.get_node("LocalMap")
	if local_map == null:
		return false

	var object_dict = local_map.get_object_chunk()
	if object_dict.has("objects"):
		object_dict = object_dict["objects"]

	var result = Constants.find_object_at(object_dict, pos.x, pos.y, true)
	if result.is_empty():
		return false

	var obj = result["data"]
	if obj.get("type", "") != "candelabra":
		return false

	var state = obj.get("state", {})
	state["is_lit"] = not state.get("is_lit", false)
	obj["state"] = state

	object_dict[result["id"]] = obj
	LoadHandlerSingleton.save_chunked_object_chunk(local_map.get_current_chunk_id(), object_dict)
	local_map.update_object_at(pos)

	if travel_log_control:
		travel_log_control.add_message_to_log("You " + ("light" if state["is_lit"] else "extinguish") + " the candelabra.")
	return true


				
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
