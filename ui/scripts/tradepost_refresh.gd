# res://ui/scripts/tradepost_refresh.gd
extends Node

# Refresh Tradepost tiles/objects/egresses right after character creation
func refresh_tradepost_data() -> void:
	print("🔄 Tradepost refresh starting…")

	# 1) Resolve save slot + base path (TRADEPOST, not *_hub)
	var slot: int = LoadHandlerSingleton.get_save_slot()
	var base_path: String = "user://saves/save%d/localchunks/tradepost/" % slot

	# Safety: only operate inside the tradepost biome folder
	if not base_path.ends_with("/tradepost/"):
		push_error("🚫 Aborted: base_path doesn’t end with /tradepost/")
		return

	# 2) Ensure z-level folders exist
	var z_levels: Array[String] = ["z-1", "z0", "z1", "z2"]
	for z: String in z_levels:
		var dir_path: String = base_path + z + "/"
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)

	# 3) Build tile/object chunks from refresh blueprints (per Z)
	var bp_path: String = "res://data/tradepost/tradepost_tiles_object_refresh.json"
	var refresh_data: Dictionary = _load_json(bp_path)
	if refresh_data.is_empty():
		push_error("❌ Missing or bad blueprint refresh file: " + bp_path)
		return

	var prefab: Dictionary = refresh_data["prefabs"][0]
	var tile_blueprints: Dictionary = prefab["tile_blueprints"]
	var object_blueprints: Dictionary = prefab["object_blueprints"]
	var blueprints: Array = refresh_data["blueprints"]

	for z: String in z_levels:
		var z_key: String = z.replace("z", "")  # "z-1" → "-1"
		var tile_name: String = str(tile_blueprints.get(z_key, ""))
		var obj_name: String = str(object_blueprints.get(z_key, ""))

		# TILE
		for bp: Dictionary in blueprints:
			var bp_name: String = str(bp.get("name", ""))
			if bp_name == tile_name:
				var tile_chunk_path: String = base_path + z + "/chunk_tile_chunk_0_0.json"
				_generate_tile_chunk(tile_chunk_path, bp)

		# OBJECT (write {} only)
		var obj_chunk_path: String = base_path + z + "/chunk_object_chunk_0_0.json"
		_write_json_file(obj_chunk_path, {})  # <- bare empty dict

	# 4) Copy egress register EXACTLY from refresh file
	var egress_src: String = "res://data/tradepost/tradepost_egress_reg_refresh.json"
	var egress_dst: String = base_path + "egress_register.json"
	var egress_data: Dictionary = _load_json(egress_src)
	if egress_data.is_empty():
		push_error("❌ Missing or bad egress refresh file: " + egress_src)
	else:
		_write_json_file(egress_dst, egress_data)
		print("✅ egress_register.json written:", egress_dst)

	print("✅ Tradepost refresh finished.")


# --- Tile chunk generation (reads legend mapped names) ---
func _generate_tile_chunk(path: String, bp: Dictionary) -> void:
	var tiles: Array = bp.get("tiles", [])
	var legend: Dictionary = bp.get("legend", {})

	var chunk_dict: Dictionary = {
		"chunk_coords": "0_0",
		"chunk_origin": { "x": 0, "y": 0 },
		"tile_grid": {}
	}

	for y in range(tiles.size()):
		var row: String = str(tiles[y])
		for x in range(row.length()):
			var ch := row[x]
			var name := _legend_name(legend, ch)
			var entry := {
				"state": {},
				"tile": name
			}
			chunk_dict["tile_grid"]["%d_%d" % [x, y]] = entry

	_write_json_file(path, chunk_dict)

# Legend helper: accepts either {"texture": "...", "name": "..."} or "texture_path"
func _legend_name(legend: Dictionary, ch: String) -> String:
	if not legend.has(ch):
		return "empty"
	var v = legend[ch]
	if typeof(v) == TYPE_DICTIONARY and v.has("name"):
		return str(v["name"])
	# else v is a texture path string → derive filename without .png
	var tex_path: String = str(v)
	var parts := tex_path.split("/")
	var filename := parts[parts.size() - 1]
	return filename.replace(".png", "")

# JSON I/O
func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var txt := f.get_as_text()
	f.close()
	var j := JSON.new()
	var err := j.parse(txt)
	if err != OK:
		return {}
	return j.data

func _write_json_file(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("❌ Failed to write: " + path)
		return
	f.store_string(JSON.stringify(data, "\t", true))
	f.close()
