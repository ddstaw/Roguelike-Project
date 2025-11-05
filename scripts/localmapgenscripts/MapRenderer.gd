extends Node
#res://scripts/localmapgenscripts/MapRenderer.gd
# this is a Singleton
const TILE_SIZE = 88  # Adjust based on your actual tile size

const AnimatedTileSprite = preload("res://scenes/animate-scenes/AnimatedTileSprite.tscn")

# ✅ Preload common textures once to optimize rendering
const TEXTURES = Constants.TILE_TEXTURES
const MAP_SIZE = 50


func _ready():
	# ✅ Ensure this is globally available as a Singleton
	if get_tree().root.has_node("MapRenderer"):
		return  # Avoid adding itself again!

	get_tree().root.add_child(self)  # ✅ Only add if not already in the scene
	set_process(false)  # ✅ No need to run `_process()`
	
func render_map(
	tile_data: Dictionary,
	object_data: Dictionary,
	npc_data: Dictionary,
	tile_container: Node,
	chunk_id: String,
	below_tile_chunk: Dictionary = {},
	below_object_chunk: Dictionary = {},
	below_npc_chunk: Dictionary = {}
) -> void:
	var local_map = tile_container.get_parent()
	var npc_container = local_map.get_node_or_null("NPCContainer")
	var npc_underlay = local_map.get_node_or_null("NPCUnderlayContainer")
	
	
	if tile_container == null:
		print("❌ ERROR: tile_container is null!")
		return

	# 🧹 Clear old tiles and objects (keep NPCs handled separately)
	for child in tile_container.get_children():
		if child.name.begins_with("tile_") or child.name.begins_with("obj_"):
			child.queue_free()

	# 🔍 Tile sanity check
	if tile_data == null or not tile_data.has("tile_grid"):
		return
	var tile_grid = tile_data["tile_grid"]
	if typeof(tile_grid) != TYPE_DICTIONARY:
		return

	var tile_count := 0

	# ───────────────────────────────────────────────
	# MAIN TILE RENDER LOOP
	# ───────────────────────────────────────────────
	for key in tile_grid.keys():
		var coords = key.split("_")
		if coords.size() != 2:
			continue
		var local_x = int(coords[0])
		var local_y = int(coords[1])
		var tile_info = tile_grid[key]
		if typeof(tile_info) != TYPE_DICTIONARY or not tile_info.has("tile"):
			continue

		var tile_name = tile_info["tile"]
		var base_texture = TEXTURES.get(tile_name, null)
		if base_texture == null:
			continue

		var tile_sprite := get_tile_sprite(tile_name, base_texture)
		tile_sprite.position = Vector2(local_x * TILE_SIZE, local_y * TILE_SIZE)
		tile_sprite.name = "tile_%d_%d" % [local_x, local_y]
		tile_sprite.z_index = -10
		tile_container.add_child(tile_sprite)
		tile_count += 1

		# ───────────────────────────────────────────────
		# UNDERLAY RENDERING FOR OPEN AIR
		# ───────────────────────────────────────────────
		if tile_name == "openair" and below_tile_chunk.has("tile_grid"):
			var below_key = "%d_%d" % [local_x, local_y]
			var below_tile_grid = below_tile_chunk["tile_grid"]
			if below_tile_grid.has(below_key):
				var below_info = below_tile_grid[below_key]
				if typeof(below_info) == TYPE_DICTIONARY and below_info.has("tile"):
					var below_tile_name = below_info["tile"]
					var below_tex = TEXTURES.get(below_tile_name, null)
					if below_tex != null:
						var faint_sprite := Sprite2D.new()
						faint_sprite.texture = below_tex
						faint_sprite.position = tile_sprite.position
						faint_sprite.modulate = Color(0.5, 0.5, 0.5, 0.12)  # gray desaturation, faint  # cool blue tint + much fainter
						faint_sprite.z_index = -150  # push it deep under current-level visuals
						tile_container.add_child(faint_sprite)

# 🧩 Render below-layer OBJECTS faintly (supports wrapped or unwrapped formats)
			var below_objects: Dictionary = {}
			if below_object_chunk.has("objects"):
				below_objects = below_object_chunk["objects"]
			else:
				below_objects = below_object_chunk  # unwrapped format fallback

			if below_objects.size() > 0:
				for obj_id in below_objects.keys():
					var obj: Dictionary = below_objects[obj_id]
					if not obj.has("position"):
						continue
					var pos: Dictionary = obj["position"]
					if int(pos.get("x", -1)) == local_x and int(pos.get("y", -1)) == local_y:
						var obj_type: String = obj.get("type", "")
						var obj_state: Dictionary = obj.get("state", {})

						# 🔥 choose lit/unlit texture
						var obj_tex: Texture2D = null
						if obj_type == "candelabra" and obj_state.get("is_lit", false):
							obj_tex = TEXTURES.get("candelabra_lit", null)
						elif obj_type == "torch" and obj_state.get("is_lit", false):
							obj_tex = TEXTURES.get("torch_lit", null)
						elif obj_type == "brazier" and obj_state.get("is_lit", false):
							obj_tex = TEXTURES.get("brazier_lit", null)
						else:
							obj_tex = TEXTURES.get(obj_type, null)

						if obj_tex != null:
							var faint_obj := Sprite2D.new()
							faint_obj.texture = obj_tex
							faint_obj.position = tile_sprite.position
							faint_obj.z_index = -120  # under current-level visuals

							# faint for unlit, soft warm tint if lit
							if obj_state.get("is_lit", false):
								faint_obj.modulate = Color(0.8, 0.8, 0.5, 0.25)
							else:
								faint_obj.modulate = Color(0.5, 0.5, 0.5, 0.12)

							tile_container.add_child(faint_obj)

			# 🧩 Render below-layer NPCs faintly
			if below_npc_chunk.has("npcs"):
				for npc_id in below_npc_chunk["npcs"]:
					var npc = below_npc_chunk["npcs"][npc_id]
					if not npc.has("position"):
						continue
					var npos = npc["position"]
					if int(npos.get("x", -1)) == local_x and int(npos.get("y", -1)) == local_y:
						var npc_type = npc.get("type", "")
						var keyname = Constants.NPC_TYPE_TO_TEXTURE_KEY.get(npc_type, "")
						var npc_tex = TEXTURES.get(keyname, null)
						if npc_tex != null:
							var faint_npc := Sprite2D.new()
							faint_npc.texture = npc_tex
							faint_npc.position = tile_sprite.position
							faint_npc.modulate = Color(0.6, 0.7, 0.9, 0.15)  # gray desaturation, faint  # cool blue tint + much fainter
							faint_npc.z_index = -120  # push it deep under current-level visuals
							if npc_underlay:
								npc_underlay.add_child(faint_npc)
							else:
								tile_container.add_child(faint_npc)  # fallback safety
	# ───────────────────────────────────────────────
	# OBJECTS (main layer)
	# ───────────────────────────────────────────────
	if object_data == null or not object_data.has("objects"):
		return
	var objects = object_data["objects"]
	if typeof(objects) != TYPE_DICTIONARY:
		return
	for obj_id in objects:
		var obj = objects[obj_id]
		if not obj.has("position"):
			continue
		var pos = obj["position"]
		var local_x = int(pos.get("x", 0))
		var local_y = int(pos.get("y", 0))
		var obj_type = obj.get("type", "")
		var obj_state = obj.get("state", {})
		var obj_texture: Texture2D = null

		if obj_type == "mount" and obj.has("texture"):
			obj_texture = load(obj["texture"])
		elif obj_type == "candelabra" and obj_state.get("is_lit", false):
			obj_texture = TEXTURES.get("candelabra_lit", null)
		elif obj_type == "slum_streetlamp":
			obj_texture = TEXTURES.get(
				"slum_streetlamp" if obj_state.get("is_lit", false) else "slum_streetlamp_broken"
			)
		else:
			obj_texture = TEXTURES.get(obj_type, null)

		if obj_texture != null:
			var obj_node_name = "obj_%d_%d" % [local_x, local_y]
			var old_obj = tile_container.get_node_or_null(obj_node_name)
			if old_obj:
				old_obj.queue_free()
			var obj_sprite := Sprite2D.new()
			obj_sprite.name = obj_node_name
			obj_sprite.texture = obj_texture
			obj_sprite.position = Vector2(local_x * TILE_SIZE, local_y * TILE_SIZE)
			obj_sprite.z_index = 0
			obj_sprite.add_to_group("object_sprites")
			tile_container.add_child(obj_sprite)

	# ───────────────────────────────────────────────
	# NPCS (main layer)
	# ───────────────────────────────────────────────
	if npc_data == null or not npc_data.has("npcs"):
		return
	var npcs = npc_data["npcs"]
	if typeof(npcs) != TYPE_DICTIONARY:
		return
	for npc_id in npcs:
		var npc = npcs[npc_id]
		if not npc.has("position"):
			continue
		var pos = npc["position"]
		var local_x = int(pos.get("x", 0))
		var local_y = int(pos.get("y", 0))
		var npc_type = npc.get("type", "generic_npc")
		var texture_key = Constants.NPC_TYPE_TO_TEXTURE_KEY.get(npc_type, null)
		if texture_key == null:
			continue
		var npc_texture: Texture2D = TEXTURES.get(texture_key, null)
		if npc_texture == null:
			continue
		var npc_node_name = "npc_%d_%d" % [local_x, local_y]
		var old_npc = tile_container.get_node_or_null(npc_node_name)
		if old_npc:
			old_npc.queue_free()
		var npc_sprite := Sprite2D.new()
		npc_sprite.name = npc_node_name
		npc_sprite.texture = npc_texture
		npc_sprite.position = Vector2(local_x * TILE_SIZE, local_y * TILE_SIZE)
		npc_sprite.z_index = 1
		npc_sprite.add_to_group("npc_sprites")
		
		if npc_container:
			npc_container.add_child(npc_sprite)
		else:
			tile_container.add_child(npc_sprite)  # fallback safety



func get_tile_sprite(tile_name: String, base_texture: Texture2D) -> Node2D:
	# 🌀 Check if this tile should be animated
	if Constants.ANIMATED_TILE_DEFINITIONS.has(tile_name):
		var anim_config: Dictionary = Constants.get_animated_tile_config(tile_name)
		var instance := AnimatedTileSprite.instantiate()

		if instance is AnimatedTileSprite:
			var animated_tile: AnimatedTileSprite = instance as AnimatedTileSprite
			var frame_paths: Array = anim_config.get("frames", [])
			var textures: Array[Texture2D] = []

			if frame_paths.size() > 0:
				for path in frame_paths:
					var tex = load(path)
					if tex is Texture2D:
						textures.append(tex)
					else:
						print("⚠️ Failed to load texture at:", path)

				animated_tile.frames = textures
				animated_tile.frame_time = anim_config.get("frame_time", 0.25)

			animated_tile.visible = true
			animated_tile.scale = Vector2.ONE
			animated_tile.z_index = 0
			return animated_tile
		else:
			print("⚠️ Failed to instantiate AnimatedTileSprite for:", tile_name)

	# 🖼 Fallback to static sprite
	var sprite := Sprite2D.new()
	sprite.texture = base_texture
	sprite.visible = true
	sprite.scale = Vector2.ONE
	sprite.z_index = 0
	return sprite


# ✅ Helper function to get preloaded textures efficiently
func _get_texture(tile_name: String):
	if TEXTURES.has(tile_name):
		return TEXTURES[tile_name]
	else:
		#print("⚠️ WARNING: Missing texture for tile:", tile_name)
		return null

func render_single_tile(pos: Vector2i, tile_data: Dictionary, tile_container: Node) -> void:
	if tile_container == null:
		#print("❌ ERROR: tile_container is null in render_single_tile!")
		return

	var tile_name: String = tile_data.get("tile", "unknown")
	var texture: Texture2D = TEXTURES.get(tile_name, null)

	if texture == null:
		#print("⚠️ No texture found for tile:", tile_name)
		return

	var key = "tile_%d_%d" % [pos.x, pos.y]
	var sprite_node = tile_container.get_node_or_null(key)

	if sprite_node == null:
		#print("⚠️ No existing sprite node at:", key)
		return

	if sprite_node is Sprite2D:
		sprite_node.texture = texture
		#print("🎨 Updated tile at", pos, "→", tile_name)
	else:
		print("⚠️ Node at", key, "is not a Sprite2D!")
		
func render_chunk_transitions(current_chunk_coords: Vector2i, tile_container: Node2D):
	
	#print("🧭 Rendering chunk transition indicators for:", current_chunk_coords)
	tile_container.set_global_position(Vector2.ZERO)
	tile_container.set_position(Vector2.ZERO)
	tile_container.scale = Vector2.ONE
	
	
	var directions := {
		"north": Vector2i(0, -1),
		"east": Vector2i(1, 0),
		"south": Vector2i(0, 1),
		"west": Vector2i(-1, 0),
	}

	# ✅ Dynamically get chunk size from blueprint
	var blueprint_map: Dictionary = LoadHandlerSingleton.get_chunk_blueprints()
	var chunk_key := "chunk_%d_%d" % [current_chunk_coords.x, current_chunk_coords.y]
	var chunk_size: Vector2i

	if blueprint_map.has(chunk_key):
		var bp: Dictionary = blueprint_map[chunk_key]
		chunk_size = Vector2i(bp["size"][0], bp["size"][1])
	else:
		# ✅ fallback to biome config when no blueprint exists
		var placement: Dictionary = LoadHandlerSingleton.load_temp_localmap_placement()
		var biome_folder: String = placement.get("local_map", {}).get("biome_key", "grassland_explore_fields")
		var biome_key: String = Constants.get_biome_chunk_key(biome_folder)
		var biome_config: Dictionary = Constants.get_biome_config(biome_key)
		chunk_size = biome_config.get("chunk_size", Vector2i(40, 40))
		print("🌎 Fallback: Using biome config:", biome_key, "| Chunk size:", chunk_size)
		
	var texture_map = Constants.TRANSITION_TEXTURES
	var TILE_SIZE = 88
	var arrow_repeat_interval = 5  # Every 5 tiles for valid transitions

	# 🧹 Clear old transition sprites
	for child in tile_container.get_children():
		if child.name.begins_with("transition_"):
			child.queue_free()

	# 🧭 Render indicators based on actual chunk size
	for dir in directions.keys():
		var offset = directions[dir]
		var neighbor_coords = current_chunk_coords + offset
		var is_valid = false
		
		if LoadHandlerSingleton.has_method("is_chunk_valid"):
			is_valid = LoadHandlerSingleton.is_chunk_valid(neighbor_coords)

		# ✅ Explicit guard for missing east/south neighbors
		if not is_valid:
			var neighbor_key = "chunk_%d_%d" % [neighbor_coords.x, neighbor_coords.y]
			if not blueprint_map.has(neighbor_key):
				is_valid = false  # force fade when no blueprint neighbor exists
				
		var texture = texture_map[dir] if is_valid else texture_map["exit"]

		var repeat_count = chunk_size.x if dir in ["north", "south"] else chunk_size.y
		var step = arrow_repeat_interval if is_valid else 1

		for i in range(0, repeat_count, step):
			var edge_tile_pos: Vector2i
			match dir:
				"north":
					edge_tile_pos = Vector2i(i, 0)
				"south":
					edge_tile_pos = Vector2i(i, chunk_size.y - 1)
				"west":
					edge_tile_pos = Vector2i(0, i)
				"east":
					edge_tile_pos = Vector2i(chunk_size.x - 1, i)

			var sprite := Sprite2D.new()
			sprite.texture = texture
			sprite.name = "transition_%s_%d" % [dir, i]
			sprite.z_index = 99

			var pixel_offset = Vector2(offset.x, offset.y) * (TILE_SIZE * 0.95)
			sprite.position = Vector2(edge_tile_pos) * TILE_SIZE + pixel_offset

			tile_container.add_child(sprite)
		
		#print("↪️ Drew %s indicators | Neighbor: %s | Valid: %s" % [dir, str(neighbor_coords), str(is_valid)])

func redraw_npcs(
	npc_data: Dictionary,
	target_container: Node2D,
	chunk_id: String,
	is_lower_z: bool = false
) -> void:
	if target_container == null:
		return

	# 🧩 Defensive guards against null or malformed data
	if npc_data == null:
		print("⚠️ redraw_npcs: npc_data is null for", chunk_id)
		return
	if not npc_data.has("npcs"):
		print("⚠️ redraw_npcs: missing 'npcs' key for", chunk_id)
		return
	if npc_data["npcs"].is_empty():
		print("⚠️ redraw_npcs: empty npc_data for", chunk_id, "→ keeping existing sprites (no despawn).")
		return
	
	# 🧹 SAFETY SCRUB — remove any orphaned Sprite2Ds without metadata
	for ghost in target_container.get_children():
		if ghost is Sprite2D and (not ghost.has_meta("npc_id") or ghost.get_meta("npc_id") == null):
			print("👻 Removing anonymous ghost sprite from", target_container.name)
			ghost.queue_free()

	
	var npcs: Dictionary = npc_data["npcs"]
	var desired_ids: Dictionary = {}

	for npc_id in npcs.keys():
		desired_ids[npc_id] = true

	# ✅ Gather existing sprites
	var existing: Dictionary = {}
	for c in target_container.get_children():
		if c is Sprite2D and c.has_meta("npc_id"):
			var id = c.get_meta("npc_id")
			existing[id] = c

	# ✅ Add or update NPCs
	for npc_id in npcs.keys():
		var nd: Dictionary = npcs[npc_id]
		if not nd.has("position"):
			continue

		var pos: Dictionary = nd["position"]
		var x := int(pos.get("x", 0))
		var y := int(pos.get("y", 0))
		var npc_type: String = nd.get("type", "")

		var tex_key: String = Constants.NPC_TYPE_TO_TEXTURE_KEY.get(npc_type, "")
		var tex: Texture2D = Constants.TILE_TEXTURES.get(tex_key, null)
		if tex == null:
			print("⚠️ Missing texture for NPC type:", npc_type)
			continue

		var spr: Sprite2D = existing.get(npc_id)
		if spr == null:
			spr = Sprite2D.new()
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
			spr.set_meta("npc_id", npc_id)
			target_container.add_child(spr)
			spr.modulate.a = 0.0
			print("➕ Created sprite for", npc_id)
		else:
			print("🔁 Reusing sprite for", npc_id)

		spr.texture = tex
		spr.name = "npc_%s" % npc_id

		# 🧱 Visual layering
		if is_lower_z:
			spr.z_index = -5  # Slightly behind normal NPCs but above tiles
			spr.modulate = Color(0.8, 0.8, 0.8, 0.55)
		else:
			spr.z_index = 1
			spr.modulate = Color(1, 1, 1, 1)

		spr.z_as_relative = false

		var new_pos := Vector2(x * 88, y * 88)
		if spr.position != new_pos:
			spr.position = new_pos
			print("🎯 Updated pos:", npc_id, "→", new_pos)

	# ✅ Remove any stale sprites
	for c in target_container.get_children():
		if c is Sprite2D and c.has_meta("npc_id"):
			var id = c.get_meta("npc_id")
			if not desired_ids.has(id):
				print("🗑️ Removing stale sprite:", id)
				c.queue_free()

	# 🧠 Debug summary
	print("✅ redraw_npcs complete for", chunk_id, "→ active NPCs:", desired_ids.keys())

func redraw_tile_and_object_at(grid_pos: Vector2i, tile_data: Dictionary, object_data: Dictionary, tile_container: Node) -> void:
	print("🔄 Redraw at", grid_pos)

	# Tile side
	var key = "tile_%d_%d" % [grid_pos.x, grid_pos.y]
	var tile_info = tile_data.get("tile_grid", {}).get(key, null)
	if tile_info == null:
		print("❌ No tile_info at", key)
	else:
		print("✅ Found tile_info:", tile_info)

	var texture: Texture2D = null
	if tile_info != null:
		var tile_name = tile_info.get("tile", "")
		texture = TEXTURES.get(tile_name, null)

	if texture == null:
		print("❌ No texture for tile:", tile_info.get("tile", "") if tile_info != null else "none")
	else:
		var existing_tile = tile_container.get_node_or_null(key)
		if existing_tile:
			print("🔍 Found existing tile node:", existing_tile.name)
			if existing_tile is Sprite2D:
				existing_tile.texture = texture
				existing_tile.position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
				print("🎨 Updated tile sprite at", grid_pos)
			else:
				print("❌ existing_tile is not a Sprite2D!")
		else:
			print("➕ No existing tile — creating new tile sprite")
			var new_tile = Sprite2D.new()
			new_tile.name = key
			new_tile.texture = texture
			new_tile.position = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
			new_tile.z_index = -10
			tile_container.add_child(new_tile)
			print("🎨 Created new tile sprite at", grid_pos)

	# Object side
	if object_data.has("objects"):
		for id in object_data["objects"].keys():
			var obj = object_data["objects"][id]
			var pos = obj.get("position", {})
			if pos.get("x", -1) == grid_pos.x and pos.get("y", -1) == grid_pos.y:
				print("🔧 Found object at tile:", grid_pos, obj)
				MapRenderer.render_single_object(grid_pos, obj, tile_container)
				break
