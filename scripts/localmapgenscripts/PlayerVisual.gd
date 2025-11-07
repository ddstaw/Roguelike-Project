##res://scripts/localmapgenscripts/PlayerVisual.gd
extends CharacterBody2D

# 🕒 Held movement timing
var last_grid_position := Vector2i(-1, -1)
var travel_log_control: Node = null
var interaction_mode := false
var interaction_origin: Vector2i = Vector2i(-1, -1)  # where the player stood when entering mode

var _is_auto_stepping := false
var _auto_step_dir: Vector2i = Vector2i.ZERO
var _turn_in_progress := false

const HOLD_DELAY := 0.25  # seconds before auto-repeat begins
const AUTO_STEP_INTERVAL := 0.15  # seconds between steps
const BuildData = preload("res://constants/build_data.gd")

var _last_camera_center_time: float = 0.0
var _camera_step_counter: int = 0
var _camera_recenter_threshold: float = 32.0  # distance in px before re-centering
var _last_camera_anchor: Vector2 = Vector2.ZERO

const CAMERA_CENTER_STEP_INTERVAL := 10  # ✅ change this number to test frequency
const CAMERA_CENTER_INTERVAL := 0.3  # seconds between auto-centers (tweakable)

signal fov_updated(tiles)


func _ready():
	var looks = LoadHandlerSingleton.load_player_looks()
	if looks != null:
		apply_appearance(looks)

	# 🧭 Force initial grid position tracking
	var current_grid_pos = Vector2i(round(position.x / TILE_SIZE), round(position.y / TILE_SIZE))
	last_grid_position = current_grid_pos

	var local_map = get_tree().root.get_node_or_null("LocalMap")
	if local_map != null:
		local_map.update_fov_from_player(current_grid_pos)
		local_map.update_object_visibility(current_grid_pos)
		call_deferred("_refresh_npc_visibility")
		
	# 🧪 Optional: auto-start build mode for debug purposes (remove or comment for prod)
	# if local_map != null and local_map.has_method("enter_targeting"):
	#     local_map.enter_targeting(local_map.TargetingMode.BUILD)


func _process(_delta: float) -> void:

	if not _is_auto_stepping and not _turn_in_progress:
		var dir := _get_input_direction()
		if dir != Vector2i.ZERO:
			_auto_step_dir = dir
			_start_auto_step()

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
	# 🧭 Generic Targeting Movement Hijack
	var local_map = get_tree().root.get_node_or_null("LocalMap")
	if local_map != null and local_map.has_method("is_in_targeting_mode") and local_map.is_in_targeting_mode():
		if event.is_pressed():
			var move_dir := Vector2i.ZERO

			if event.is_action("up_move"):
				move_dir = Vector2i(0, -1)
			elif event.is_action("down_move"):
				move_dir = Vector2i(0, 1)
			elif event.is_action("left_move"):
				move_dir = Vector2i(-1, 0)
			elif event.is_action("right_move"):
				move_dir = Vector2i(1, 0)
			elif event.is_action("upleft_move"):
				move_dir = Vector2i(-1, -1)
			elif event.is_action("upright_move"):
				move_dir = Vector2i(1, -1)
			elif event.is_action("downleft_move"):
				move_dir = Vector2i(-1, 1)
			elif event.is_action("downright_move"):
				move_dir = Vector2i(1, 1)

			if move_dir != Vector2i.ZERO:
				local_map.move_target_cursor(move_dir)
				get_viewport().set_input_as_handled()
				return
				
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
		# 🧱 BUILD MODE: Freeze other inputs and hijack E key for placement
		if local_map != null and local_map.get_current_targeting_mode() == local_map.TargetingMode.BUILD:
			# 🔨 Place buildable with E
			if event.is_action("interact"):
				get_viewport().set_input_as_handled()
				travel_log_control.add_message_to_log("🚧 Attempting to build at: " + str(local_map.target_cursor_grid_pos))
				attempt_build_placement()
				return

			# ❄️ Block aim and inspect during build mode
			if event.is_action("toggle_aim_mode") or event.is_action("toggle_inspect_mode"):
				get_viewport().set_input_as_handled()
				travel_log_control.add_message_to_log("❌ Can't aim or inspect during building.")
				return

		# 🧩 Normal non-build controls
		if event.is_action("interact"):
			get_viewport().set_input_as_handled()
			_enter_interaction_mode()
			return

		elif event.is_action("interact_egress"):
			handle_egress_check()

		elif event.is_action("toggle_inventory"):
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

		# 🧱 Enter build mode
		elif event.is_action("toggle_build_mode"):
			get_viewport().set_input_as_handled()
			if LoadHandlerSingleton.is_holding_hammer_tool():
				travel_log_control.add_message_to_log("You are ready to build.")
				if local_map != null:
					local_map.enter_targeting(local_map.TargetingMode.BUILD)
			else:
				travel_log_control.add_message_to_log("You need a hammer to build.")
			return

		# 🎯 Enter aim mode
		elif event.is_action("toggle_aim_mode"):
			travel_log_control.add_message_to_log("You size up a shot.")
			get_viewport().set_input_as_handled()
			if local_map != null:
				local_map.enter_targeting(local_map.TargetingMode.AIM)
			return

		# 👁 Enter inspect mode
		elif event.is_action("toggle_inspect_mode"):
			travel_log_control.add_message_to_log("You strain your eyes to review what's around.")
			get_viewport().set_input_as_handled()
			if local_map != null:
				local_map.enter_targeting(local_map.TargetingMode.INSPECT)
			return

		# ✅ Confirm action
		elif InputMap.has_action("confirm_action") and event.is_action("confirm_action"):
			if local_map != null and local_map.is_in_targeting_mode():
				travel_log_control.add_message_to_log("🎯 Confirmed target at: " + str(local_map.target_cursor_grid_pos))
				local_map.exit_targeting()
				get_viewport().set_input_as_handled()
				return


func _get_input_direction() -> Vector2i:
	var dir := Vector2i.ZERO
	if Input.is_action_pressed("up_move"):
		dir.y -= 1
	elif Input.is_action_pressed("down_move"):
		dir.y += 1
	elif Input.is_action_pressed("left_move"):
		dir.x -= 1
	elif Input.is_action_pressed("right_move"):
		dir.x += 1
	elif Input.is_action_pressed("upleft_move"):
		dir = Vector2i(-1, -1)
	elif Input.is_action_pressed("upright_move"):
		dir = Vector2i(1, -1)
	elif Input.is_action_pressed("downleft_move"):
		dir = Vector2i(-1, 1)
	elif Input.is_action_pressed("downright_move"):
		dir = Vector2i(1, 1)
	return dir


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
	# ✅ Step 1: get current true grid & z level
	var current_grid_pos := Vector2i(round(position.x / TILE_SIZE), round(position.y / TILE_SIZE))
	var current_z := int(LoadHandlerSingleton.get_current_z_level_mem())

	# ✅ Step 2: write to in-memory cache (no file I/O needed for loop transitions)
	LoadHandlerSingleton.set_current_local_grid_pos(current_grid_pos)
	LoadHandlerSingleton.set_current_z_level(current_z)

	# ✅ Step 3: sync to temp placement only if you want to preserve crash recovery
	var placement_data := LoadHandlerSingleton.load_temp_placement()
	if not placement_data.has("local_map"):
		placement_data["local_map"] = {}

	placement_data["local_map"]["grid_position_local"] = {
		"x": current_grid_pos.x,
		"y": current_grid_pos.y
	}
	placement_data["local_map"]["z_level"] = str(current_z)

	LoadHandlerSingleton.save_temp_placement(placement_data)

	print("💾 [Inventory Toggle] Cached grid:", current_grid_pos, "| z:", current_z)

	# ✅ Step 4: jump to inventory scene
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

	# 🧭 SMART CAMERA — recenter only if player leaves visible viewport
	if get_tree().root.has_node("LocalMap"):
		var world_view: Node2D = local_map.get_node_or_null("WorldView")
		if world_view:
			var player_pos: Vector2 = position
			var zoom_factor: float = float(local_map.zoom_factor)
			var vp_size: Vector2 = get_viewport_rect().size

			# Camera center in *world* coords
			var camera_center: Vector2 = (-world_view.position / zoom_factor) + ((vp_size * 0.5) / zoom_factor)

			# Visible rect in world units
			var half_vp: Vector2 = (vp_size * 0.5) / zoom_factor
			var visible_left: float = camera_center.x - half_vp.x
			var visible_right: float = camera_center.x + half_vp.x
			var visible_top: float = camera_center.y - half_vp.y
			var visible_bottom: float = camera_center.y + half_vp.y

			var tile_px: float = float(local_map.TILE_SIZE)
			var margin: float = tile_px * 2.0  # safe zone buffer

			var out_of_bounds: bool = (
				player_pos.x < visible_left + margin or
				player_pos.x > visible_right - margin or
				player_pos.y < visible_top + margin or
				player_pos.y > visible_bottom - margin
			)

			if out_of_bounds:
				# Use your tweened center helper if you have one; otherwise anchor directly.
				if local_map.has_method("center_on_player_after_load"):
					local_map.center_on_player_after_load(0.0) # duration 0 = snap
				elif local_map.has_method("_center_on_anchor"):
					local_map._center_on_anchor(player_pos)



	# 🔎 POST-MOVE PROBES (new)
	var current_grid_pos = Vector2i(round(position.x / TILE_SIZE), round(position.y / TILE_SIZE))

	# Re-check chunk edge so exit popup shows when you step ON the edge
	if local_map.has_method("check_for_chunk_transition"):
		local_map.check_for_chunk_transition(current_grid_pos)

	# Probe z-egress (stairs, ladders) on the tile you are standing on
	if local_map.has_method("probe_egress_here"):
		local_map.probe_egress_here(current_grid_pos)

	
	# 🔁 Update FOV if needed
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
	
	# 💾 Update grid_position_local on actual movement
	var placement_data := LoadHandlerSingleton.load_temp_placement()
	if not placement_data.has("local_map"):
		placement_data["local_map"] = {}

	placement_data["local_map"]["grid_position_local"] = {
		"x": current_grid_pos.x,
		"y": current_grid_pos.y
	}
	LoadHandlerSingleton.save_temp_placement(placement_data)

func start_held_move(dir: Vector2i) -> void:
	if _turn_in_progress:
		return

	_auto_step_dir = dir
	_is_auto_stepping = true

	# Immediate first step (for tap movement)
	_perform_single_step(dir)

	# Start checking for hold after a short delay
	await get_tree().create_timer(HOLD_DELAY).timeout
	if Input.is_action_pressed("move_any"):
		_start_auto_step()  # begin repeat if still held

func _start_auto_step() -> void:
	while _auto_step_dir != Vector2i.ZERO and Input.is_action_pressed("move_any"):
		if _turn_in_progress:
			await get_tree().process_frame
			continue

		await get_tree().create_timer(AUTO_STEP_INTERVAL).timeout
		if not Input.is_action_pressed("move_any"):
			break

		_perform_single_step(_auto_step_dir)

	_is_auto_stepping = false

func _smooth_move_to(target: Vector2) -> void:
	if not is_inside_tree():
		return
	var tween := create_tween()
	tween.tween_property(self, "position", target, 0.08) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)


func _perform_single_step(dir: Vector2i) -> void:
	if _turn_in_progress:
		return

	_turn_in_progress = true

	var old_pos := position

	# 🧭 Perform the move (handles collisions, doors, etc.)
	move_player(dir)

	# ✅ Check if move_player actually changed our position
	if position != old_pos:
		_smooth_move_to(position)  # smooth between the two valid tiles

	await get_tree().process_frame
	_turn_in_progress = false

	
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
	if local_map.has_method("update_tile_visual_at"):
		local_map.update_tile_visual_at(pos)
	elif local_map.has_method("update_tile_at"):
		local_map.update_tile_at(pos)
		
	var grid_pos := Vector2i(round(position.x / TILE_SIZE), round(position.y / TILE_SIZE))
	if local_map.has_method("force_update_fov_at"):
		local_map.force_update_fov_at(grid_pos)
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
	
	var grid_pos := Vector2i(round(position.x / TILE_SIZE), round(position.y / TILE_SIZE))
	if local_map.has_method("force_update_fov_at"):
		local_map.force_update_fov_at(grid_pos)

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
	var placement_data: Dictionary = LoadHandlerSingleton.load_temp_placement()
	if not placement_data.has("local_map"):
		placement_data["local_map"] = {}

	var z_int: int = LoadHandlerSingleton.z_to_int(new_z)
	placement_data["local_map"]["z_level"] = z_int
	placement_data["local_map"]["spawn_pos"] = {"x": new_pos.x, "y": new_pos.y}
	placement_data["local_map"]["grid_position_local"] = {"x": new_pos.x, "y": new_pos.y}

	LoadHandlerSingleton.save_temp_placement(placement_data)

	# ✅ Update in-memory cache for instant sync
	LoadHandlerSingleton.set_current_z_level(z_int)
	LoadHandlerSingleton.set_current_local_grid_pos(new_pos)

	print("💾 [Egress] Z-level set to:", z_int, "Spawn:", new_pos)

	
	var scene_manager: Node = get_node("/root/SceneManager")
	scene_manager.current_play_scene_path = "res://scenes/play/LocalMap.tscn"
	scene_manager.change_scene_to_file("res://scenes/play/ChunkToChunkRefresh.tscn")


func handle_egress_check():
	var local_map: Node = get_tree().root.get_node_or_null("LocalMap")
	if local_map == null:
		print("❌ Cannot find LocalMap!")
		return

	var egress_data: Dictionary = local_map.get_egress_for_current_position(last_grid_position)
	if egress_data.is_empty():
		print("🚫 No egress point found at current tile.")
		return

	var new_z_variant: Variant = egress_data.get("target_z", null)
	var pos: Variant = egress_data.get("position", null)
	if new_z_variant == null or pos == null:
		print("⚠️ Egress data incomplete.")
		return

	var new_z: int = LoadHandlerSingleton.z_to_int(new_z_variant)
	var new_pos := Vector2i(int(pos["x"]), int(pos["y"]))

	change_z_level(new_z, new_pos)



func attempt_build_placement():
	var local_map = get_tree().root.get_node_or_null("LocalMap")
	if local_map == null:
		travel_log_control.add_message_to_log("This won't do.")
		return

	var grid_pos: Vector2i = local_map.target_cursor_grid_pos

	# Validate
	if not local_map.is_valid_build_position(grid_pos):
		travel_log_control.add_message_to_log("I can’t build that here.")
		return

	if not LoadHandlerSingleton.has_required_materials_for_current_build():
		travel_log_control.add_message_to_log("I don't have the required materials.")
		return

	# Delegate the actual placement to LocalMap
	local_map.place_current_buildable_at(grid_pos)
	
	var used_materials: Dictionary = local_map.consume_materials_for_current_build()
	if used_materials.size() > 0:
		var msg: String = "Used materials:\n"
		for id: String in used_materials.keys():
			var entry = used_materials[id]
			var name: String = entry.get("display_name", id)
			var qty: int = entry.get("used_qty", 0)
			msg += "- %s x%d\n" % [name, qty]
		travel_log_control.add_message_to_log(msg.strip_edges())
	else:
		travel_log_control.add_message_to_log("⚠️ No materials consumed — possible logic issue.")
	
			# ✅ Emit global inventory change signal
	if LoadHandlerSingleton.has_signal("inventory_changed"):
		LoadHandlerSingleton.emit_signal("inventory_changed")


func _refresh_npc_visibility() -> void:
	var local_map = get_tree().root.get_node_or_null("LocalMap")
	if local_map == null:
		return
	if local_map.has_method("_apply_fov_to_npc_layer"):
		var npc_layer = local_map.get_node_or_null("NPCLayer")
		var npc_under = local_map.get_node_or_null("NPCUnderlayLayer")
		if npc_layer:
			local_map._apply_fov_to_npc_layer(npc_layer, false)
		if npc_under:
			local_map._apply_fov_to_npc_layer(npc_under, true)
			
func _refresh_npc_visibility_safe() -> void:
	var local_map := get_tree().root.get_node_or_null("LocalMap")
	if not local_map:
		return
	if local_map.has_method("refresh_npc_visibility"):
		local_map.refresh_npc_visibility()
	elif local_map.has_method("redraw_npcs"):
		local_map.redraw_npcs()
