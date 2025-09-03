extends Node

# ✅ Make this a Singleton
const TILE_SIZE = 88  # Adjust based on your actual tile size

const AnimatedTileSprite = preload("res://scenes/animate-scenes/AnimatedTileSprite.tscn")

# ✅ Preload common textures once to optimize rendering
const TEXTURES = Constants.TILE_TEXTURES
const MAP_SIZE = 50


func _ready():
	# ✅ Ensure this is globally available as a Singleton
	if get_tree().root.has_node("MapRenderer"):
		print("⚠️ WARNING: MapRenderer already exists. Skipping add_child().")
		return  # Avoid adding itself again!

	get_tree().root.add_child(self)  # ✅ Only add if not already in the scene
	set_process(false)  # ✅ No need to run `_process()`
	
func render_map(tile_data: Dictionary, object_data: Dictionary, npc_data: Dictionary, tile_container: Node, chunk_id: String) -> void:
	if tile_container == null:
		print("❌ ERROR: tile_container is null!")
		return

	print("📐 TileContainer Pos:", tile_container.position)
	print("👁 TileContainer Visible:", tile_container.visible)
	print("👶 TileContainer Children Before Render:", tile_container.get_child_count())

	# 🧹 Clear old stuff
	for child in tile_container.get_children():
		if child.name.begins_with("tile_") or child.name.begins_with("obj_") or child.name.begins_with("npc_"):
			child.queue_free()

	print("🖼 Rendering map from normalized chunk data...")

	# 🔍 Tile sanity
	if tile_data == null or not tile_data.has("tile_grid"):
		print("❌ ERROR: tile_data missing 'tile_grid' key or is null!", tile_data)
		return

	var tile_grid = tile_data["tile_grid"]
	if typeof(tile_grid) != TYPE_DICTIONARY:
		print("❌ ERROR: tile_grid is not a dictionary! Actual type:", typeof(tile_grid))
		return

	print("🔢 tile_grid contains", tile_grid.size(), "entries.")
	var tile_count := 0

	for key in tile_grid.keys():
		if tile_count < 5:
			print("🔍 Tile Key:", key, "→ Data:", tile_grid[key])
		var coords = key.split("_")
		if coords.size() != 2:
			print("⚠️ Skipping malformed tile key:", key)
			continue

		var local_x = int(coords[0])
		var local_y = int(coords[1])

		var tile_info = tile_grid[key]
		if typeof(tile_info) != TYPE_DICTIONARY or not tile_info.has("tile"):
			print("⚠️ Skipping bad tile_info at", key)
			continue

		var tile_name = tile_info["tile"]
		var base_texture = TEXTURES.get(tile_name, null)
		if base_texture == null:
			print("⚠️ Missing texture for tile:", tile_name)
			continue

		var tile_sprite := get_tile_sprite(tile_name, base_texture)
		tile_sprite.position = Vector2(local_x * TILE_SIZE, local_y * TILE_SIZE)
		tile_sprite.name = "tile_%d_%d" % [local_x, local_y]
		tile_sprite.z_index = -10
		tile_container.add_child(tile_sprite)
		
		tile_count += 1

	print("✅ Tiles rendered:", tile_count)

	# 🔍 Validate and render objects
	if object_data == null or not object_data.has("objects"):
		print("⚠️ WARNING: object_data is invalid or missing 'objects'!", object_data)
		return

	var objects = object_data["objects"]
	if typeof(objects) != TYPE_DICTIONARY:
		print("❌ ERROR: 'objects' is not a dictionary!", objects)
		return

	var object_count := 0
	for obj_id in objects:
		var obj = objects[obj_id]
		if not obj.has("position") or typeof(obj["position"]) != TYPE_DICTIONARY:
			print("🚫 Object position malformed:", obj_id, "→", obj.get("position"))
			continue

		print("🧪 RAW position:", obj.get("position"))
		var pos = obj["position"]
		var local_x = int(pos["x"])
		var local_y = int(pos["y"])

		var obj_type = obj.get("type", "")
		var obj_state = obj.get("state", {})

		var obj_texture: Texture2D = null

		# 🎯 Mounts use inline texture paths
		if obj_type == "mount" and obj.has("texture"):
			obj_texture = load(obj["texture"])
		elif obj_type == "candelabra" and obj_state.get("is_lit", false):
			obj_texture = TEXTURES.get("candelabra_lit", null)
		elif obj_type == "slum_streetlamp":
			obj_texture = TEXTURES.get("slum_streetlamp" if obj_state.get("is_lit", false) else "slum_streetlamp_broken")
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
			object_count += 1
		else:
			print("⚠️ Missing texture for object:", obj_type)
			print("🧪 Texture for", obj_type, "→", obj_texture)

		# 🧍 Render NPCs
	if npc_data == null or not npc_data.has("npcs"):
		print("⚠️ WARNING: npc_data is invalid or missing 'npcs'!", npc_data)
		return

	var npcs = npc_data["npcs"]
	if typeof(npcs) != TYPE_DICTIONARY:
		print("❌ ERROR: 'npcs' is not a dictionary!", npcs)
		return

	var npc_count := 0
	for npc_id in npcs:
		var npc = npcs[npc_id]
		if not npc.has("position") or typeof(npc["position"]) != TYPE_DICTIONARY:
			print("🚫 NPC position malformed:", npc_id, "→", npc.get("position"))
			continue

		var pos = npc["position"]
		var local_x = int(pos["x"])
		var local_y = int(pos["y"])

		# 🧠 Basic fallback: use TEXTURES or a scene path
		var npc_type = npc.get("type", "generic_npc")
		var npc_texture: Texture2D = TEXTURES.get(npc_type, null)

		if npc_texture != null:
			var npc_node_name = "npc_%d_%d" % [local_x, local_y]
			var old_npc = tile_container.get_node_or_null(npc_node_name)
			if old_npc:
				old_npc.queue_free()

			var npc_sprite := Sprite2D.new()
			npc_sprite.name = npc_node_name
			npc_sprite.texture = npc_texture
			npc_sprite.position = Vector2(local_x * TILE_SIZE, local_y * TILE_SIZE)
			npc_sprite.z_index = 1  # Render above objects and tiles
			npc_sprite.add_to_group("npc_sprites")
			tile_container.add_child(npc_sprite)
			npc_count += 1
		else:
			print("⚠️ Missing texture for NPC:", npc_type)

	print("✅ NPCs rendered:", npc_count)


	print("👶 TileContainer Children After Render:", tile_container.get_child_count())
	print("✅ Map rendering complete.")


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
		print("⚠️ WARNING: Missing texture for tile:", tile_name)
		return null

func render_single_tile(pos: Vector2i, tile_data: Dictionary, tile_container: Node) -> void:
	if tile_container == null:
		print("❌ ERROR: tile_container is null in render_single_tile!")
		return

	var tile_name: String = tile_data.get("tile", "unknown")
	var texture: Texture2D = TEXTURES.get(tile_name, null)

	if texture == null:
		print("⚠️ No texture found for tile:", tile_name)
		return

	var key = "tile_%d_%d" % [pos.x, pos.y]
	var sprite_node = tile_container.get_node_or_null(key)

	if sprite_node == null:
		print("⚠️ No existing sprite node at:", key)
		return

	if sprite_node is Sprite2D:
		sprite_node.texture = texture
		print("🎨 Updated tile at", pos, "→", tile_name)
	else:
		print("⚠️ Node at", key, "is not a Sprite2D!")
		
func render_chunk_transitions(current_chunk_coords: Vector2i, tile_container: Node2D):
	print("🧭 Rendering chunk transition indicators for:", current_chunk_coords)

	var directions := {
		"north": Vector2i(0, -1),
		"east": Vector2i(1, 0),
		"south": Vector2i(0, 1),
		"west": Vector2i(-1, 0),
	}

	# ✅ Dynamically get chunk size from blueprint
	var blueprint_map: Dictionary = LoadHandlerSingleton.get_chunk_blueprints()
	var chunk_key := "chunk_%d_%d" % [current_chunk_coords.x, current_chunk_coords.y]
	var chunk_size := Vector2i(50, 50)  # fallback

	if blueprint_map.has(chunk_key):
		var bp: Dictionary = blueprint_map[chunk_key]
		chunk_size = Vector2i(bp["size"][0], bp["size"][1])
	else:
		print("⚠️ No blueprint found for chunk:", chunk_key)

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
		var is_valid = LoadHandlerSingleton.is_chunk_valid(neighbor_coords)
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

		print("↪️ Drew %s indicators | Neighbor: %s | Valid: %s" % [dir, str(neighbor_coords), str(is_valid)])
