extends Node

@onready var CellarGen = preload("res://scripts/localmapgenscripts/cellargen.gd").new()
@onready var CaveGen = preload("res://scripts/localmapgenscripts/cavegen.gd").new()
# Register this as a singleton via Project Settings > Autoload (ZLevelManager)

func process_z_down_egresses_for_biome(biome_key: String):
	var short_key = Constants.get_biome_chunk_key(biome_key)
	var biome_config = Constants.get_biome_config(short_key)
	var chunk_size = biome_config["chunk_size"]

	var egresses: Array = LoadHandlerSingleton.get_egress_points()

	# Step 1: Generate Z-1 Cellars First
	var biome_folder = Constants.get_chunk_folder_for_key(short_key)
	var prefab_register = LoadHandlerSingleton.load_prefab_register(biome_folder)
	
	for egress in egresses:
		var z_offset = Constants.EGRESS_TYPES.get(egress.type, 0)
		if z_offset == -1:
			var chunk_coords = Vector2i(
				floori(egress.position.x / chunk_size.x),
				floori(egress.position.y / chunk_size.y)
			)
			print("📦 Dispatching cellar gen for:", chunk_coords)
			CellarGen.generate_cellar_chunk(chunk_coords, biome_key, egress, prefab_register)

	# 🔁 Refresh egress list — Z-1 generation may have created new Z-2 egresses
	egresses = LoadHandlerSingleton.get_egress_points()

	# Step 2: Generate Z-2 Caves
	for egress in egresses:
		var z_offset = Constants.EGRESS_TYPES.get(egress.type, 0)
		if z_offset == -2:
			var chunk_coords = Vector2i(
				floori(egress.position.x / chunk_size.x),
				floori(egress.position.y / chunk_size.y)
			)
			print("📦 Dispatching cave gen for:", chunk_coords)
			#CaveGen.generate_cave_chunk(chunk_coords, biome_key, egress)
