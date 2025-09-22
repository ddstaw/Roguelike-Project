extends Node

@onready var CellarGen = preload("res://scripts/localmapgenscripts/cellargen.gd").new()
@onready var CaveGen = preload("res://scripts/localmapgenscripts/cavegen.gd").new()

func _ready():
	await process_z_down_egresses_for_biome("grass")

func process_z_down_egresses_for_biome(biome_key: String) -> void:
	var short_key = Constants.get_biome_chunk_key(biome_key)
	if short_key == "":
		return

	var biome_config = Constants.get_biome_config(short_key)
	var chunk_size = biome_config["chunk_size"]

	var egresses: Array = LoadHandlerSingleton.get_egress_points()

	# Step 1: Generate Z-1 Cellars
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

	# Wait a frame to ensure Z-1 I/O is flushed
	await get_tree().process_frame

	# Step 2: Generate Z-2 Caves
	egresses = LoadHandlerSingleton.get_combined_egress_list()

	var z2_chunks := {}

	for egress in egresses:
		if egress.has("target_z") and egress["target_z"] == -2:
			var pos = egress["position"]
			var chunk_coords = Vector2i(
				floori(pos["x"] / chunk_size.x),
				floori(pos["y"] / chunk_size.y)
			)
			z2_chunks[chunk_coords] = egress  # Track the most relevant egress (if any)

	# Fill out entire grid if not covered
	var grid_size = biome_config.get("grid_size", Vector2i(1, 1))
	for x in grid_size.x:
		for y in grid_size.y:
			var coords = Vector2i(x, y)
			if not z2_chunks.has(coords):
				z2_chunks[coords] = {}  # No egress, but still needs dirt chunk

	for coords in z2_chunks.keys():
		var egress_data = z2_chunks[coords]
		CaveGen.generate_cave_chunk(coords, biome_key, egress_data)

