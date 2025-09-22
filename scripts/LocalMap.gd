extends Control

@onready var tile_container = $TileContainer  # A Node2D that holds all tile sprites
@onready var world_map_button = $UILayer/DebugUI/WorldMap  # Adjust if needed
@onready var generate_button = $UILayer/DebugUI/GenNewMapDebugButton
@onready var toggle_free_pan_button = $UILayer/DebugUI/ToggleFreePan  # Free pan toggle button
@onready var bottom_ui = $UIlayer/LocalPlayUI/BottomUI  # ✅ Reference the BottomUI node
@onready var dark_overlay = $UILayer/DarkOverlay
@onready var light_overlay := $LightOverlay
@onready var travel_log = $UILayer/LocalPlayUI/TravelLogControl


var light_map: Array = []  # 🌕 Stores per-tile light levels
var tile_light_levels: Dictionary = {}
var sunlight_level: float = 1.0
var is_full_daylight := sunlight_level >= 0.95  # max sunlight
var last_minute_seen: int = -1  # Add this at the top of localmap.gd
var player: Node = null  # 👤 Store player instance globally in this script
var visible_tiles := {}  # Stores tiles currently in vision
var current_visible_tiles: Dictionary = {}
var free_pan_enabled = false  # Default: OFF
var pan_speed = 500  # Adjust as needed
var zoom_factor = 1.0  # Keep track of current zoom level
var zoom_levels =  [1.0, 0.75, 0.5, 0.35, 0.2]  # Zoom factors
var current_zoom_index = 0  # Default zoom
var walkability_grid: Array = []
var _last_visibility_update_time := 0.0
var entry_context: Dictionary = {}
var entry_type: String = "explore"  # Fallback
var current_tile_chunk: Dictionary = {}
var current_object_chunk: Dictionary = {}
var current_npc_chunk: Dictionary = {}
var current_chunk_id: String = ""
var active_area_exit_popup: Node = null
var current_z_level: int = 0
var last_egress_pos: Vector2i = Vector2i(-999, -999)  # Declare this at the top of your
var visible_chunks: Array = []

const VISIBILITY_UPDATE_INTERVAL := 0.1  # seconds

const TEXTURES = Constants.TILE_TEXTURES

const TILE_SIZE = 88  # Each tile is 88x88 pixels

func _ready():
	#print("🔍 DEBUG: LocalMap.gd _ready() is running!")

	await get_tree().process_frame  # Let scene tree settle

	# 🔄 Load placement data first
	var placement = LoadHandlerSingleton.load_temp_localmap_placement()

	if placement.has("local_map") and placement["local_map"].has("chunk_blueprints"):
		#print("🔧 Populating ChunkTools with blueprint data...")
		ChunkTools.populate_from_loadhandler()
	else:
		print("❌ ERROR: No blueprint data found in placement — chunk transitions may fail!")

	var entry_context = LoadHandlerSingleton.load_entry_context()
	var entry_type = entry_context.get("entry_type", "explore")
	#print("📘 Entry Type Detected:", entry_type)

	# 🎛️ Hook up UI controls
	world_map_button.connect("pressed", Callable(self, "_on_WorldMap_pressed"))

	if tile_container == null:
		#print("❌ ERROR: tile_container is NULL in LocalMap.gd!")
		return

	if not generate_button.pressed.is_connected(_on_GenNewMapDebugButton_pressed):
		generate_button.pressed.connect(_on_GenNewMapDebugButton_pressed)

	if not toggle_free_pan_button.pressed.is_connected(_toggle_free_pan):
		toggle_free_pan_button.pressed.connect(_toggle_free_pan)

	#print("✅ SUCCESS: tile_container found in LocalMap.gd!", tile_container)
	#print("📐 TileContainer Pos:", tile_container.global_position)
	#print("🔍 TileContainer Children:", tile_container.get_child_count())

	# 🗺️ Render map and objects
	load_and_render_local_map()

	# 💡 Manually initialize LightOverlay AFTER map is built
	if light_overlay and light_overlay.has_method("initialize"):
		#print("🔧 Initializing LightOverlay manually...")
		light_overlay.initialize(walkability_grid, TILE_SIZE)
		await light_overlay.ready_signal
		#print("✅ LightOverlay fully ready.")
	else:
		print("❌ ERROR: LightOverlay missing or doesn't implement initialize().")

	# 🧭 Update contextual UI
	update_time_label()
	update_local_flavor_image()
	update_date_label()
	update_realm_label()
	update_play_scene_name()
	update_local_progress_bars()
	update_dark_overlay()

	# 🔦 Kick off FOV + lighting update if player exists
	if player:
		var grid_pos = Vector2i(round(player.position.x / TILE_SIZE), round(player.position.y / TILE_SIZE))
		update_fov_from_player(grid_pos)
	else:
		print("⚠️ Player not ready yet — skipping FOV update (will happen on spawn)")
		


func load_and_render_local_map():
	for child in tile_container.get_children():
		child.queue_free()
	#print("📂 Loading local map data from saved JSONs...")

	# 🔍 Get entry context and chunk info
	var entry_context = LoadHandlerSingleton.load_entry_context()
	var placement = LoadHandlerSingleton.load_temp_localmap_placement()
	var chunk_id = LoadHandlerSingleton.load_temp_localmap_placement().local_map.current_chunk_id
	var biome_folder = placement["local_map"].get("biome_key", "grassland_explore_fields")
	var biome_key = Constants.get_biome_chunk_key(biome_folder)  # 👈 Convert long name to short key
	var z_level = str(placement["local_map"].get("z_level", "0"))
	current_chunk_id = chunk_id

	#print("🧩 Loading chunked local map:", chunk_id, "at Z =", z_level)

	# 🧱 Load tile and object chunks
	var tile_path = LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_id, biome_key, z_level)
	var object_path = LoadHandlerSingleton.get_chunked_object_chunk_path(chunk_id, biome_key, z_level)
	var npc_path = LoadHandlerSingleton.get_chunked_npc_chunk_path(chunk_id, biome_key, z_level)
	
	var tile_chunk = LoadHandlerSingleton.load_json_file(tile_path)
	var object_chunk = LoadHandlerSingleton.load_json_file(object_path)
	var npc_chunk = LoadHandlerSingleton.load_json_file(npc_path)

	
		# Only wrap if tile_chunk is valid
	print("📂 Attempting to load tile chunk from:", tile_path)
	if tile_chunk != null and tile_chunk.has("tile_grid"):
		tile_chunk = { "tile_grid": tile_chunk["tile_grid"] }
		
	if object_chunk != null and object_chunk.has("objects"):
		object_chunk = object_chunk
	elif typeof(object_chunk) == TYPE_DICTIONARY:
		object_chunk = { "objects": object_chunk }
	else:
		object_chunk = { "objects": {} }

	if npc_chunk != null and npc_chunk.has("npcs"):
		npc_chunk = npc_chunk
	elif typeof(npc_chunk) == TYPE_DICTIONARY:
		npc_chunk = { "npcs": npc_chunk }
	else:
		npc_chunk = { "npcs": {} }

	current_tile_chunk = tile_chunk
	current_object_chunk = object_chunk
	current_npc_chunk = npc_chunk

	# ❌ Bail if anything failed
	if tile_chunk == null or object_chunk == null:
		print("❌ ERROR: Failed to load chunk data!")
		return

	# 🎨 Render map using chunks
	MapRenderer.render_map(tile_chunk, object_chunk, npc_chunk, tile_container, chunk_id)
	#print("✅ Chunked local map rendered.")
	var coords = LoadHandlerSingleton.get_current_chunk_coords()
	MapRenderer.render_chunk_transitions(coords, tile_container)
	
	
	# 🧭 Build walkability grid
	var tile_dict = tile_chunk.get("tile_grid", {})
	if object_chunk.has("objects"):
		object_chunk = object_chunk["objects"]
	walkability_grid = LoadHandlerSingleton.build_walkability_grid(tile_dict, object_chunk)

	# 🌑 Init blank light map
	light_map.clear()
	for y in range(walkability_grid.size()):
		var row: Array = []
		for x in range(walkability_grid[y].size()):
			row.append(0.0)
		light_map.append(row)

	# 🧍 Spawn player
	spawn_player_visual()
	#print("✅ Player visual spawned at:", player.position)

	# 👁️ Update FOV after frame delay
	await get_tree().process_frame
	var grid_pos = Vector2i(player.position.x / TILE_SIZE, player.position.y / TILE_SIZE)
	update_fov_from_player(grid_pos)
	visible_chunks = [ current_chunk_id ]

func spawn_player_visual():
	var placement = LoadHandlerSingleton.load_temp_localmap_placement()
	if placement == null:
		#print("❌ No placement data — cannot spawn player.")
		return

	var entry_context = LoadHandlerSingleton.load_entry_context()
	var entry_type = entry_context.get("entry_type", "explore")

	# 🧭 Prefer local position if it exists
	var map_data = placement.get("local_map", {})
	var player_pos = map_data.get("grid_position_local", null)

	if player_pos == null:
		# Fallback to global
		player_pos = map_data.get("grid_position", null)
		if player_pos != null:
			print("⚠️ No local spawn, using global coords for player:", player_pos)
		else:
			print("❌ No player position found in placement data.")
			if entry_type == "explore":
				print("⚠️ Entry is explore, defaulting to center spawn.")
				player_pos = { "x": 25, "y": 25 }
			else:
				print("❌ No fallback defined for entry_type =", entry_type)
				return

	# 🎯 Convert to world position
	var x = int(player_pos["x"]) * TILE_SIZE
	var y = int(player_pos["y"]) * TILE_SIZE

	var player_scene = preload("res://scenes/actors/PlayerVisual.tscn")
	var player_instance = player_scene.instantiate()
	player_instance.position = Vector2(x, y)
	
	# ✅ Set travel log here
	player_instance.set_travel_log($UILayer/LocalPlayUI/TravelLogControl)
	
	self.player = player_instance
	player_instance.connect("fov_updated", Callable(self, "_on_player_fov_updated"))

	# 🎨 Visuals
	var looks = LoadHandlerSingleton.load_player_looks()
	if looks != null:
		player_instance.apply_appearance(looks)
	else:
		print("⚠️ No player looks loaded — using default visuals.")

	tile_container.add_child(player_instance)

	update_fov_from_player(Vector2i(player_pos["x"], player_pos["y"]))
	#call_deferred("center_tile_container")

	#print("✅ Player visual spawned at (local):", player_pos, "→ World Pos:", Vector2(x, y))


func _on_WorldMap_pressed():
	#print("🌍 Returning to World Map...")

	# ✅ Transition to the refresh scene first
	get_tree().change_scene_to_file("res://scenes/play/LocaltoWorldRefresh.tscn")


func _on_GenNewMapDebugButton_pressed():
	#print("🛠 DEBUG: Generate New Map button pressed!")
	generate_local_map()


func center_tile_container():
	if player == null:
		#print("⚠️ Player not ready — can't center tile container yet.")
		return

	var player_pixel_pos: Vector2 = player.position

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var zoom: float = tile_container.scale.x  # Assuming uniform scaling

	var offset: Vector2 = viewport_size / (2.0 * zoom)

	var new_position = -player_pixel_pos + offset
	tile_container.position = new_position

	#print("🎯 Centering on player:")
	#print("   ↪ Grid Pos:", Vector2i(player_pixel_pos / TILE_SIZE))
	#print("   ↪ Pixel Pos:", player_pixel_pos)
	#print("📐 Viewport Size:", viewport_size)
	#print("🔍 Zoom Level:", zoom)
	#print("📍 New TileContainer Pos:", new_position)

func _toggle_free_pan():
	var previous_position = tile_container.position  # ✅ Store current position before toggling
	
	free_pan_enabled = !free_pan_enabled
	update_free_pan_button()

	# ✅ Restore position after toggling
	tile_container.position = previous_position

func update_free_pan_button():
	toggle_free_pan_button.text = "Free Pan: ON" if free_pan_enabled else "Free Pan: OFF"

func _process(delta):
	update_dark_overlay()

	# ✅ Auto-close area exit popup if player moves away from the trigger tile
	if active_area_exit_popup and is_instance_valid(player):
		var player_tile = Vector2i(player.position.x / TILE_SIZE, player.position.y / TILE_SIZE)

		if is_instance_valid(active_area_exit_popup):
			var trigger_tile = active_area_exit_popup.get_meta("trigger_tile")
			if player_tile != trigger_tile:
				#print("❌ Player moved away from edge — closing area exit popup.")
				active_area_exit_popup.queue_free()
				active_area_exit_popup = null
		else:
			# 🔒 Safety reset in case popup was freed by button press
			active_area_exit_popup = null

	# ✅ Free pan movement
	if free_pan_enabled:
		handle_panning(delta)

	# ✅ Only recalculate once per in-game minute
	var time_data = LoadHandlerSingleton.get_time_and_date()
	var minute_str = time_data.get("miltime", "1200").substr(2, 2)
	var current_minute = int(minute_str)

	if current_minute != last_minute_seen:
		last_minute_seen = current_minute
		calculate_sunlight_levels()

func zoom_in():
	if current_zoom_index > 0:
		current_zoom_index -= 1
		update_zoom()

func zoom_out():
	if current_zoom_index < zoom_levels.size() - 1:
		current_zoom_index += 1
		update_zoom()

func update_zoom():
	# ✅ Get the current center BEFORE zooming
	var previous_center = tile_container.position + (get_viewport_rect().size / 2) / tile_container.scale

	# ✅ Apply the zoom factor
	zoom_factor = zoom_levels[current_zoom_index]
	tile_container.scale = Vector2(zoom_factor, zoom_factor)

	# ✅ Recalculate center AFTER zooming
	var new_center = (previous_center * zoom_factor) - (get_viewport_rect().size / 2) / tile_container.scale

	# ✅ Clamp to prevent it from zooming into negative space
	var map_width = 100 * TILE_SIZE * zoom_factor  # Adjust for zoom
	var map_height = 100 * TILE_SIZE * zoom_factor

	tile_container.position = Vector2(
		clamp(new_center.x, -map_width / 2, map_width / 2),
		clamp(new_center.y, -map_height / 2, map_height / 2)
	)

	#print("Zoom Updated. New TileContainer Position:", tile_container.position)



func _unhandled_input(event):
	if event.is_action_pressed("local_zoom_in"):
		zoom_in()
	elif event.is_action_pressed("local_zoom_out"):
		zoom_out()


func _on_generate_pressed():
	generate_local_map()

func generate_local_map():
	# 🚨 Debugging: Ensure `tile_container` exists
	if tile_container == null:
		#print("❌ ERROR: `tile_container` is NULL in LocalMap! Aborting.")
		return

	#print("✅ SUCCESS: `tile_container` found in LocalMap.gd!", tile_container)

	# ✅ Step 1: Clear the old map
	for child in tile_container.get_children():
		child.queue_free()
	#print("🧹 Cleared TileContainer.")

	# ✅ Step 2: Generate map with `tile_container`
	var result = await GeneratorDispatcher.generate_local_map(tile_container)

	# 🚨 Check for NULL result
	if result == null:
		#print("❌ ERROR: GeneratorDispatcher returned NULL! Debug the generator function.")
		return

	# ✅ Ensure both grid and object layers are returned
	if result.size() < 2:
		#print("❌ ERROR: Generator returned an invalid grid and object layer! Got:", result)
		return

	#print("✅ DEBUG: Generator returned valid grid & object layer.")

	var grid = result[0]
	var object_layer = result[1]

	# ✅ Step 3: Check if grid is empty
	if grid == null or grid.size() == 0:
		#print("❌ ERROR: No valid grid was returned from generator.")
		return

	#print("🟢 DEBUG: Grid successfully generated with size:", grid.size())

	# ✅ Step 4: Place objects on the grid
	var placement_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_worldmap_placement_path())

	var biome_name = "unknown"
	if placement_data.has("character_position"):
		var char_pos = placement_data["character_position"]
		var realm = char_pos.get("current_realm", "worldmap")
		biome_name = char_pos.get(realm, {}).get("biome", "unknown")

	#print("🧭 Object placement biome:", biome_name)
	ObjectPlacer.place_objects(grid, object_layer, biome_name)

	# ✅ Step 5: Render the map
	print("🛠 DEBUG: Calling MapRenderer.render_map()...")

	print("✅ Map successfully generated and rendered!")


var last_logged_position = Vector2.ZERO  # Stores the last printed position

func handle_panning(delta):
	if tile_container == null:
		print("❌ ERROR: `tile_container` is NULL in `handle_panning()`! Aborting.")
		return  # 🔥 Prevent crashes

	var move_vector = Vector2.ZERO

	# ✅ Basic movement controls
	if Input.is_action_pressed("up_move"):
		move_vector.y += 1
	if Input.is_action_pressed("down_move"):
		move_vector.y -= 1
	if Input.is_action_pressed("left_move"):
		move_vector.x += 1
	if Input.is_action_pressed("right_move"):
		move_vector.x -= 1

	# ✅ Normalize to prevent diagonal speed increase
	if move_vector.length() > 0:
		move_vector = move_vector.normalized()

	# ✅ Adjust movement speed based on zoom level
	var adjusted_speed = pan_speed / zoom_factor

	# ✅ Apply movement to `tile_container`
	tile_container.position += move_vector * adjusted_speed * delta

func update_time_label():
	var time_label = get_node_or_null("UILayer/LocalPlayUI/Time")
	if time_label:
		var timedate = LoadHandlerSingleton.get_time_and_date()
		if timedate.has("gametime"):
			time_label.text = timedate["gametime"]
	else:
		print("⚠️ TimeLabel node not found at path: UILayer/Time")

func update_dark_overlay():
	var target_alpha := 0.0

	if LoadHandlerSingleton.is_underground():
		target_alpha = 0.0  # 🕳️ Underground = full clarity
	else:
		var time_data = LoadHandlerSingleton.get_time_and_date()
		if time_data == null:
			#print("⚠️ Time data missing — cannot update overlay.")
			return

		var miltime: String = time_data.get("miltime", "1200")
		var hour := int(miltime.substr(0, 2))

		if hour < 5 or hour >= 22:
			target_alpha = 0.45  # Late night
		elif hour < 7 or hour >= 19:
			target_alpha = 0.25  # Dusk/Dawn
		else:
			target_alpha = 0.0  # Daytime

	# ✅ Apply darkening using ColorRect’s actual color property
	dark_overlay.color = Color(0, 0, 0, target_alpha)


func update_local_flavor_image():
	var flavor_image_node = $UILayer/LocalPlayUI/TimeOfDayType # Adjust this path if needed
	if flavor_image_node:
		var flavor_texture = LoadHandlerSingleton.get_gametimeflavorlocal_image()
		if flavor_texture:
			flavor_image_node.texture = flavor_texture
			#print("🕓 Local flavor image updated.")
		else:
			print("⚠️ Could not load local flavor texture.")
	else:
		print("❌ Error: TimeFlavorImage node not found.")

func update_date_label():
	var date_label = get_node("UILayer/LocalPlayUI/Date")  # Update with correct path
	if date_label:
		var date_value = LoadHandlerSingleton.get_date_name()
		date_label.text = date_value
		#print("📅 Date label updated to:", date_value)
	else:
		print("❌ Error: Date label node not found.")

func update_realm_label():
	var realm_label = get_node("UILayer/LocalPlayUI/Realm")  # 🔁 Replace with your actual node path if different

	if realm_label:
		var current_realm = LoadHandlerSingleton.get_current_realm()

		if current_realm == "worldmap":
			realm_label.text = LoadHandlerSingleton.get_world_name()
		elif current_realm == "citymap":
			realm_label.text = LoadHandlerSingleton.get_current_city()
		elif current_realm == "localmap":
			realm_label.text = "Wilderness"
		else:
			realm_label.text = "Unknown Realm"

		#print("🌍 Updated realm label to:", realm_label.text)
	else:
		print("❌ Error: RealmLabel node not found.")

func update_play_scene_name():
	var label_node = get_node_or_null("UILayer/LocalPlayUI/PlaySceneName")
	if label_node == null:
		#print("❌ Error: PlaySceneName label not found.")
		return

	var entry_context = LoadHandlerSingleton.load_entry_context()
	var entry_type = entry_context.get("entry_type", "explore")  # fallback to explore if missing

	match entry_type:
		"explore":
			var pos = LoadHandlerSingleton.get_player_position()
			var biome = LoadHandlerSingleton.get_biome_name(pos)
			var biome_label = Constants.get_biome_label(biome)

			# ✅ Use current_chunk_id instead of janky explored_chunks
			var placement = LoadHandlerSingleton.load_temp_localmap_placement()
			var chunk_id = placement.get("local_map", {}).get("current_chunk_id", "chunk_1_1")
			chunk_id = chunk_id.replace("chunk_", "")  # Get just the coords part

			var chunk_label = _get_chunk_direction_label(chunk_id)
			label_node.text = "Exploring " + biome_label + chunk_label

		"remembered":
			label_node.text = "Revisiting Familiar Grounds"

		"investigation":
			label_node.text = "Investigating a Lead"

		"encounter":
			label_node.text = "Random Encounter"

		_:
			label_node.text = "Wandering"

	#print("🧭 Play scene name updated to:", label_node.text)


func _get_chunk_direction_label(chunk_id: String) -> String:
	var parts = chunk_id.split("_")
	if parts.size() != 2:
		return ""

	var x = int(parts[0])
	var y = int(parts[1])

	var dir_x = ""
	var dir_y = ""

	match x:
		0: dir_x = "West"
		1: dir_x = ""
		2: dir_x = "East"

	match y:
		0: dir_y = "North"
		1: dir_y = ""
		2: dir_y = "South"

	if dir_x != "" and dir_y != "":
		return " - " + dir_y + dir_x  # e.g. SouthEast
	elif dir_x != "":
		return " - " + dir_x
	elif dir_y != "":
		return " - " + dir_y
	else:
		return " - Center"


func update_local_progress_bars():
	var stats_data = LoadHandlerSingleton.get_combat_stats()
	if not stats_data.has("combat_stats"):
		#print("⚠️ No combat_stats found!")
		return
	
	var stats = stats_data["combat_stats"]

	# Map node paths to their stat keys
	var bar_paths = {
		"health": "UILayer/LocalPlayUI/LocalMetersContainer/HBoxLocalHealth/LocalHealthBar",
		"stamina": "UILayer/LocalPlayUI/LocalMetersContainer/HBoxLocalStamina/LocalStaminaBar",
		"hunger": "UILayer/LocalPlayUI/LocalMetersContainer/HBoxLocalHunger/LocalHungerBar",
		"fatigue": "UILayer/LocalPlayUI/LocalMetersContainer/HBoxLocalFatigue/LocalFatigueBar",
		"sanity": "UILayer/LocalPlayUI/LocalMetersContainer/HBoxLocalSanity/LocalSanityBar"
	}

	for stat in bar_paths.keys():
		var path = bar_paths[stat]
		if has_node(path):
			var bar = get_node(path)
			var stat_info = stats.get(stat, {})
			bar.max_value = stat_info.get("max", 100)
			bar.value = stat_info.get("current", 0)
		else:
			print("⚠️ Missing node for", stat)

func is_tile_walkable(pos: Vector2i) -> bool:
	if not is_in_bounds(pos):
		return false
	var cell = walkability_grid[pos.y][pos.x]
	return cell.get("walkable", true)
	
func update_fov_from_player(grid_pos: Vector2i): 
	#print("🔦 FOV update from:", grid_pos)

	var previous_visible_tiles := current_visible_tiles.keys()
	visible_tiles.clear()

	# 👁️ Player vision range only
	var base_radius: float = LoadHandlerSingleton.get_effective_vision_radius()
	var fov_light_level: float = clamp(sunlight_level, 0.0, 1.0)

	var equipped_light_data = LoadHandlerSingleton.get_best_equipped_light_item_with_id()
	var min_vision_radius: float = equipped_light_data.get("light_radius", 3)
	var max_vision_multiplier: float = 16.0

	var t: float = clamp((fov_light_level - 0.85) / 0.15, 0.0, 1.0)
	var vision_multiplier: float = lerp(1.0, max_vision_multiplier, t)
	var player_radius: int = int(min_vision_radius * vision_multiplier)

	#print("🌞 Sunlight:", sunlight_level, "| Player Radius:", player_radius)

	for y in range(walkability_grid.size()):
		for x in range(walkability_grid[y].size()):
			var pos: Vector2i = Vector2i(x, y)
			var tile_data: Dictionary = walkability_grid[y][x]

			if tile_data.has("indoor") and tile_data["indoor"] == true:
				continue

			var dist_sq: int = (pos - grid_pos).length_squared()
			if dist_sq <= player_radius * player_radius:
				if has_line_of_sight(grid_pos, pos):
					if not visible_tiles.has(pos) or (visible_tiles[pos] > 0 and dist_sq < visible_tiles[pos]):
						visible_tiles[pos] = dist_sq

	# 🔁 Mark dirty tiles for redraw
	for pos in visible_tiles.keys():
		if not previous_visible_tiles.has(pos):
			light_overlay.dirty_tiles[pos] = true
	for pos in previous_visible_tiles:
		if not visible_tiles.has(pos):
			light_overlay.dirty_tiles[pos] = true

	# ✅ Finalize visibility state
	# Apply static lighting to *only* visible tiles
	apply_static_light_to_visible_tiles()

	current_visible_tiles = visible_tiles.duplicate()
	#emit_signal("fov_updated", visible_tiles)
	update_object_visibility(grid_pos)

	if light_overlay.is_ready:
		update_light_map()

	# 🕒 Optional redraw (now uses is_ready flag)
	var time_now: float = Time.get_ticks_msec() / 1000.0
	if time_now - _last_visibility_update_time > VISIBILITY_UPDATE_INTERVAL:
		var has_nv: bool = LoadHandlerSingleton.player_has_nightvision()

		if light_overlay.is_ready:
			if light_overlay.should_redraw_light(current_visible_tiles, sunlight_level, has_nv):
				light_overlay.update_light_map(
					current_visible_tiles,
					light_map,
					sunlight_level,
					has_nv
				)

		_last_visibility_update_time = time_now

func update_light_map() -> void:
	if not light_overlay or not light_overlay.is_ready:
		#print("⏳ Skipping update_light_map() — LightOverlay not ready yet.")
		return

	# 🌌 1. Ambient fill (sunlight)
	for y in range(light_map.size()):
		for x in range(light_map[y].size()):
			var ambient_fade: float = lerp(0.1, 0.8, clamp(sunlight_level, 0.0, 1.0))
			light_map[y][x] = ambient_fade

	# 🔦 2. Player-held light radius
	var light_radius: int = LoadHandlerSingleton.get_player_light_radius()
	var light_pos: Vector2i = Vector2i(round(player.position.x / TILE_SIZE), round(player.position.y / TILE_SIZE))

	for y in range(-light_radius, light_radius + 1):
		for x in range(-light_radius, light_radius + 1):
			var offset := Vector2i(x, y)
			var pos := light_pos + offset
			if not is_in_bounds(pos):
				continue
			var dist := offset.length()
			if dist > light_radius:
				continue
			var intensity: float = clamp(1.0 - (dist / light_radius), 0.0, 1.0)
			light_map[pos.y][pos.x] = max(light_map[pos.y][pos.x], intensity)

	# 💡 3. Static lights the player *would be aware of*
	var static_sources = get_static_light_sources()
	var player_pos = Vector2i(player.position.x / TILE_SIZE, player.position.y / TILE_SIZE)
	var daytime_vision_radius := 20  # Approximate "memory of lamp locations"

	for source in static_sources:
		var center: Vector2i = source["pos"]
		var radius: int = source.get("radius", 3)
		var boost: float = source.get("boost", 1.5)

		var dist_to_player := (center - player_pos).length()
		var skip_visibility_check := sunlight_level > 0.85

		if not skip_visibility_check:
			if dist_to_player > daytime_vision_radius or not has_line_of_sight(player_pos, center, true):
				continue

		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var offset := Vector2i(x, y)
				var pos := center + offset

				if not is_in_bounds(pos):
					continue

				var dist := offset.length()
				if dist > radius:
					continue

				if pos != center and not has_line_of_sight(center, pos, true, true):
					continue

				var intensity: float = clamp(1.0 - (dist / radius), 0.0, 1.0)
				if sunlight_level <= 0.3:
					intensity *= boost

				light_map[pos.y][pos.x] = max(light_map[pos.y][pos.x], intensity)

				# 🧠 If the lamp is visible from the player (LOS not blocked), treat it as "revealed"
				if has_line_of_sight(player_pos, pos, true):
					if not visible_tiles.has(pos):
						visible_tiles[pos] = -2  # -2 means: visible because of static light
						light_overlay.dirty_tiles[pos] = true
						#print("👁️ Lamp-illuminated tile visible to player:", pos)


func _on_player_fov_updated(tiles):
	current_visible_tiles = tiles
	var has_nightvision := LoadHandlerSingleton.player_has_nightvision()
	light_overlay.update_light_map(
		current_visible_tiles,
		light_map,
		sunlight_level,
		has_nightvision
	)
	#print("🛰️ FOV signal received. Visible tiles:", visible_tiles.size())


func is_tile_transparent(pos: Vector2i) -> bool:
	if !is_in_bounds(pos):
		return false
	var cell = walkability_grid[pos.y][pos.x]
	return cell.get("transparent", true)

func is_in_bounds(pos: Vector2i) -> bool:
	return pos.y >= 0 and pos.y < walkability_grid.size() and pos.x >= 0 and pos.x < walkability_grid[0].size()

func calculate_sunlight_levels() -> void:
	tile_light_levels.clear()

	# 🕳️ Underground mode: freeze it as fully dark
	if LoadHandlerSingleton.is_underground():
		var new_sun_intensity := 0.8

		if !is_equal_approx(new_sun_intensity, sunlight_level):
			#print("🕳️ Underground mode: Forcing darkness")
			sunlight_level = new_sun_intensity
			for pos in current_visible_tiles.keys():
				light_overlay.dirty_tiles[pos] = true

		for tile in tile_container.get_children():
			var tile_pos = Vector2i(tile.position.x / TILE_SIZE, tile.position.y / TILE_SIZE)
			tile_light_levels[tile_pos] = sunlight_level

		# ✅ Static glow, with LOS
		var static_sources: Array = get_static_light_sources()
		for source in static_sources:
			var center: Vector2i = source["pos"]
			var radius: int = source["radius"]

			for y in range(-radius, radius + 1):
				for x in range(-radius, radius + 1):
					var offset: Vector2i = Vector2i(x, y)
					var pos: Vector2i = center + offset

					if !is_in_bounds(pos):
						continue

					var dist: float = offset.length()
					if dist > radius:
						continue

					# ✅ Respect line of sight
					if pos != center and not has_line_of_sight(center, pos, true, true):
						continue

					var strength: float = clamp(1.0 - (dist / radius), 0.0, 1.0)
					tile_light_levels[pos] = max(tile_light_levels.get(pos, 0.0), strength * 0.8)

		return

	# 🌞 Above-ground sunlight logic
	var time_data = LoadHandlerSingleton.get_time_and_date()
	var miltime: String = time_data.get("miltime", "1200")
	var hour := int(miltime.substr(0, 2))
	var minute := int(miltime.substr(2, 2))
	var total_minutes = hour * 60 + minute

	var new_sun_intensity := 0.8
	if total_minutes < 300:
		new_sun_intensity = 0.8
	elif total_minutes < 420:
		var t := float(total_minutes - 300) / 120.0
		new_sun_intensity = lerp(0.8, 1.0, t)
	elif total_minutes < 1200:
		new_sun_intensity = 1.0
	elif total_minutes < 1320:
		var t := float(total_minutes - 1200) / 120.0
		new_sun_intensity = lerp(1.0, 0.8, t)
	else:
		new_sun_intensity = 0.8

	if !is_equal_approx(new_sun_intensity, sunlight_level):
		#print("☀️ Sunlight level changed! Forcing redraw on changed tiles.")
		sunlight_level = new_sun_intensity
		for pos in current_visible_tiles.keys():
			light_overlay.dirty_tiles[pos] = true

	for tile in tile_container.get_children():
		var tile_pos = Vector2i(tile.position.x / TILE_SIZE, tile.position.y / TILE_SIZE)
		tile_light_levels[tile_pos] = sunlight_level

	# 💡 Optional: ambient tile glow from lit objects, if needed
	if sunlight_level <= 0.3:
		var static_sources: Array = get_static_light_sources()
		for source in static_sources:
			var center: Vector2i = source["pos"]
			var radius: int = source["radius"]

			for y in range(-radius, radius + 1):
				for x in range(-radius, radius + 1):
					var offset: Vector2i = Vector2i(x, y)
					var pos: Vector2i = center + offset

					if !is_in_bounds(pos):
						continue

					var dist: float = offset.length()
					if dist > radius:
						continue

					# ✅ LOS check
					if pos != center and not has_line_of_sight(center, pos, true):
						continue

					var strength: float = clamp(1.0 - (dist / radius), 0.0, 1.0)
					tile_light_levels[pos] = max(tile_light_levels.get(pos, 0.0), strength * 0.8)


func has_line_of_sight(from: Vector2i, to: Vector2i, strict := false, allow_darkness_pass := false) -> bool:
	var line = get_bresenham_line(from, to)

	for point in line:
		if not is_in_bounds(point):
			return false

		var cell = walkability_grid[point.y][point.x]
		var terrain_type: String = cell.get("terrain_type", "")
		var object_type: String = cell.get("object_type", "")
		var tile_state: Dictionary = cell.get("tile_state", {})

		var blocks_vision = Constants.is_blocking_vision(terrain_type, object_type, tile_state)

		# 👁️ Let light "pass" through darkness if requested
		if allow_darkness_pass and not blocks_vision:
			continue

		if blocks_vision:
			if strict or point != to:
				return false

	return true


func get_bresenham_line(from: Vector2i, to: Vector2i) -> Array:
	var points = []
	var x0 = from.x
	var y0 = from.y
	var x1 = to.x
	var y1 = to.y

	var dx = abs(x1 - x0)
	var dy = -abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy

	while true:
		points.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x0 += sx
		if e2 <= dx:
			err += dx
			y0 += sy

	return points

func is_pitch_black() -> bool:
	return sunlight_level <= 0.0
	
func update_object_visibility(player_grid_pos: Vector2i) -> void:
	var visibility_radius: int = 2
	var fade_radius: float = float(visibility_radius + 1)

	for obj: Node in tile_container.get_children():
		if not obj is Node2D or obj == player:
			continue

		var obj_node: Node2D = obj as Node2D
		var obj_grid_pos: Vector2i = Vector2i(obj_node.position.x / TILE_SIZE, obj_node.position.y / TILE_SIZE)

		var dist: float = (player_grid_pos - obj_grid_pos).length()
		var in_radius: bool = dist <= fade_radius
		var can_see: bool = current_visible_tiles.has(obj_grid_pos)

		if can_see:
			if sunlight_level >= 0.9:
				obj_node.modulate.a = 1.0
			else:
				var base_fade: float = clamp(1.0 - (dist / fade_radius), 0.0, 1.0)
				var sun_fade: float = clamp(1.0 - sunlight_level, 0.0, 1.0)
				var final_alpha: float = lerp(base_fade, 1.0, 1.0 - sun_fade)
				obj_node.modulate.a = final_alpha
		else:
			obj_node.modulate.a = 0.0

func rebuild_walkability():
	#print("🔁 Rebuilding walkability grid...")

	if current_tile_chunk == null or current_object_chunk == null:
		#print("❌ Cannot rebuild walkability — chunk data is null.")
		return

	var tile_dict: Dictionary = current_tile_chunk.get("tile_grid", {})
	if tile_dict.is_empty():
		print("⚠️ Tile dictionary is empty!")
	
	var object_dict: Dictionary = current_object_chunk  # Already flat format ✅
	#print("🧱 Processing %d object(s) into walk grid..." % object_dict.size())
	
	if object_dict.has("objects"):
		object_dict = object_dict["objects"]
	walkability_grid = LoadHandlerSingleton.build_walkability_grid(tile_dict, object_dict)

	#print("✅ Walkability grid rebuilt!")


func update_tile_at(pos: Vector2i):
	if not has_node("TileContainer"):
		#print("❌ No TileContainer found for tile update.")
		return

	var tile_container = $TileContainer
	var tile_dict = current_tile_chunk.get("tile_grid", {})
	var object_dict = current_object_chunk

	var key = "%d_%d" % [pos.x, pos.y]
	var tile_node_name = "tile_%s" % key
	var object_node_name = "obj_%s" % key

	if not tile_dict.has(key):
		#print("❌ Tile update failed — no tile data at:", key)
		return

	# 🧱 Update tile sprite
	var tile_data = tile_dict[key]
	var tile_name = tile_data.get("tile", "unknown")
	var tile_texture = Constants.get_texture_from_name(tile_name)

	var tile_node = tile_container.get_node_or_null(tile_node_name)
	if tile_node and tile_node is Sprite2D:
		tile_node.texture = tile_texture
	else:
		print("⚠️ Tile sprite not found at", tile_node_name)

	# 🧹 Remove old object sprite (if any)
	var old_object_node = tile_container.get_node_or_null(object_node_name)
	if old_object_node:
		old_object_node.queue_free()

	# 🕯️ Add updated object sprite if present
	var result = Constants.find_object_at(object_dict, pos.x, pos.y, true)
	if result.has("data"):
		var obj = result["data"]
		var obj_type = obj.get("type", "")
		var obj_state = obj.get("state", {})

		var obj_texture: Texture2D = null
		if obj_type == "candelabra":
			obj_texture = Constants.TILE_TEXTURES.get("candelabra_lit" if obj_state.get("is_lit", false) else "candelabra")
		elif obj_type == "slum_streetlamp":
			obj_texture = Constants.TILE_TEXTURES.get("slum_streetlamp" if obj_state.get("is_lit", false) else "slum_streetlamp_broken")
		else:
			obj_texture = Constants.get_object_texture(obj_type)

		if obj_texture:
			var sprite := Sprite2D.new()
			sprite.name = object_node_name
			sprite.texture = obj_texture
			sprite.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
			sprite.add_to_group("object_sprites")
			tile_container.add_child(sprite)
			print("🎨 Updated object at", pos, "→", obj_type)

func update_object_at(pos: Vector2i):
	if not has_node("TileContainer"):
		#print("❌ No TileContainer found for object update.")
		return

	var tile_container = $TileContainer
	var object_dict = current_object_chunk
	
		# 🛠️ Unwrap if needed
	if object_dict.has("objects"):
		object_dict = object_dict["objects"]

	# 🔥 Clear old object sprite at position
	for node in tile_container.get_children():
		if node.is_in_group("object_sprites") and node.position == Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE):
			#print("🧹 Removing old object sprite at", pos)
			node.queue_free()

	# 🔍 Find object at this position
	var obj = Constants.find_object_at(object_dict, pos.x, pos.y)
	if obj != null and obj.has("type"):
		var obj_type = obj["type"]
		var obj_state = obj.get("state", {})

		var obj_texture: Texture2D = null
		if obj_type == "candelabra":
			obj_texture = Constants.TILE_TEXTURES.get("candelabra_lit" if obj_state.get("is_lit", false) else "candelabra")
		else:
			obj_texture = Constants.get_object_texture(obj_type)

		if obj_texture != null:
			var new_obj = Sprite2D.new()
			new_obj.name = "obj_%d_%d" % [pos.x, pos.y]
			new_obj.texture = obj_texture
			new_obj.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
			new_obj.add_to_group("object_sprites")
			tile_container.add_child(new_obj)

			#print("👁️ Added object node named:", new_obj.name)
			#print("✨ Object at", pos, "updated visually to:", obj_type, "| Lit:", obj_state.get("is_lit", false))

func get_static_light_sources() -> Array:
	var lit_sources := []
	var object_defs = preload("res://constants/object_data.gd")

	# ✅ Use already-loaded current chunk data
	var object_dict = current_object_chunk
	if object_dict.has("objects"):
		object_dict = object_dict["objects"]

	for obj_id in object_dict:
		var obj = object_dict[obj_id]
		var obj_type = obj.get("type", "")
		var obj_state = obj.get("state", {})

		var props = object_defs.OBJECT_PROPERTIES.get(obj_type, {})
		if props.get("lightable", false) and obj_state.get("is_lit", false):
			var radius = props.get("light_radius", 3)
			var boost = props.get("boost", 1.0)
			var pos = obj.get("position", {})
			lit_sources.append({
				"pos": Vector2i(pos["x"], pos["y"]),
				"radius": radius,
				"boost": boost
			})

	#print("✨ Static light sources (from loaded chunk):", lit_sources.size())
	return lit_sources

	
func apply_static_light_to_visible_tiles() -> void:
	if not is_instance_valid(player):
		return

	var static_sources = get_static_light_sources()
	var player_pos = Vector2i(player.position.x / TILE_SIZE, player.position.y / TILE_SIZE)
	var memory_radius := 20

	for source in static_sources:
		var center = source["pos"]
		var radius = source.get("radius", 3)

		if (center - player_pos).length() > memory_radius:
			continue

		if not has_line_of_sight(player_pos, center, true):
			continue

		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var offset = Vector2i(x, y)
				var pos = center + offset

				if not is_in_bounds(pos):
					continue

				if offset.length() > radius:
					continue

				if pos != center and not has_line_of_sight(center, pos, true, true):
					continue

				# 🔒 Only insert if it doesn't override real visibility
				if not visible_tiles.has(pos):
					visible_tiles[pos] = 99999  # Special marker
					light_overlay.dirty_tiles[pos] = true



func get_tile_chunk() -> Dictionary:
	return current_tile_chunk

func get_object_chunk() -> Dictionary:
	return current_object_chunk

func get_npc_chunk() -> Dictionary:
	return current_npc_chunk

func get_current_chunk_id() -> String:
	return current_chunk_id

func get_current_chunk_size() -> Vector2i:
	var grid: Dictionary = current_tile_chunk.get("tile_grid", {})
	if grid.is_empty():
		return Vector2i(0, 0)

	# Derive width/height from keys like "x_y"
	var max_x = 0
	var max_y = 0

	for key in grid.keys():
		var parts = key.split("_")
		var x = int(parts[0])
		var y = int(parts[1])
		max_x = max(max_x, x)
		max_y = max(max_y, y)

	return Vector2i(max_x + 1, max_y + 1)
	
func check_for_chunk_transition(target_tile: Vector2i) -> bool:
	#print("🧭 Checking for chunk transition to:", target_tile)

	var current_chunk_id = LoadHandlerSingleton.get_current_chunk_id()
	var current_chunk_size = LoadHandlerSingleton.get_chunk_size_for_chunk_id(current_chunk_id)

	# Default edge math
	var width = current_chunk_size.x
	var height = current_chunk_size.y

	# 🔍 If we're still inside bounds, no transition needed
	if target_tile.x >= 0 and target_tile.x < width and target_tile.y >= 0 and target_tile.y < height:
		#print("✅ Target tile is within current chunk — no transition.")
		return false

	# 🌍 Convert target to global tile space
	var current_origin = LoadHandlerSingleton.get_chunk_origin(current_chunk_id)
	var global_tile = current_origin + target_tile
	#print("🌐 Global tile stepping into:", global_tile)

	# 📦 Use blueprint logic to resolve destination chunk
	var dest_info = ChunkTools.get_chunk_for_global_tile(global_tile)
	if dest_info == {}:
		#print("🚪 No valid chunk exists at that global tile — treat as area exit.")
		spawn_area_exit_popup()
		return true

	var new_chunk_id = dest_info["id"]
	var new_tile = dest_info["local"]

	if new_chunk_id == current_chunk_id:
		#print("✅ Still within current chunk after conversion — no transition.")
		return false

	# ⛔ Check if destination tile is walkable
	var new_chunk_coords = Vector2i(
		new_chunk_id.split("_")[1].to_int(),
		new_chunk_id.split("_")[2].to_int()
	)

	if not LoadHandlerSingleton.chunk_exists(new_chunk_coords):
		spawn_area_exit_popup()
		return true

	var target_origin := LoadHandlerSingleton.get_chunk_origin(new_chunk_id)
	var tile_global: Vector2i = target_origin + new_tile
	if not LoadHandlerSingleton.is_tile_walkable_in_chunk(new_chunk_coords, tile_global):
		#print("🚫 Destination tile in", new_chunk_id, "is not walkable:", new_tile)
		return true

	# 🧭 Explore tracking
	LoadHandlerSingleton.mark_chunk_as_explored(new_chunk_coords)

	#print("📦 Transitioning to:", new_chunk_id, "→ Tile:", new_tile)
	SceneManager.transition_to_chunk(new_chunk_id, new_tile)
	return true


func spawn_area_exit_popup():
	# ✅ Prevent duplicate popups from stacking
	if active_area_exit_popup != null and active_area_exit_popup.is_inside_tree():
		#print("⚠️ Area exit popup already visible — skipping spawn.")
		return

	#print("📦 Spawning area exit popup...")

	var popup_scene = preload("res://ui/scenes/LocalAreaExitPopup.tscn")
	var popup = popup_scene.instantiate()
	popup.name = "LocalAreaExitPopup"

	$UILayer.add_child(popup)

	# 📍 Center-ish position for now
	popup.position = Vector2(400, 200)
	popup.z_index = 100

	# 🔁 Track and store trigger tile
	active_area_exit_popup = popup
	var player_tile = Vector2i(player.position.x / TILE_SIZE, player.position.y / TILE_SIZE)
	popup.set_meta("trigger_tile", player_tile)

func load_z_level(z: int):
	#print("📡 load_z_level called with Z:", z)
	current_z_level = z
	load_and_render_local_map()

	# Read the saved spawn position (if any)
	var placement_data = LoadHandlerSingleton.load_temp_placement()
	var pos_data = placement_data.get("local_map", {}).get("spawn_pos", null)

	if pos_data != null:
		var spawn_tile = Vector2i(pos_data["x"], pos_data["y"])
		call_deferred("_deferred_spawn_player", spawn_tile)
	else:
		print("⚠️ No saved spawn_pos in placement_data. Using default.")


func _deferred_spawn_player(spawn_tile: Vector2i) -> void:
	await get_tree().process_frame
	var player = get_node_or_null("LocalMap/PlayerVisual")
	if player == null:
		#print("❌ Could not find PlayerVisual node.")
		return
	player.position = Vector2(spawn_tile * TILE_SIZE)
	player.last_grid_position = spawn_tile

	update_fov_from_player(spawn_tile)
	calculate_sunlight_levels()
	update_object_visibility(spawn_tile)

	#print("🧭 Player spawned at:", spawn_tile)

func get_egress_for_current_position(player_pos: Vector2i) -> Dictionary:
	var placement = LoadHandlerSingleton.load_temp_placement()
	var chunk_id = placement["local_map"].get("current_chunk_id", "")
	var z_level = int(placement["local_map"].get("z_level", 0))
	var biome_key = placement["local_map"].get("biome_key", "")
	var biome = Constants.get_biome_name_from_key(biome_key)

	var local_pos = {
		"x": player_pos.x,
		"y": player_pos.y,
		"z": z_level
	}

	var key = "%s|z%d" % [chunk_id, z_level]
	print("📦 Checking egress for key:", key)
	print("🧭 Player global pos & z:", local_pos, "biome:", biome)

	LoadHandlerSingleton.clear_cached_egress_register()
	var egress_data = LoadHandlerSingleton.load_global_egress_data(true)
	if not egress_data.has(key):
		print("❌ No egress data found under key:", key, "available keys:", egress_data.keys())
		return {}

	var chunk_origin = LoadHandlerSingleton.get_chunk_origin(chunk_id)
	print("💡 chunk_origin for chunk:", chunk_origin)

	for egress in egress_data[key]:
		var pos = egress["position"]
		var biome_match = egress["biome"] == biome
		if not biome_match:
			continue

		var local_x = pos["x"] - chunk_origin.x
		var local_y = pos["y"] - chunk_origin.y

		# exact global match?
		if pos["x"] == local_pos["x"] and pos["y"] == local_pos["y"] and pos["z"] == z_level:
			print("✅ Exact global match egress found:", egress)
			return egress

		# fallback: local match
		if local_x == player_pos.x and local_y == player_pos.y and pos["z"] == z_level:
			print("✅ Fallback local match egress found:", egress)
			return egress

	print("🚫 No matching egress found in key:", key)
	return {}


func get_visible_chunks() -> Array:
	# For now, we make visible_chunks be just the current chunk
	# Could be expanded later (neighboring chunks, etc.)
	return visible_chunks
