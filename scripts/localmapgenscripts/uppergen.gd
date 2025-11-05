extends Node

# ─────────────────────────────────────────────────────────────
# UpperGen — generates upper floors and roofs for multi-floor prefabs
# Uses LoadHandlerSingleton.write_zlevel_chunk() for all saves.
# Clears stale z1–z5 chunk JSONs on biome re-explore.
# ─────────────────────────────────────────────────────────────

# Optional helper (kept for compatibility)
func _get_blueprint_map_for_biome(biome_key: String) -> Dictionary:
	var result = LoadHandlerSingleton.load_prefab_data(biome_key)
	if typeof(result) == TYPE_ARRAY and result.size() >= 2:
		return result[1]
	elif typeof(result) == TYPE_DICTIONARY:
		return result
	return {}

func _stamp_visual_egresses_for_z(
	biome_key: String,
	chunk_key: String,
	z_level: int,
	flat_local: Dictionary
) -> void:
	var short_key := Constants.get_biome_chunk_key(biome_key)
	var biome_folder := Constants.get_chunk_folder_for_key(short_key)
	var egress_data: Dictionary = LoadHandlerSingleton.load_egress_register(biome_folder)

	var chunk_z_key := "%s|z%d" % [chunk_key, z_level]
	if not egress_data.has(chunk_z_key):
		return

	var egress_array: Array = egress_data[chunk_z_key]
	for egress_item in egress_array:
		if typeof(egress_item) != TYPE_DICTIONARY:
			continue
		var etype: String = egress_item.get("type", "")
		var pos: Dictionary = egress_item.get("position", {})
		if typeof(pos) != TYPE_DICTIONARY:
			continue

		var ex: int = int(pos.get("x", -1))
		var ey: int = int(pos.get("y", -1))
		if ex < 0 or ey < 0:
			continue

		var key := "%d_%d" % [ex, ey]
		var stair_tile: String = etype
		if not Constants.TEXTURE_TO_NAME.values().has(stair_tile):
			stair_tile = "stone_stairs_down"  # fallback

		flat_local[key] = {
			"tile": stair_tile,
			"state": LoadHandlerSingleton.get_tile_state_for(stair_tile)
		}
		print("🪜 [UpperGen] Stamped visual egress:", stair_tile, "at", key)

# ─────────────────────────────────────────────────────────────
# UpperGen — simplified single-roof generation for towers
# ─────────────────────────────────────────────────────────────

func generate_upper_floors(prefab_def: Dictionary, biome_key: String, chunk_key: String, global_place_at: Vector2i) -> void:
	print("🧱 [UpperGen] Generating single roof layer for:", prefab_def.get("name", "unknown"), "chunk:", chunk_key)

	# 0) Validate biome key
	var short_key := Constants.get_biome_chunk_key(biome_key)
	if short_key == "":
		print("⚠️ [UpperGen] Invalid biome key:", biome_key)
		return

	# 1) Get the prefab’s floor definitions
	var all_floors: Dictionary = prefab_def.get("floors", {})
	if all_floors.is_empty():
		print("⚠️ [UpperGen] No floor data found for:", prefab_def.get("name", "unknown"))
		return

	# 2) Identify the roof blueprint name
	var roof_blueprint_name := ""
	for key in all_floors.keys():
		if key.to_lower().find("roof") != -1:
			roof_blueprint_name = all_floors[key]
			break

	if roof_blueprint_name == "":
		print("⚠️ [UpperGen] No roof entry found for:", prefab_def.get("name", "unknown"))
		return

	# 3) Load biome blueprint map
	var biome_data = LoadHandlerSingleton.load_prefab_data(biome_key)
	var blueprint_map: Dictionary = {}
	if typeof(biome_data) == TYPE_ARRAY and biome_data.size() >= 2:
		blueprint_map = biome_data[1]

	if not blueprint_map.has(roof_blueprint_name):
		print("⚠️ [UpperGen] Missing roof blueprint:", roof_blueprint_name)
		return

	var bp: Dictionary = blueprint_map[roof_blueprint_name]
	print("🧩 [UpperGen] Using blueprint:", roof_blueprint_name)

	# 4) Resolve chunk placement
	var biome_cfg = Constants.get_biome_config(short_key)
	var chunk_size: Vector2i = biome_cfg.get("chunk_size", Vector2i(40, 40))
	var parts = chunk_key.replace("chunk_", "").split("_")
	if parts.size() != 2:
		print("⚠️ [UpperGen] Bad chunk key:", chunk_key)
		return

	var cx = int(parts[0])
	var cy = int(parts[1])
	var chunk_origin = Vector2i(cx * chunk_size.x, cy * chunk_size.y)
	var local_place_at = global_place_at - chunk_origin

	# 5) Build z1 tile grid
	var w: int = bp.get("width", 0)
	var h: int = bp.get("height", 0)
	var rows: Array = bp.get("tiles", [])
	var legend: Dictionary = bp.get("legend", {})

	var flat_local := {}
	for sy in range(min(h, rows.size())):
		var row: String = rows[sy]
		for sx in range(min(w, row.length())):
			var sym := row[sx]
			var tex_path: String = legend.get(sym, "")
			if tex_path == "":
				continue
			var tex = load(tex_path)
			if tex == null:
				continue
			var tile_name: String = Constants.TEXTURE_TO_NAME.get(tex, "unknown")
			if tile_name == "unknown":
				continue

			var lx = local_place_at.x + sx
			var ly = local_place_at.y + sy
			if lx < 0 or ly < 0 or lx >= chunk_size.x or ly >= chunk_size.y:
				continue

			var key = str(lx) + "_" + str(ly)
			flat_local[key] = {
				"tile": tile_name,
				"state": LoadHandlerSingleton.get_tile_state_for(tile_name)
			}

	# 6) Save as z1 layer (merge into existing openair grid)
	var biome_key_short = Constants.get_biome_chunk_key(biome_key)
	var biome_folder = Constants.get_chunk_folder_for_key(biome_key_short)
	var chunk_filename = "chunk_tile_%s.json" % chunk_key
	var z_dir = LoadHandlerSingleton.get_save_file_path() + "localchunks/%s/z1/" % biome_folder
	DirAccess.make_dir_recursive_absolute(z_dir)

	var z_path = z_dir + chunk_filename

	# --- Load existing openair file if it exists
	var existing: Dictionary = {}
	if FileAccess.file_exists(z_path):
		existing = LoadHandlerSingleton.load_json_file(z_path)
	else:
		existing = {
			"chunk_coords": chunk_key.replace("chunk_", ""),
			"chunk_origin": {"x": chunk_origin.x, "y": chunk_origin.y},
			"tile_grid": {}
		}

	# ✅ Explicit type annotation here fixes Variant warning
	var tile_grid: Dictionary = existing.get("tile_grid", {})

	# --- Merge: paint prefab roof tiles onto the existing grid
	for key in flat_local.keys():
		tile_grid[key] = flat_local[key]
	
	_stamp_visual_egresses_for_z(biome_key, chunk_key, 1, tile_grid)
	
	existing["tile_grid"] = tile_grid
	
	# --- Save back to disk
	LoadHandlerSingleton.save_json_file(z_path, existing)
	print("💾 [UpperGen] Merged roof layer:", roof_blueprint_name, "→ z1 for", prefab_def["name"])
