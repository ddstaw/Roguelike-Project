extends Node

@onready var CellarGen = preload("res://scripts/localmapgenscripts/cellargen.gd").new()
@onready var CaveGen = preload("res://scripts/localmapgenscripts/cavegen.gd").new()
# Register this as a singleton via Project Settings > Autoload (ZLevelManager)

func process_z_down_egresses_for_biome(biome_key: String):
	var egresses: Array = LoadHandlerSingleton.get_egress_points()

	for egress in egresses:
		var z_offset = Constants.EGRESS_TYPES.get(egress.type, 0)
		if z_offset < 0:
			var target_z: int = int(egress.position.z + z_offset)
			var chunk_coords := Vector2i(
				floori(egress.position.x / 40),
				floori(egress.position.y / 40)
			)

			match z_offset:
				-1:
					print("📦 Dispatching cellar gen for:", chunk_coords)
					CellarGen.generate_cellar_chunk(chunk_coords, biome_key, egress)
				-2:
					print("📦 Dispatching cave gen for:", chunk_coords)
					#CaveGen.generate_cave_chunk(chunk_coords, biome_key, egress)
