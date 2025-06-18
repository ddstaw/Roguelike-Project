extends Node
# Optional autoload

var chunk_blueprints := {} # Populated at runtime with chunk ID → blueprint dictionary

func get_chunk_for_global_tile(global_tile: Vector2i) -> Dictionary:
	for chunk_id in chunk_blueprints:
		var blueprint = chunk_blueprints[chunk_id]
		var origin = blueprint.origin
		var size = blueprint.size
		var bounds = Rect2i(origin, size)

		if bounds.has_point(global_tile):
			print("✅ Found chunk for global tile", global_tile, "→", chunk_id)
			return {
				"id": chunk_id,
				"local": global_tile - origin,
				"blueprint": blueprint
			}

	print("❌ No chunk found for global tile:", global_tile)
	return {}  # fallback

func get_local_tile_in_chunk(global_tile: Vector2i, chunk_id: String) -> Vector2i:
	var blueprint = chunk_blueprints.get(chunk_id)
	if blueprint:
		return global_tile - blueprint.origin
	return Vector2i.ZERO

func get_chunk_size_for_chunk_id(chunk_id: String) -> Vector2i:
	var blueprint = chunk_blueprints.get(chunk_id)
	if blueprint:
		return blueprint.size
	return Vector2i.ZERO

func get_neighbor_chunk(current_chunk_id: String, direction: Vector2i) -> String:
	var current = chunk_blueprints.get(current_chunk_id)
	if not current:
		return ""
	var target_global = current.origin + (direction * current.size)
	var found = get_chunk_for_global_tile(target_global)
	return found.get("id", "")  # if found == {} fallback to ""

func is_global_tile_walkable(global_tile: Vector2i) -> bool:
	var chunk = get_chunk_for_global_tile(global_tile)
	if chunk == {}:
		return false
	var local = chunk["local"]
	var blueprint = chunk["blueprint"]
	# Add logic here to check terrain/objects/etc
	return true

func register_chunk(chunk_id: String, origin: Vector2i, size: Vector2i, metadata := {}):
	chunk_blueprints[chunk_id] = {
		"origin": origin,
		"size": size,
		"metadata": metadata
	}

func populate_from_loadhandler():
	chunk_blueprints.clear()
	var blueprints = LoadHandlerSingleton.get_chunk_blueprints()

	for chunk_id in blueprints.keys():
		var bp: Dictionary = blueprints[chunk_id]
		if bp.has("origin") and bp.has("size"):
			var origin = Vector2i(bp["origin"][0], bp["origin"][1])
			var size = Vector2i(bp["size"][0], bp["size"][1])
			register_chunk(chunk_id, origin, size, bp)
		else:
			print("⚠️ Skipping blueprint for", chunk_id, "- missing origin or size!")
