#localmap.gd - parent node script
extends Control

@onready var world_view: Node2D = $WorldView
@onready var tile_container: Node2D = $WorldView/TileContainer
@onready var world_map_button = $UILayer/DebugUI/WorldMap  # Adjust if needed
@onready var generate_button = $UILayer/DebugUI/GenNewMapDebugButton
@onready var toggle_free_pan_button = $UILayer/DebugUI/ToggleFreePan  # Free pan toggle button
@onready var bottom_ui = $UILayer/LocalPlayUI/BottomUI  # ✅ Reference the BottomUI node
@onready var dark_overlay = $UILayer/DarkOverlay
@onready var light_overlay: Node2D = $WorldView/LightOverlay
@onready var travel_log = $UILayer/LocalPlayUI/TravelLogControl
@onready var buildables_overlay := preload("res://scenes/play/BuildablesOverlay.tscn").instantiate()

@onready var pause_menu = preload("res://scenes/play/PauseMenu.tscn").instantiate()

@onready var npc_container: Node2D = $WorldView/NPCContainer
@onready var npc_underlay_container: Node2D = $WorldView/NPCUnderlayContainer

@onready var turn_manager := get_node_or_null("/root/TurnManager")

@onready var map_layers: Array[Node2D] = [
	$WorldView/TileContainer,
	$WorldView/NPCUnderlayContainer,
	$WorldView/NPCContainer
]

var light_map: Array = []  # 🌕 Stores per-tile light levels
var tile_light_levels: Dictionary = {}
var sunlight_level: float = 1.0
var is_full_daylight := sunlight_level >= 0.95  # max sunlight
var last_minute_seen: int = -1  # Add this at the top of localmap.gd
var player: Node = null  # 👤 Store player instance globally in this script
var visible_tiles := {}  # Stores tiles currently in vision
var current_visible_tiles: Dictionary = {}
var free_pan_enabled = true  # Default: OFF
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

enum TargetingMode { NONE, BUILD, AIM, INSPECT }
var targeting_mode: TargetingMode = TargetingMode.NONE
var targeting_cursor: Node = null  # instance of your TargetingCursor scene
var target_cursor_grid_pos: Vector2i = Vector2i.ZERO

var retry_attempts := 0
var cursor_realigned := false  # Global flag to avoid loops

var _last_world_view_pos: Vector2 = Vector2.ZERO
var _wvpos_initialized: bool = false

var chunk_id: String = LoadHandlerSingleton.get_current_chunk_id()
var placement: Dictionary = LoadHandlerSingleton.load_temp_localmap_placement()
var biome_key: String = placement.get("local_map", {}).get("biome_key", "")
var z_level: String = str(LoadHandlerSingleton.get_current_z_level())

var target_map_position: Vector2 = Vector2.ZERO
var is_sliding: bool = false
const SLIDE_SPEED := 6.0  # tweak: higher = faster snap

var _last_fov_grid: Vector2i = Vector2i(-999, -999)
var _last_fov_update_time: float = 0.0
var _los_cache: Dictionary = {}

var camera_tween: Tween
var camera_follow_speed := 6.0

var is_dragging := false
var last_mouse_pos: Vector2 = Vector2.ZERO


const MAX_RETRIES := 10

const TerrainData = preload("res://constants/terrain_data.gd")

const BuildData = preload("res://constants/build_data.gd")

const VISIBILITY_UPDATE_INTERVAL := 0.1  # seconds

const TEXTURES = Constants.TILE_TEXTURES

const TILE_SIZE = 88  # Each tile is 88x88 pixels

const NPC_VISIBILITY_RADIUS := 6.0
const NPC_UNDERLAY_ALPHA := 0.45
const NPC_MIN_ALPHA := 0.1

const CAMERA_SLIDE_DURATION := 0.12  # seconds
const CAMERA_EASING := 0.25          # softer easing for turn feel

func _ready():
	set_process_unhandled_input(true)
	process_mode = Node.PROCESS_MODE_ALWAYS  # 👈 allows input while paused
	if turn_manager:
		turn_manager.local_map_ref = self
		print("✅ LocalMap registered with TurnManager:", self)
	$UILayer.add_child(pause_menu)
	pause_menu.hide()
	pause_menu.z_index = 999
	#print("🔍 DEBUG: LocalMap.gd _ready() is running!")

	await get_tree().process_frame  # Let scene tree settle
	var cursor_scene = preload("res://scenes/play/TargetingCursor.tscn")
	targeting_cursor = cursor_scene.instantiate()
	print("TargetingCursor instance:", targeting_cursor, "visible:", targeting_cursor.visible, "z_index:", targeting_cursor.z_index)
	tile_container.add_child(targeting_cursor)
	# Make sure it's drawn above other things
	targeting_cursor.z_index = 900
	targeting_cursor.set_mode(TargetingMode.NONE)

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
	_precompute_fov_before_first_frame()

	print("TargetingCursor position:", targeting_cursor.position)
	if is_instance_valid(targeting_cursor):
		tile_container.move_child(targeting_cursor, tile_container.get_child_count() - 1)
	_attempt_cursor_realignment()

	
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
		
	$UILayer.add_child(buildables_overlay)
	buildables_overlay.visible = false
	
	# ✅ Cursor safety setup after full scene load
	call_deferred("_finalize_targeting_cursor")
	await get_tree().create_timer(0.3).timeout
	_attempt_cursor_realignment()
	
	# 👇 Add this right below
	call_deferred("_sync_fov_after_load")
	
	var weather_canvas = $WeatherCanvas
	if weather_canvas:
		weather_canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	
func load_and_render_local_map():
	# 🔒 Prevent first-frame NPC flash
	_set_npc_layers_visible(false)
	
	for child in tile_container.get_children():
		if child.name != "TargetingCursor":
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

	# 🧱 Optional: below-layer loader for upper z-levels (non-destructive)
	var below_tile_chunk: Dictionary = {}
	var below_object_chunk: Dictionary = {}
	var below_npc_chunk: Dictionary = {}
	
	print("🔎 z_level raw value:", z_level)

	if z_level != "0":
		var below_z_int := int(z_level.trim_prefix("z"))
		if below_z_int > 0:
			var below_path := LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_id, biome_key, str(below_z_int - 1))
			var below_object_path := LoadHandlerSingleton.get_chunked_object_chunk_path(chunk_id, biome_key, str(below_z_int - 1))
			var below_npc_path := LoadHandlerSingleton.get_chunked_npc_chunk_path(chunk_id, biome_key, str(below_z_int - 1))

			# 🕵️ Debug prints
			print("🧭 Current z_level:", z_level)
			print("📁 Expecting below z:", below_z_int - 1)
			print("🧩 Built below path:", below_path)

			# 🧩 Load below tiles
			if FileAccess.file_exists(below_path):
				below_tile_chunk = LoadHandlerSingleton.load_json_file(below_path)
				print("⬇️ Loaded below layer for visual underlay:", below_path)
				if below_tile_chunk.has("tile_grid"):
					print("🧱 BELOW LAYER LOADED →", below_tile_chunk["tile_grid"].size(), "tiles available for underlay.")
				else:
					print("⚠️ BELOW LAYER EMPTY OR MISSING.")
					
				print("🧩 Built below paths:")
				print("   ⬇️ Tile:", below_path)
				print("   ⬇️ Object:", below_object_path)
				print("   ⬇️ NPC:", below_npc_path)
						# 🧩 Load below-layer OBJECTS
			if FileAccess.file_exists(below_object_path):
				below_object_chunk = LoadHandlerSingleton.load_json_file(below_object_path)
				print("⬇️ Loaded below-layer objects:", below_object_path)

			# 🧩 Load below-layer NPCs
			if FileAccess.file_exists(below_npc_path):
				below_npc_chunk = LoadHandlerSingleton.load_json_file(below_npc_path)
				print("⬇️ Loaded below-layer NPCs:", below_npc_path)
	
	# ✅ Normalize below-layer data so MapRenderer can read it correctly
	if typeof(below_object_chunk) == TYPE_DICTIONARY:
		if not below_object_chunk.has("objects"):
			below_object_chunk = { "objects": below_object_chunk }
	else:
		below_object_chunk = { "objects": {} }

	if typeof(below_npc_chunk) == TYPE_DICTIONARY:
		if not below_npc_chunk.has("npcs"):
			below_npc_chunk = { "npcs": below_npc_chunk }
	else:
		below_npc_chunk = { "npcs": {} }
	
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
	
		# ✅ Reset transform origins before rendering
	tile_container.set_global_position(Vector2.ZERO)
	tile_container.set_position(Vector2.ZERO)
	tile_container.scale = Vector2.ONE

	var map_parent = tile_container.get_parent()
	if map_parent:
		map_parent.set_global_position(Vector2.ZERO)
		map_parent.set_position(Vector2.ZERO)
		map_parent.scale = Vector2.ONE
	
	# 🎨 Render map using chunks (now supports optional underlay)
	MapRenderer.render_map(tile_chunk, object_chunk, npc_chunk, tile_container, chunk_id, below_tile_chunk, below_object_chunk, below_npc_chunk)
		
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

	# 👁️ Compute FOV *now*, still with NPC layers hidden
	var grid_pos = Vector2i(player.position.x / TILE_SIZE, player.position.y / TILE_SIZE)
	update_fov_from_player(grid_pos)

	# 🚫 Ensure NPCs are masked *before* first visible frame
	apply_fov_to_npc_layers()

	# ✅ Now it’s safe to show them
	_set_npc_layers_visible(true)

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
	
	# 👁️ When FOV is updated for the first time, apply visibility mask to NPC layers
	player_instance.connect("fov_updated", func(_tiles):
		if has_method("apply_fov_to_npc_layers"):
			apply_fov_to_npc_layers()
	)

	# 🎨 Visuals
	var looks = LoadHandlerSingleton.load_player_looks()
	if looks != null:
		player_instance.apply_appearance(looks)
	else:
		print("⚠️ No player looks loaded — using default visuals.")

	tile_container.add_child(player_instance)

	update_fov_from_player(Vector2i(player_pos["x"], player_pos["y"]))
	#call_deferred("center_tile_container")
	# 🎥 Center camera on player once when map loads
	await get_tree().process_frame
	var vp: Vector2 = get_viewport_rect().size
	var target_pos: Vector2 = (vp * 0.5) - (player_instance.position * zoom_factor)
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(world_view, "position", target_pos, 0.25)

	#print("✅ Player visual spawned at (local):", player_pos, "→ World Pos:", Vector2(x, y))

func _on_WorldMap_pressed():
	#print("🌍 Returning to World Map...")

	# ✅ Transition to the refresh scene first
	get_tree().change_scene_to_file("res://scenes/play/LocaltoWorldRefresh.tscn")


func _on_GenNewMapDebugButton_pressed():
	#print("🛠 DEBUG: Generate New Map button pressed!")
	generate_local_map()

func center_tile_container():
	print("🌀 SMARTCAM center_tile_container called from:", get_stack())
	if player == null:
		return
	_center_on_anchor(player.position)
	
func _center_on_anchor(anchor_world_px: Vector2) -> void:
	print("🌀 SMARTCAM center_on_anchor called from:", get_stack())
	# 🧩 Prevent camera spam: ignore new calls if a tween is already in motion
	if camera_tween and camera_tween.is_running():
		print("🧩 SMARTCAM skip — tween still running")
		return

	var vp := get_viewport_rect().size
	var desired_pos: Vector2 = (vp * 0.5) - (anchor_world_px * zoom_factor)

	camera_tween = create_tween()
	camera_tween.set_ease(Tween.EASE_OUT)
	camera_tween.set_trans(Tween.TRANS_CUBIC)
	camera_tween.tween_property(world_view, "position", desired_pos, CAMERA_SLIDE_DURATION)


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

	if is_sliding:
			var current_pos: Vector2 = _get_map_position()
	#		
			# 🧭 Smooth damp: approach target at fixed speed (pixels/sec)
			var direction: Vector2 = target_map_position - current_pos
			var distance: float = direction.length()
			
			if distance < 0.5:
				_set_map_position(target_map_position)
				is_sliding = false
			else:
				var max_step: float = SLIDE_SPEED * delta * 88.0  # roughly 1 tile per speed unit
				var step: float = min(distance, max_step)
				var new_pos: Vector2 = current_pos + direction.normalized() * step
				_set_map_position(new_pos)
	
	if player and not free_pan_enabled and not is_sliding:
		var vp: Vector2 = get_viewport_rect().size
		var target: Vector2 = ((vp * 0.5) - (player.position * zoom_factor)).round()

		var camera_follow_speed := 6.0
		world_view.position = world_view.position.lerp(target, camera_follow_speed * delta)
				
func _set_map_scale(s: float) -> void:
	world_view.scale = Vector2(s, s)
	zoom_factor = s
		
func _set_map_position(p: Vector2) -> void:
	# Move the entire world
	world_view.position = p

func _get_map_position() -> Vector2:
	return world_view.position

# old center on anchor func
#func _center_on_anchor(anchor_world_px: Vector2) -> void:
	# Keep the given world pixel (e.g. player.position) centered in the view
#	var vp: Vector2 = get_viewport_rect().size
#	var pos: Vector2 = (vp * 0.5) - (anchor_world_px * zoom_factor)
#	_set_map_position(pos)

func zoom_in() -> void:
	if current_zoom_index > 0:
		current_zoom_index -= 1
		update_zoom()

func zoom_out() -> void:
	if current_zoom_index < zoom_levels.size() - 1:
		current_zoom_index += 1
		update_zoom()

func update_zoom() -> void:
	if world_view == null:
		return

	var new_zoom: float = zoom_levels[current_zoom_index]
	var old_zoom: float = zoom_factor
	if new_zoom == old_zoom:
		return

	var vp_size: Vector2 = get_viewport_rect().size
	var mouse_pos: Vector2 = get_viewport().get_mouse_position().clamp(Vector2.ZERO, vp_size)

	# 🧭 Lock pivot world-space point *before* zoom changes
	var pivot_world_before: Vector2 = (mouse_pos - world_view.position) / old_zoom

	# 🧱 Compute final position target *once*, before any tweening
	var target_pos: Vector2 = mouse_pos - pivot_world_before * new_zoom

	# 🧩 Immediately apply scale target but don’t tween both independently
	# Instead, tween them in a grouped, atomic way
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_parallel(true)
	tween.tween_property(world_view, "scale", Vector2(new_zoom, new_zoom), 0.2)
	tween.tween_property(world_view, "position", target_pos, 0.2)
	tween.set_parallel(false)

	zoom_factor = new_zoom


func _apply_zoom_step(val: float) -> void:
	_set_map_scale(val)


func _unhandled_input(event):
	if is_in_targeting_mode():
		if event.is_action_pressed("ui_cancel"):
			exit_targeting()
			if get_viewport() != null:
				get_viewport().set_input_as_handled()
			else:
				print("⚠️ Viewport is null when trying to set input as handled.")
			return
	
	# 🟡 Give ESC key to exit popup first
	if event.is_action_pressed("ui_cancel"):
		if active_area_exit_popup and is_instance_valid(active_area_exit_popup):
			active_area_exit_popup.queue_free()
			active_area_exit_popup = null
			get_viewport().set_input_as_handled()
			return

		# 🟢 Close any active inventory / trade / loot windows before showing pause menu
	if event.is_action_pressed("ui_cancel"):
		var ui_layer := get_node_or_null("UILayer")
		if ui_layer:
			for child in ui_layer.get_children():
				# Match all dynamic inventory or trade UIs
				var n := child.name
				if (
					(n.begins_with("Inventory_mini") or
					n.begins_with("ChestInventoryUI") or
					n.begins_with("TradeInventoryUI"))
					and child.visible
				):
					print("🧭 Closing UI window:", n)
					child.queue_free()
					get_viewport().set_input_as_handled()
					return

	# Toggle pause menu
	if event.is_action_pressed("ui_cancel"):
		if pause_menu.visible:
			pause_menu.hide()
			get_tree().paused = false
		else:
			pause_menu.show()
			get_tree().paused = true
		get_viewport().set_input_as_handled()
		return
		
	# Zoom remains globally available
	if event.is_action_pressed("local_zoom_in"):
		zoom_in()
	elif event.is_action_pressed("local_zoom_out"):
		zoom_out()

	# 🖱️ Click-and-drag camera panning
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			is_dragging = true
			last_mouse_pos = get_viewport().get_mouse_position()
		elif event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
			is_dragging = false

	elif event is InputEventMouseMotion and is_dragging:
		var mouse_delta: Vector2 = event.relative
		world_view.position += mouse_delta

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

func handle_panning(delta: float) -> void:
	if world_view == null:
		return

	# 1) Try the compact vector first
	var move_vector := Input.get_vector("pan_left", "pan_right", "pan_up", "pan_down")

	# 2) Fallback: manual sampling (covers mis-bound actions)
	if move_vector == Vector2.ZERO:
		if Input.is_action_pressed("pan_up"):
			move_vector.y -= 1   # up is negative Y
		if Input.is_action_pressed("pan_down"):
			move_vector.y += 1
		if Input.is_action_pressed("pan_left"):
			move_vector.x -= 1
		if Input.is_action_pressed("pan_right"):
			move_vector.x += 1

	# If still nothing, bail
	if move_vector == Vector2.ZERO:
		return

	# Normalize + move whole world
	move_vector = move_vector.normalized()
	var adjusted_speed: float = float(pan_speed) / max(zoom_factor, 0.0001)

	# Debug once per press to confirm we're reading input
	# print("PAN vec:", move_vector, " adj:", adjusted_speed, " pos(before):", world_view.position)

	world_view.position -= move_vector * adjusted_speed * delta
	# print("pos(after):", world_view.position)


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
		
		"tradepost":
			# ✅ Use optional hub name, fallback to Tradepost
			var hub_name = entry_context.get("hub_name", "Tradepost")
			label_node.text = hub_name
		
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
	# 🧠 Skip expensive FOV if player hasn't moved to a new tile
	if _last_fov_grid == grid_pos:
		return
	_last_fov_grid = grid_pos
	#print("🔦 FOV update from:", grid_pos)
	
	# 🕒 Limit FOV updates to at most 20 per second (~0.05s)
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_fov_update_time < 0.05:
		return
	_last_fov_update_time = now

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
		call_deferred("update_light_map")

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
		
	_los_cache.clear()
	
	
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
	var key := str(from.x, "_", from.y, "_", to.x, "_", to.y)
	if _los_cache.has(key):
		return _los_cache[key]

	var line = get_bresenham_line(from, to)
	for point in line:
		if not is_in_bounds(point):
			_los_cache[key] = false
			return false
		var cell = walkability_grid[point.y][point.x]
		var terrain_type: String = cell.get("terrain_type", "")
		var object_type: String = cell.get("object_type", "")
		var tile_state: Dictionary = cell.get("tile_state", {})
		var blocks_vision = Constants.is_blocking_vision(terrain_type, object_type, tile_state)
		if allow_darkness_pass and not blocks_vision:
			continue
		if blocks_vision:
			if strict or point != to:
				_los_cache[key] = false
				return false
	_los_cache[key] = true
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

	# =====================================================
	# 🎨 BASE TILE / OBJECT VISIBILITY
	# =====================================================
	for obj: Node in tile_container.get_children():
		if not obj is Node2D or obj == player:
			continue

		var obj_node: Node2D = obj as Node2D
		var obj_grid_pos: Vector2i = Vector2i(obj_node.position.x / TILE_SIZE, obj_node.position.y / TILE_SIZE)

		var dist: float = (player_grid_pos - obj_grid_pos).length()
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

	# =====================================================
	# 🧍 EXTEND VISIBILITY TO NPC LAYERS
	# =====================================================
	apply_fov_to_npc_layers()

# ==========================================================
# 👁️ NPC FOV / VISIBILITY EXTENSIONS
# ==========================================================

func _apply_fov_to_npc_layer(layer: Node2D, is_underlay: bool) -> void:
	if layer == null or player == null:
		return

	var player_grid: Vector2i = Vector2i(int(round(player.position.x / TILE_SIZE)), int(round(player.position.y / TILE_SIZE)))
	var fade_radius: float = float(NPC_VISIBILITY_RADIUS)

	for c in layer.get_children():
		if not (c is Sprite2D and c.has_meta("npc_id")):
			continue

		var spr: Sprite2D = c
		var gpos: Vector2i = Vector2i(int(round(spr.position.x / TILE_SIZE)), int(round(spr.position.y / TILE_SIZE)))

		# 🧱 NEW: prevent out-of-bounds NPCs from being drawn at all
		if not is_in_bounds(gpos):
			spr.visible = false
			continue

		var visible: bool = current_visible_tiles.has(gpos)

		if not visible:
			spr.visible = false
			continue

		spr.visible = true

		# ✅ Vector2i has no .distance_to(), so use length() on the difference
		var delta: Vector2i = gpos - player_grid
		var dist: float = float(delta.length())

		# Distance-based fade
		var base_fade: float = clamp(1.0 - (dist / (fade_radius + 0.0001)), NPC_MIN_ALPHA, 1.0)

		# Dimmer in darkness
		var alpha: float = lerp(base_fade, 1.0, sunlight_level)

		# Underlay (lower Z-level)
		if is_underlay:
			alpha *= NPC_UNDERLAY_ALPHA

		var tint: Color = spr.modulate
		tint.a = alpha
		spr.modulate = tint


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
	if not has_node("WorldView/TileContainer"):
		print("⚠️ No TileContainer found for tile update.")
		return

	var tile_container: Node2D = $WorldView/TileContainer
	var tile_dict = current_tile_chunk.get("tile_grid", {})
	var object_dict = current_object_chunk
	var key = "%d_%d" % [pos.x, pos.y]

	if not tile_dict.has(key):
		print("⚠️ Tile update failed — no tile data at:", key)
		return

	# 🧱 Refresh tile texture
	var tile_data: Dictionary = tile_dict[key]
	var tile_name: String = tile_data.get("tile", "unknown")
	var tile_texture: Texture2D = Constants.get_texture_from_name(tile_name)

	var tile_node_name = "tile_%s" % key
	var tile_node: Sprite2D = tile_container.get_node_or_null(tile_node_name)
	if tile_node:
		tile_node.texture = tile_texture
	else:
		# if we somehow lost it, spawn a new tile
		var new_tile := Sprite2D.new()
		new_tile.name = tile_node_name
		new_tile.texture = tile_texture
		new_tile.position = Vector2(pos.x * TILE_SIZE, pos.y * TILE_SIZE)
		tile_container.add_child(new_tile)
		print("🎨 Reconstructed missing tile sprite at", pos)

	# 🔦 Flag tile as dirty for lighting update
	if light_overlay and "dirty_tiles" in light_overlay:
		light_overlay.dirty_tiles[pos] = true

	# 🧹 Object sync handled by update_object_at
	if has_method("update_object_at"):
		update_object_at(pos)


func update_object_at(pos: Vector2i):
	if not has_node("TileContainer"):
		#print("❌ No TileContainer found for object update.")
		return

	var tile_container: Node2D = $WorldView/TileContainer
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
					
	propagate_light_from_lower_z()
	
func propagate_light_from_lower_z() -> void:
	var current_z: int = LoadHandlerSingleton.get_current_z_level()
	print("[belowlighttest] 🔽 Entering propagate_light_from_lower_z() — current_z:", current_z)

	var lower_z: int = current_z - 1
	print("[belowlighttest] Calculated lower_z:", lower_z)
	if lower_z < 0:
		print("[belowlighttest] 🛑 No lower z-level (already at z0)")
		return

	var chunk_id: String = LoadHandlerSingleton.get_current_chunk_id()
	var placement: Dictionary = LoadHandlerSingleton.load_temp_localmap_placement()
	var biome_key: String = str(placement.get("local_map", {}).get("biome_key", ""))

	print("[belowlighttest] ▶ Checking lower light propagation | current_z:", current_z, "| lower_z:", lower_z, "| biome:", biome_key, "| chunk_id:", chunk_id)

	# 🔍 Build correct path
	var lower_object_path: String = LoadHandlerSingleton.get_chunked_object_chunk_path(chunk_id, biome_key, str(lower_z))
	print("[belowlighttest] 🔍 lower_object_path =", lower_object_path)
	if not FileAccess.file_exists(lower_object_path):
		print("[belowlighttest] ❌ No lower object chunk file exists at:", lower_object_path)
		return

	# 📦 Load and normalize object structure
	var lower_object_chunk: Dictionary = LoadHandlerSingleton.load_json_file(lower_object_path)
	var objs: Dictionary = lower_object_chunk["objects"] if lower_object_chunk.has("objects") else lower_object_chunk
	print("[belowlighttest] 📦 Loaded lower object chunk with", objs.size(), "entries.")

	if objs.is_empty():
		print("[belowlighttest] ⚠️ lower objects dict empty, nothing to light")
		return

	# 🧱 Load object definitions
	var object_defs = preload("res://constants/object_data.gd")
	var lower_sources: Array = []

	for obj_id in objs.keys():
		var obj: Dictionary = objs[obj_id]
		var obj_type: String = str(obj.get("type", ""))
		var obj_state: Dictionary = obj.get("state", {}) as Dictionary
		var props: Dictionary = object_defs.OBJECT_PROPERTIES.get(obj_type, {}) as Dictionary

		if bool(props.get("lightable", false)) and bool(obj_state.get("is_lit", false)):
			var pos_dict: Dictionary = obj.get("position", {}) as Dictionary
			var center: Vector2i = Vector2i(int(pos_dict.get("x", 0)), int(pos_dict.get("y", 0)))
			var radius: int = int(props.get("light_radius", 3))
			var boost: float = float(props.get("boost", 1.0))
			lower_sources.append({
				"pos": center,
				"radius": radius,
				"boost": boost,
				"type": obj_type
			})
			print("[belowlighttest] 💡 Found lit lower object:", obj_type, "at", center, "| radius:", radius)
		elif bool(props.get("lightable", false)):
			print("[belowlighttest] 🔕 Object", obj_type, "is lightable but not lit (is_lit:", obj_state.get("is_lit", false), ")")

	if lower_sources.is_empty():
		print("[belowlighttest] ⚠️ No active lit objects found in lower_z:", lower_z)
		return

	print("[belowlighttest] 🔦 Found", lower_sources.size(), "lower-z light sources, checking visibility...")

	var player_pos: Vector2i = Vector2i(int(player.position.x / TILE_SIZE), int(player.position.y / TILE_SIZE))
	print("[belowlighttest] 🧭 Player position:", player_pos)

	var above_grid: Dictionary = current_tile_chunk.get("tile_grid", {})
	if above_grid.is_empty():
		print("[belowlighttest] ❌ current_tile_chunk.tile_grid is empty — cannot verify openair tiles")
		return

	var visible_count := 0

	for source in lower_sources:
		var center: Vector2i = source["pos"]
		var radius: int = int(source["radius"])
		var boost: float = float(source["boost"])
		var obj_type: String = source["type"]

		var dist := (center - player_pos).length()
		if dist > 30:
			print("[belowlighttest] ⏩ Skipping", obj_type, "at", center, "(too far from player:", dist, ")")
			continue

		var above_key: String = "%d_%d" % [center.x, center.y]
		if not above_grid.has(above_key):
			print("[belowlighttest] ❓ No above tile entry for", above_key)
			continue

		var above_info: Dictionary = above_grid[above_key]
		var above_tile: String = str(above_info.get("tile", ""))
		if above_tile != "openair":
			print("[belowlighttest] 🚫 Blocked above:", above_tile, "at", above_key)
			continue

		print("[belowlighttest] ✅ Openair above source:", obj_type, "at", center, "| radius:", radius)

		for y in range(-radius, radius + 1):
			for x in range(-radius, radius + 1):
				var offset: Vector2i = Vector2i(x, y)
				var distf := offset.length()
				if distf > float(radius):
					continue

				var pos: Vector2i = center + offset
				if not is_in_bounds(pos):
					continue
				if not has_line_of_sight(center, pos, true, true):
					continue

				var intensity: float = clamp(1.0 - (distf / float(radius)), 0.0, 1.0)
				if sunlight_level <= 0.3:
					intensity *= boost

				if light_map.has(pos.y) and pos.x < light_map[pos.y].size():
					light_map[pos.y][pos.x] = max(light_map[pos.y][pos.x], intensity)

				if not visible_tiles.has(pos):
					visible_tiles[pos] = 88888
					visible_count += 1
					print("[belowlighttest] ✨ Lower light illuminated tile:", pos, "intensity:", intensity)
				if is_instance_valid(light_overlay):
					light_overlay.dirty_tiles[pos] = true

	print("[belowlighttest] ✅ Finished propagation. Total new visible tiles:", visible_count)


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
	# 🔒 Static hub override — single-chunk biomes exit directly to worldmap
	var entry_type = LoadHandlerSingleton.load_entry_context().get("entry_type", "explore")
	if entry_type in ["tradepost", "guildhall", "temple"]:
		var current_chunk_size = get_current_chunk_size()
		if target_tile.x < 0 or target_tile.x >= current_chunk_size.x or target_tile.y < 0 or target_tile.y >= current_chunk_size.y:
			print("🚪 Leaving static hub (single-chunk biome) → area exit popup.")
			spawn_area_exit_popup()
			return true
		# ✅ Inside hub bounds — normal movement, no transition
		return false
			
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
	var placement_data: Dictionary = LoadHandlerSingleton.load_temp_localmap_placement()
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
	
	# 🧠 NEW: ensures NPC visibility syncs on first frame
	if has_method("apply_fov_to_npc_layers"):
		apply_fov_to_npc_layers()

	print("🧭 Player spawned at:", spawn_tile)
	#print("🧭 Player spawned at:", spawn_tile)

func get_egress_for_current_position(player_pos: Vector2i) -> Dictionary:
	var placement: Dictionary = LoadHandlerSingleton.load_temp_localmap_placement()
	var chunk_id: String = placement.get("local_map", {}).get("current_chunk_id", "")
	var z_raw: Variant = placement.get("local_map", {}).get("z_level", 0)
	var z_int: int = LoadHandlerSingleton.z_to_int(z_raw)
	var key: String = "%s|%s" % [chunk_id, LoadHandlerSingleton.z_key(z_int)]

	var biome_key: String = placement.get("local_map", {}).get("biome_key", "")
	var biome_name: String = Constants.get_biome_name_from_key(biome_key)

	var local_pos := {"x": player_pos.x, "y": player_pos.y, "z": z_int}
	print("📦 Checking egress for key:", key)
	print("🧭 Player local pos & z:", local_pos, "biome:", biome_name)

	LoadHandlerSingleton.clear_cached_egress_register()
	var egress_data: Dictionary = LoadHandlerSingleton.load_global_egress_data(true)
	if not egress_data.has(key):
		print("❌ No egress data under key:", key, "keys:", egress_data.keys())
		return {}

	var chunk_origin := LoadHandlerSingleton.get_chunk_origin(chunk_id)
	print("💡 chunk_origin for chunk:", chunk_origin)

	for egress in egress_data[key]:
		var pos: Dictionary = egress.get("position", {})
		if egress.get("biome", "") != biome_name:
			continue

		var local_x: int = int(pos.get("x", -999)) - chunk_origin.x
		var local_y: int = int(pos.get("y", -999)) - chunk_origin.y
		var pos_z: int = LoadHandlerSingleton.z_to_int(pos.get("z", 0))

		if pos["x"] == player_pos.x + chunk_origin.x and pos["y"] == player_pos.y + chunk_origin.y and pos_z == z_int:
			print("✅ Exact global match egress found:", egress)
			return egress

		if local_x == player_pos.x and local_y == player_pos.y and pos_z == z_int:
			print("✅ Fallback local match egress found:", egress)
			return egress

	print("🚫 No matching egress found in key:", key)
	return {}



func get_visible_chunks() -> Array:
	# For now, we make visible_chunks be just the current chunk
	# Could be expanded later (neighboring chunks, etc.)
	return visible_chunks
	
func enter_targeting(mode: TargetingMode) -> void:
	targeting_mode = mode

	# Toggle overlay visibility here
	if is_instance_valid(buildables_overlay):
		buildables_overlay.visible = (mode == TargetingMode.BUILD)

	if is_instance_valid(targeting_cursor):
		targeting_cursor.set_mode(mode)
		targeting_cursor.visible = true
	else:
		print("❌ Targeting cursor invalid in enter_targeting")

	call_deferred("_place_cursor_at_player_deferred")

func _place_cursor_at_player_deferred() -> void:
	if not is_inside_tree():
		if retry_attempts < MAX_RETRIES:
			retry_attempts += 1
			call_deferred("_place_cursor_at_player_deferred")
		else:
			print("❌ Failed to place cursor after retries.")
		return

	await get_tree().process_frame

	if not is_instance_valid(player):
		print("⚠️ No player instance found.")
		return

	var player_grid_pos = Vector2i(player.position / TILE_SIZE)
	target_cursor_grid_pos = player_grid_pos

	if is_instance_valid(targeting_cursor):
		targeting_cursor.set_grid_position(player_grid_pos, TILE_SIZE)
	else:
		print("❌ Targeting cursor not valid in deferred placement.")
		
func _deferred_enter_targeting(mode: TargetingMode) -> void:
	await get_tree().process_frame  # wait a frame to let player position finalize

	if not is_instance_valid(player):
		print("❌ Player node is not valid yet.")
		return

	var player_grid_pos = Vector2i(player.position / TILE_SIZE)
	target_cursor_grid_pos = player_grid_pos

	if is_instance_valid(targeting_cursor):
		targeting_cursor.set_mode(mode)
		targeting_cursor.set_grid_position(player_grid_pos, TILE_SIZE)
		targeting_cursor.visible = true
		print("🎯 Deferred enter_targeting: cursor placed at player:", player_grid_pos)
	else:
		print("❌ Targeting cursor is not valid!")

	# Build overlay toggle
	if is_instance_valid(buildables_overlay):
		buildables_overlay.visible = (mode == TargetingMode.BUILD)

	call_deferred("update_target_cursor_position")


func _position_cursor_at_player(mode: TargetingMode) -> void:
	if not is_inside_tree():
		print("⚠️ _position_cursor_at_player: node not in tree yet.")
		return

	if not is_instance_valid(player):
		print("⚠️ _position_cursor_at_player: player still invalid. Retrying shortly.")
		await get_tree().create_timer(0.2).timeout
		if not is_instance_valid(player):
			print("❌ _position_cursor_at_player: player invalid after wait. Aborting.")
			return

	var player_grid_pos = Vector2i(player.position / TILE_SIZE)
	target_cursor_grid_pos = player_grid_pos
	print("📍 _position_cursor_at_player: repositioning cursor to", player_grid_pos)

	if is_instance_valid(targeting_cursor):
		targeting_cursor.set_mode(mode)
		targeting_cursor.set_grid_position(player_grid_pos, TILE_SIZE)
		targeting_cursor.visible = true
	else:
		print("❌ _position_cursor_at_player: targeting_cursor still invalid!")


func exit_targeting() -> void:
	var was_in_build_mode := (targeting_mode == TargetingMode.BUILD)
	targeting_mode = TargetingMode.NONE

	if is_instance_valid(targeting_cursor):
		targeting_cursor.visible = false
	if is_instance_valid(buildables_overlay):
		buildables_overlay.visible = false

	var chunk_id = LoadHandlerSingleton.get_current_chunk_id()
	var placement = LoadHandlerSingleton.load_temp_localmap_placement()
	var biome_key = placement.get("local_map", {}).get("biome_key", "")
	var z_level = str(LoadHandlerSingleton.get_current_z_level())

	if was_in_build_mode:
		hard_refresh_chunk_on_build_mode_exit(chunk_id, biome_key, z_level, true)
		rebuild_walkability()

		
func move_target_cursor(delta: Vector2i) -> void:
	target_cursor_grid_pos += delta
	if is_instance_valid(targeting_cursor):
		targeting_cursor.set_grid_position(target_cursor_grid_pos, TILE_SIZE)
	else:
		print("⚠️ Targeting cursor not valid on move.")

func is_in_targeting_mode() -> bool:
	return targeting_mode != TargetingMode.NONE

func get_current_targeting_mode() -> TargetingMode:
	return targeting_mode

func get_chunk_coords_from_tile(tile_pos: Vector2i) -> Vector2i:
	var chunk_id := LoadHandlerSingleton.get_current_chunk_id()
	var chunk_origin := LoadHandlerSingleton.get_chunk_origin(chunk_id)
	var global_tile_pos := chunk_origin + tile_pos

	var chunk_info := ChunkTools.get_chunk_for_global_tile(global_tile_pos)
	if chunk_info.has("id"):
		var parts: PackedStringArray = chunk_info["id"].split("_")
		if parts.size() == 3:
			return Vector2i(parts[1].to_int(), parts[2].to_int())
	
	push_warning("⚠️ Could not resolve chunk coords for tile_pos: %s (global: %s)" % [tile_pos, global_tile_pos])
	return Vector2i.ZERO


func get_current_z_level() -> int:
	var placement := LoadHandlerSingleton.load_temp_localmap_placement()
	return placement.get("local_map", {}).get("z_level", 0)

func is_valid_build_position(pos: Vector2i) -> bool:
	var placement := LoadHandlerSingleton.load_temp_localmap_placement()
	var player_pos: Dictionary = placement.get("local_map", {}).get("grid_position_local", {})

	if player_pos.get("x", -999) == pos.x and player_pos.get("y", -999) == pos.y:
		return false  # ❌ Player tile

	var walk_grid = walkability_grid
	if pos.y >= 0 and pos.y < walk_grid.size() and pos.x >= 0 and pos.x < walk_grid[0].size():
		var cell: Dictionary = walk_grid[pos.y][pos.x]

		if not cell.get("walkable", false):
			return false  # ❌ Not walkable

		var raw_terrain_type: String = cell.get("terrain_type", "")
		var terrain_type := raw_terrain_type

		# 🧼 Normalize terrain (e.g., "stonedoor_open" → "stonedoor")
		if terrain_type.ends_with("_open"):
			var stripped := terrain_type.replace("_open", "")
			if TerrainData.TERRAIN_PROPERTIES.has(stripped):
				terrain_type = stripped

		print("🌍 Tile type:", terrain_type)
		var terrain_info: Dictionary = TerrainData.TERRAIN_PROPERTIES.get(terrain_type, {})

		if terrain_info.get("door", false):
			return false  # ❌ Always disallow building on doors

		if terrain_info.get("block_building", false):
			return false

	# 🧍 Block NPC overlap
	var chunk_id := LoadHandlerSingleton.get_current_chunk_id()
	var npc_chunk: Dictionary = LoadHandlerSingleton.get_npcs_in_chunk(chunk_id)

	for npc_id in npc_chunk.keys():
		var npc: Dictionary = npc_chunk[npc_id]
		if not npc.has("position"):
			continue

		var npc_pos := Vector2i(
			int(npc["position"].get("x", -1)),
			int(npc["position"].get("y", -1))
		)

		if npc_pos == pos:
			return false  # ❌ Can't build on NPCs

	return true  # ✅ All checks passed

func _finalize_targeting_cursor() -> void:
	await get_tree().process_frame  # ensure frame settles

	if player and is_instance_valid(targeting_cursor):
		var grid_pos = Vector2i(player.position / TILE_SIZE)
		target_cursor_grid_pos = grid_pos
		targeting_cursor.set_grid_position(grid_pos, TILE_SIZE)
		print("🎯 Post-load cursor forced to player grid pos:", grid_pos)

		# Remove or comment this! It auto-re-enters targeting:
		# if LoadHandlerSingleton.is_holding_hammer_tool():
		#     enter_targeting(TargetingMode.BUILD)

func hard_refresh_chunk_on_build_mode_exit(chunk_id: String, biome_key: String, z_level: String, force_reload: bool = false) -> void:
	var tile_container := get_tree().root.get_node_or_null("LocalMap/TileContainer")
	if tile_container == null:
		print("❌ TileContainer not found — cannot refresh visuals.")
		return

	var tile_path := LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_id, biome_key, z_level)
	var object_path := LoadHandlerSingleton.get_chunked_object_chunk_path(chunk_id, biome_key, z_level)
	var npc_path := LoadHandlerSingleton.get_chunked_npc_chunk_path(chunk_id, biome_key, z_level)

	var tile_data: Dictionary = LoadHandlerSingleton.load_json_file(tile_path)
	var object_data: Dictionary = LoadHandlerSingleton.load_json_file(object_path)
	var npc_data: Dictionary = LoadHandlerSingleton.load_json_file(npc_path)

	# ✅ Optional below layer
	var below_tile_data: Dictionary = {}
	if z_level != "z0":
		var below_z := int(z_level.trim_prefix("z")) - 1
		var below_path := LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_id, biome_key, "z%d" % below_z)
		if FileAccess.file_exists(below_path):
			below_tile_data = LoadHandlerSingleton.load_json_file(below_path)

	MapRenderer.render_map(tile_data, { "objects": object_data }, npc_data, tile_container, chunk_id, below_tile_data)

	if force_reload:
		print("🔁 Forcing full chunk reload to initialize tile behavior.")
		var player_pos_dict: Dictionary = LoadHandlerSingleton.load_temp_localmap_placement().get("local_map", {}).get("grid_position_local", {})
		var player_pos := Vector2i(
			int(player_pos_dict.get("x", 0)),
			int(player_pos_dict.get("y", 0))
		)
		SceneManager.transition_to_chunk(chunk_id, player_pos)

		
func place_current_buildable_at(grid_pos: Vector2i) -> void:
	var build_reg: Dictionary = LoadHandlerSingleton.load_player_buildreg()
	var build_key: String = build_reg.get("current_build", "")
	if build_key == "":
		push_warning("❌ No current build selected.")
		return

	print("📦 Current build key:", build_key)

	var build_data: Dictionary = BuildData.BUILD_PROPERTIES.get(build_key, null)
	if build_data == null:
		push_warning("❌ Build data not found for: " + build_key)
		return

	print("📚 Build data found:", build_data)

	var chunk_id: String = LoadHandlerSingleton.get_current_chunk_id()
	var placement: Dictionary = LoadHandlerSingleton.load_temp_localmap_placement()
	var biome_key: String = placement.get("local_map", {}).get("biome_key", "")
	var z_level: String = str(LoadHandlerSingleton.get_current_z_level())
	var chunk_origin: Vector2i = LoadHandlerSingleton.get_chunk_origin(chunk_id)

	var local_x: int = grid_pos.x
	var local_y: int = grid_pos.y

	print("🧭 Chunk ID:", chunk_id)
	print("🌍 Biome key:", biome_key)
	print("🗺️ Z level:", z_level)
	print("🧱 Chunk origin:", chunk_origin)
	print("🎯 Local grid pos:", grid_pos)

	if build_data.get("type", "") == "tile":
		var tile_path: String = LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_id, biome_key, z_level)
		print("📄 Tile path to modify:", tile_path)

		var tile_data: Dictionary = LoadHandlerSingleton.load_json_file(tile_path)
		var tile_grid: Dictionary = tile_data.get("tile_grid", {})

		var key: String = "%d_%d" % [local_x, local_y]
		print("🧩 Tile key to set:", key)
		print("🧱 Tile name to place:", build_data.get("terrain_name", ""))

		tile_grid[key] = {
			"tile": build_data.get("terrain_name", ""),
			"state": LoadHandlerSingleton.get_tile_state_for(build_data.get("terrain_name", ""))
		}

		tile_data["tile_grid"] = tile_grid
		LoadHandlerSingleton.save_json_file(tile_path, tile_data)

	elif build_data.get("type", "") == "object":
		var object_path: String = LoadHandlerSingleton.get_chunked_object_chunk_path(chunk_id, biome_key, z_level)
		print("📄 Object path to modify:", object_path)

		var object_data: Dictionary = LoadHandlerSingleton.load_json_file(object_path)

		var id: String
		if build_data.get("cat", "") == "storage":
			id = "%s_%d_%d" % [build_data.get("object_name", "unknown"), local_x, local_y]
		else:
			var next_id: String = str(randi() % 100000)
			id = "%s_%s" % [build_data.get("object_name", "unknown"), next_id]

		print("🆔 Generated object ID:", id)
		print("📦 Object type:", build_data.get("object_name", "unknown"))
		print("📌 Placing at:", { "x": local_x, "y": local_y, "z": int(z_level) })

		object_data[id] = {
			"type": build_data.get("object_name", "unknown"),
			"position": { "x": local_x, "y": local_y, "z": int(z_level) }
		}

		LoadHandlerSingleton.save_json_file(object_path, object_data)

		# 🧰 Create empty storage entry if this is a storage buildable
		if build_data.get("cat", "") == "storage":
			var time_data := LoadHandlerSingleton.get_time_and_date()
			var timestamp := {
				"date": time_data.get("gamedate", "Unknown"),
				"time": time_data.get("gametime", "Unknown")
			}

			var biome: String = placement.get("local_map", {}).get("biome_key", "")
			var z_key: String = z_level
			var storage_id: String = id  # same ID used above
			var register := LoadHandlerSingleton.load_storage_register(biome)

			if not register.has(z_key):
				register[z_key] = {}
			if not register[z_key].has(chunk_id):
				register[z_key][chunk_id] = {}
			if not register[z_key][chunk_id].has(biome_key):
				register[z_key][chunk_id][biome_key] = {}

			if not register[z_key][chunk_id][biome_key].has(storage_id):
				register[z_key][chunk_id][biome_key][storage_id] = {
					"position": [local_x, local_y],
					"inventory": {},
					"storage_type": build_data.get("object_name", "storage"),
					"rolled_once": true,
					"is_built": true,  # 🧱 Prevent loot roll on built storage
					"created_at": timestamp
				}
				LoadHandlerSingleton.save_storage_register(biome, register)


	# ✅ Refresh visuals
	refresh_chunk_after_build(chunk_id, biome_key, z_level)
	

func consume_materials_for_current_build() -> Dictionary:
	var build_reg: Dictionary = LoadHandlerSingleton.load_player_buildreg()
	var build_key: String = build_reg.get("current_build", "")
	if build_key == "":
		print("❌ No current build selected in build register.")
		return {}

	var build_data: Dictionary = BuildData.BUILD_PROPERTIES.get(build_key)
	if build_data == null:
		print("❌ Build data not found for:", build_key)
		return {}

	var requirements: Dictionary = build_data.get("requires", {})
	var inventory: Dictionary = LoadHandlerSingleton.load_player_inventory_dict()

	print("🛠️ Build requires:", requirements)
	print("🎒 Player inventory snapshot:")
	for item_id: String in inventory.keys():
		var item: Dictionary = inventory[item_id]
		print("  -", item_id, ":", item)

	var to_consume: Dictionary = {}
	var used_snapshot: Dictionary = {}  # 🧾 Store readable data for UI logging later

	for tag: String in requirements.keys():
		var needed_qty: int = int(requirements[tag])
		var remaining: int = needed_qty
		print("🔍 Searching for tag:", tag, " — Need:", needed_qty)

		for item_id: String in inventory.keys():
			var item: Dictionary = inventory[item_id]
			var crafting_tags: Array = item.get("crafting_tags", [])
			if tag in crafting_tags and remaining > 0:
				var qty: int = item.get("qty", 0)
				var used: int = min(qty, remaining)
				remaining -= used
				to_consume[item_id] = used if not to_consume.has(item_id) else to_consume[item_id] + used
				print("    ➕ Would consume", used, "from", item_id, "(has", qty, ")")

				# ✅ Stop once we've consumed enough for this tag
				if remaining <= 0:
					break

		if remaining > 0:
			print("❗ Not enough '%s'. Still missing: %d" % [tag, remaining])
		else:
			print("✅ All '%s' accounted for." % tag)

	print("📦 Final material plan:")
	for id: String in to_consume.keys():
		print("  -", id, "→", to_consume[id], "units")

	# ✅ Actually consume items
	for item_id: String in to_consume.keys():
		var used_qty: int = to_consume[item_id]
		if inventory.has(item_id):
			var item: Dictionary = inventory[item_id]

			# 🧾 Save snapshot for UI logging before modifying inventory
			used_snapshot[item_id] = {
				"display_name": item.get("display_name", item_id),
				"used_qty": used_qty
			}

			inventory[item_id]["qty"] -= used_qty
			if inventory[item_id]["qty"] <= 0:
				inventory.erase(item_id)

	# 💾 Save updated inventory
	LoadHandlerSingleton.save_player_inventory_dict(inventory)
	print("💾 Inventory updated after consumption.")

	return used_snapshot  # ✅ return readable snapshot instead of raw item IDs

	
func refresh_chunk_after_build(chunk_id: String, biome_key: String, z_level: String) -> void:
	var tile_container := get_tree().root.get_node_or_null("LocalMap/TileContainer")
	if tile_container == null:
		print("❌ TileContainer not found — cannot refresh visuals.")
		return

	var tile_path: String = LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_id, biome_key, z_level)
	var object_path: String = LoadHandlerSingleton.get_chunked_object_chunk_path(chunk_id, biome_key, z_level)
	var npc_path: String = LoadHandlerSingleton.get_chunked_npc_chunk_path(chunk_id, biome_key, z_level)

	var tile_data: Dictionary = LoadHandlerSingleton.load_json_file(tile_path)
	var object_data: Dictionary = LoadHandlerSingleton.load_json_file(object_path)
	var npc_data: Dictionary = LoadHandlerSingleton.load_json_file(npc_path)

	# ✅ Optional below layer
	var below_tile_data: Dictionary = {}
	if z_level != "z0":
		var below_z := int(z_level.trim_prefix("z")) - 1
		var below_path := LoadHandlerSingleton.get_chunked_tile_chunk_path(chunk_id, biome_key, "z%d" % below_z)
		if FileAccess.file_exists(below_path):
			below_tile_data = LoadHandlerSingleton.load_json_file(below_path)

	MapRenderer.render_map(tile_data, { "objects": object_data }, npc_data, tile_container, chunk_id, below_tile_data)
	
	# ✅ Refresh walkability + FOV
	if player:
		var grid_pos = Vector2i(player.position / TILE_SIZE)
		walkability_grid = LoadHandlerSingleton.build_walkability_grid(
			tile_data.get("tile_grid", {}), object_data
		)
		update_fov_from_player(grid_pos)

func _attempt_cursor_realignment():
	if cursor_realigned:
		return  # ✅ Only fix once per scene

	if is_instance_valid(targeting_cursor) and is_instance_valid(player):
		if targeting_cursor.position == Vector2.ZERO:
			var grid_pos = Vector2i(player.position / TILE_SIZE)
			target_cursor_grid_pos = grid_pos
			targeting_cursor.set_grid_position(grid_pos, TILE_SIZE)
			cursor_realigned = true
			print("🛠️ Failsafe realignment triggered at:", grid_pos)

func _exit_tree() -> void:
	if turn_manager and turn_manager.local_map_ref == self:
		turn_manager.local_map_ref = null
		print("🧹 LocalMap unregistered from TurnManager.")

func _draw():
	# Draw transparent rect over screen to clear previous NPC frame artifacts
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color(0, 0, 0, 0), false)

func _sync_fov_after_load() -> void:

	if player == null:
		print("⚠️ No player yet — skipping sync.")
		return

	var grid_pos := Vector2i(round(player.position.x / TILE_SIZE), round(player.position.y / TILE_SIZE))
	update_fov_from_player(grid_pos)

	if has_method("apply_fov_to_npc_layers"):
		apply_fov_to_npc_layers()

	print("🕶️ Post-Turn deferred FOV sync complete — xray NPCs cleaned up.")

func _precompute_fov_before_first_frame() -> void:
	if player == null:
		return

	# Compute FOV once before screen draws
	var grid_pos := Vector2i(round(player.position.x / TILE_SIZE), round(player.position.y / TILE_SIZE))
	update_fov_from_player(grid_pos)

	if has_method("apply_fov_to_npc_layers"):
		apply_fov_to_npc_layers()

	print("🕶️ FOV pre-pass complete before first frame.")

# Put near other helpers
func _set_npc_layers_visible(v: bool) -> void:
	if is_instance_valid(npc_container):
		npc_container.visible = v
	if is_instance_valid(npc_underlay_container):
		npc_underlay_container.visible = v

func apply_fov_to_npc_layers() -> void:
	if current_visible_tiles.is_empty():
		return
	# Current Z
	if is_instance_valid(npc_container):
		for c in npc_container.get_children():
			if c is Sprite2D:
				var g := Vector2i(int(c.position.x / TILE_SIZE), int(c.position.y / TILE_SIZE))
				c.modulate.a = 1.0 if current_visible_tiles.has(g) else 0.0
	# Underlay Z
	if is_instance_valid(npc_underlay_container):
		for c in npc_underlay_container.get_children():
			if c is Sprite2D:
				var g := Vector2i(int(c.position.x / TILE_SIZE), int(c.position.y / TILE_SIZE))
				# Slightly visible if both FOV and underlay; otherwise 0
				c.modulate.a = 0.18 if current_visible_tiles.has(g) else 0.0

func probe_egress_here(grid_pos: Vector2i) -> void:
	# 🔑 Identify current biome and chunk folder (not short key!)
	var placement: Dictionary = LoadHandlerSingleton.load_temp_localmap_placement()
	var biome_ref: String = str(placement.get("local_map", {}).get("biome_key", "grassland_explore_fields"))

	var biome_folder: String = ""
	if biome_ref.contains("_"):  # already a folder
		biome_folder = biome_ref
	elif biome_ref.length() <= 3:  # short key
		biome_folder = Constants.get_biome_folder_from_key(biome_ref)
	else:  # plain biome name
		biome_folder = biome_ref

	var chunk_id: String = get_current_chunk_id()
	var z: String = str(LoadHandlerSingleton.get_current_z_level())
	var key: String = "%s|z%s" % [chunk_id, z]

	# 🧾 Load egress register for this biome folder
	var egress_data: Dictionary = LoadHandlerSingleton.load_egress_register(biome_folder)
	if not egress_data.has(key):
		return

	var egress_list: Array = egress_data[key]

	# 🔍 Check if we are standing on any egress tile
	for entry in egress_list:
		if typeof(entry) != TYPE_DICTIONARY or not entry.has("position"):
			continue

		var pos_dict: Dictionary = entry["position"]
		var egress_pos := Vector2i(int(pos_dict.get("x", -999)), int(pos_dict.get("y", -999)))

		if egress_pos == grid_pos:
			# Grab egress target data
			var target_z := int(entry.get("target_z", z))
			var egress_type: String = str(entry.get("type", "unknown"))

			print("🌀 Egress detected at:", grid_pos, "| type:", egress_type, "| target Z:", target_z)

			# ✅ Update placement JSON so temp data reflects the new Z-level
			var placement_data := LoadHandlerSingleton.load_temp_localmap_placement()
			if placement_data.has("local_map"):
				placement_data["local_map"]["z_level"] = str(target_z)
				placement_data["local_map"]["grid_position_local"] = {
					"x": grid_pos.x,
					"y": grid_pos.y
				}
			LoadHandlerSingleton.save_temp_placement(placement_data)

			# ✅ Update live in-memory state if available
			if LoadHandlerSingleton.has_method("set_current_local_grid_pos"):
				LoadHandlerSingleton.set_current_local_grid_pos(grid_pos)
			if LoadHandlerSingleton.has_method("set_current_z_level"):
				LoadHandlerSingleton.set_current_z_level(target_z)

			# ✅ Only spawn popup for actual exits, not internal stairs/trapdoors
			if has_method("spawn_area_exit_popup") and not egress_type.contains("stairs") and not egress_type.contains("trapdoor"):
				spawn_area_exit_popup()

			# ✅ Reload LocalMap for the new z-level (deferred for safety)
			if has_method("_reload_z_level"):
				call_deferred("_reload_z_level", target_z, grid_pos)

			last_egress_pos = grid_pos
			return

	# ❌ No egress underfoot — close stale popup if it exists
	if active_area_exit_popup:
		active_area_exit_popup.queue_free()
		active_area_exit_popup = null

func _reload_z_level(new_z: int, entry_pos: Vector2i) -> void:
	print("🔄 Reloading LocalMap for new Z-level:", new_z)
	var old_z := int(current_z_level)  # previous level before reload
	
	# Normalize & set live state
	var z_int := LoadHandlerSingleton.z_to_int(new_z)
	LoadHandlerSingleton.set_current_z_level(z_int)
	LoadHandlerSingleton.set_current_local_grid_pos(entry_pos)

	# Persist temp placement (single source of truth)
	var placement_data: Dictionary = LoadHandlerSingleton.load_temp_localmap_placement()
	if not placement_data.has("local_map"):
		placement_data["local_map"] = {}
	placement_data["local_map"]["z_level"] = z_int
	placement_data["local_map"]["grid_position_local"] = {"x": entry_pos.x, "y": entry_pos.y}
	LoadHandlerSingleton.save_temp_placement(placement_data) # ✅ use save_temp_placement

	# Resolve the actual containers under WorldView (null-safe)
	var tile_container  : Node2D = get_node_or_null("WorldView/TileContainer")
	var npc_container   : Node2D = get_node_or_null("WorldView/NPCContainer")
	var npc_underlay    : Node2D = get_node_or_null("WorldView/NPCUnderlayContainer")

	# Clear existing children safely (skip TargetingCursor)
	for c in [tile_container, npc_container, npc_underlay]:
		if c:
			for child in c.get_children():
				if c == tile_container and child.name == "TargetingCursor":
					continue
				child.queue_free()

	# Let frees complete before rebuild
	await get_tree().process_frame

	# Rebuild the new Z level (uses your existing init path)
	if has_method("load_z_level"):
		load_z_level(z_int)
	else:
		load_and_render_local_map()
	
	if world_view:
		var zf: float = zoom_factor if zoom_factor != 0 else 1.0
		world_view.position = Vector2.ZERO
		world_view.scale = Vector2.ONE * zf
	
	# Move player to correct tile and center camera smoothly after map loads
	if player:
		player.position = Vector2(entry_pos.x * TILE_SIZE, entry_pos.y * TILE_SIZE)
		call_deferred("center_on_player_after_load", 0.2)
		
	# ♻️ Force LOS/FOV to recompute for this Z (same XY stairs case)
	_last_fov_grid = Vector2i(-999, -999)   # invalidate the cache
	current_visible_tiles.clear()
	visible_tiles.clear()
	_los_cache.clear()
	if light_overlay and "dirty_tiles" in light_overlay:
		light_overlay.dirty_tiles.clear()

	# Ensure the map has finished building before FOV
	await get_tree().process_frame

	# Recompute FOV + lighting immediately
	if has_method("update_fov_from_player"):
		update_fov_from_player(entry_pos)
	if has_method("apply_fov_to_npc_layers"):
		apply_fov_to_npc_layers()
	if has_method("update_light_map"):
		call_deferred("update_light_map")

	# Optional: pull light from lower z after FOV
	if has_method("propagate_light_from_lower_z"):
		propagate_light_from_lower_z()

	print("✅ LocalMap reloaded cleanly for Z =", z_int)
	
	# 🪜 Travel log feedback for Z-level change (deferred to ensure UI is ready)

	await get_tree().process_frame
	await get_tree().process_frame

	if travel_log and travel_log.has_method("add_message_to_log"):
		if z_int > old_z:
			travel_log.add_message_to_log("You ascend to an upper level.")
		else:
			travel_log.add_message_to_log("You descend to a lower level.")
	else:
		print("⚠️ Travel log not ready when trying to post Z-level message.")

func force_update_fov_at(grid_pos: Vector2i) -> void:
	# Invalidate caches & throttle so the next call recomputes immediately
	_last_fov_grid = Vector2i(-999, -999)
	_last_fov_update_time = 0.0

	# If you want to guarantee a redraw delta, also mark current tiles dirty:
	for pos in current_visible_tiles.keys():
		if light_overlay and "dirty_tiles" in light_overlay:
			light_overlay.dirty_tiles[pos] = true

	# Now run the normal path
	update_fov_from_player(grid_pos)

	# Ensure lighting texture updates after visibility change
	if has_method("update_light_map"):
		call_deferred("update_light_map")

func center_on_player_after_load(delay := 0.2) -> void:
	if player == null or world_view == null:
		return
	await get_tree().create_timer(delay).timeout

	var vp: Vector2 = get_viewport_rect().size
	var target_pos: Vector2 = (vp * 0.5) - (player.position * zoom_factor)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(world_view, "position", target_pos, 0.25)
