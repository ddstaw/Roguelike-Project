extends Node

# ─────────────────────────────────────────────────────────────
# ZLevelManager — orchestrates z-level generation for all biomes
# Handles z-1 Cellars, z-2 Caves, and z+N Upper Floors.
# Now uses the same deterministic save logic as CellarGen/CaveGen.
# ─────────────────────────────────────────────────────────────

@onready var CellarGen = preload("res://scripts/localmapgenscripts/cellargen.gd").new()
@onready var CaveGen   = preload("res://scripts/localmapgenscripts/cavegen.gd").new()
@onready var UpperGen  = preload("res://scripts/localmapgenscripts/uppergen.gd").new()

func run_full_generation_pass():
	var biome_keys = [
		"grass",
		"grassland_explore_fields",
		"forest",
		"mountain",
		"desert"
	]

	for biome_key in biome_keys:
		print("🌍 [ZLevelManager] Running full z-level generation for biome:", biome_key)

		await process_z_down_egresses_for_biome(biome_key)
		await get_tree().process_frame

		await process_z_up_prefabs_for_biome(biome_key)
		await get_tree().process_frame

	print("✅ [ZLevelManager] Completed full z-level generation for all biomes.")

# ─────────────────────────────────────────────────────────────
# Z-1: Cellars, Z-2: Caves
# ─────────────────────────────────────────────────────────────
func process_z_down_egresses_for_biome(biome_key: String) -> void:
	var short_key = Constants.get_biome_chunk_key(biome_key)
	if short_key == "":
		return

	var biome_config = Constants.get_biome_config(short_key)
	var chunk_size = biome_config["chunk_size"]

	var egresses: Array = LoadHandlerSingleton.get_egress_points()

	# Step 1️⃣: Generate Z-1 Cellars
	var biome_folder = Constants.get_chunk_folder_for_key(short_key)
	var prefab_register = LoadHandlerSingleton.load_prefab_register(biome_folder)

	for egress in egresses:
		var z_offset = Constants.EGRESS_TYPES.get(egress.type, 0)
		if z_offset == -1 and egress.position.z == 0:
			var chunk_coords = Vector2i(
				floori(egress.position.x / chunk_size.x),
				floori(egress.position.y / chunk_size.y)
			)
			CellarGen.generate_cellar_chunk(chunk_coords, biome_key, egress, prefab_register)

	await get_tree().process_frame

	# Step 2️⃣: Generate Z-2 Caves
	egresses = LoadHandlerSingleton.get_combined_egress_list()
	var z2_chunks := {}

	for egress in egresses:
		if egress.has("target_z") and egress["target_z"] == -2:
			var pos = egress["position"]
			var chunk_coords = Vector2i(
				floori(pos["x"] / chunk_size.x),
				floori(pos["y"] / chunk_size.y)
			)
			z2_chunks[chunk_coords] = egress

	# Fill out entire grid if not covered
	var grid_size = biome_config.get("grid_size", Vector2i(1, 1))
	for x in grid_size.x:
		for y in grid_size.y:
			var coords = Vector2i(x, y)
			if not z2_chunks.has(coords):
				z2_chunks[coords] = {}  # empty dirt fallback

	for coords in z2_chunks.keys():
		var egress_data = z2_chunks[coords]
		CaveGen.generate_cave_chunk(coords, biome_key, egress_data)

# ─────────────────────────────────────────────────────────────
# Z+N: Upper Floors
# ─────────────────────────────────────────────────────────────
func process_z_up_prefabs_for_biome(biome_key: String) -> void:
	var short_key = Constants.get_biome_chunk_key(biome_key)
	if short_key == "":
		print("⚠️ [ZLevelManager] Invalid short_key for biome:", biome_key)
		return

	print("🏗 [ZLevelManager] Generating upper floors for biome:", biome_key)

	# 🧹 Clear existing upper z-level data (z1–z5) before regeneration
	LoadHandlerSingleton.clear_upper_z_for_biome(biome_key)

	# Load prefab data and registers
	var prefab_data = LoadHandlerSingleton.load_prefab_data(biome_key)
	if prefab_data == null or prefab_data.size() < 2:
		print("⚠️ [ZLevelManager] No prefab data found for biome:", biome_key)
		return

	var biome_folder = Constants.get_chunk_folder_for_key(short_key)
	var prefab_register = LoadHandlerSingleton.load_prefab_register(biome_folder)
	if prefab_register.is_empty():
		print("⚠️ [ZLevelManager] Empty prefab register for biome:", biome_key)
		return

	# Iterate through prefab entries
	for chunk_key in prefab_register.keys():
		var prefab_entry = prefab_register[chunk_key]
		if not prefab_entry.has("prefab_id"):
			continue

		var prefab_name = prefab_entry["prefab_id"]
		var prefab_match: Dictionary = {}

		# Prefer direct floor data if present
		if prefab_entry.has("floors"):
			prefab_match = {
				"name": prefab_name,
				"floors": prefab_entry["floors"]
			}
		else:
			# fallback: find by name in biome prefab list
			if typeof(prefab_data) == TYPE_ARRAY and prefab_data.size() > 0:
				var all_prefabs = prefab_data[0]
				for p in all_prefabs:
					if p.get("name", "") == prefab_name:
						prefab_match = p
						break

		if prefab_match.is_empty():
			print("⚠️ [ZLevelManager] No matching prefab found for:", prefab_name)
			continue

		var coords = prefab_entry.get("coords", {"x": 0, "y": 0})
		print("🏗 Generating upper floors for:", prefab_name, "at", coords)

		await UpperGen.generate_upper_floors(
			prefab_match,
			biome_key,
			chunk_key,
			Vector2i(coords["x"], coords["y"])
		)

		await get_tree().process_frame

	print("✅ [ZLevelManager] Finished generating upper floors for biome:", biome_key)
