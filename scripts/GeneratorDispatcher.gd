extends Node

# Register map generators (add more as needed)
var local_map_generators = {}

const Consts = preload("res://scripts/Constants.gd")  # adjust path as needed


# Function to dispatch the city generator based on the biome
func generate_city(city_name: String, biome: String):
	# Match the biome type for generation
	match biome:
		"village":
			load_village_generator(city_name)
		# Add more biomes when needed

# Function to load the village generator
func load_village_generator(city_name: String):
	# Preload and instantiate the VillageGenerator
	var village_generator = preload("res://scripts/CityGenScripts/VillageGenerator.gd").new()
	village_generator.generate(city_name)
	
func generate_local_map(tile_container: Node):
	# 🚨 Ensure `tile_container` is valid before proceeding
	if tile_container == null:
		print("❌ ERROR: `tile_container` is NULL in GeneratorDispatcher! Aborting.")
		return null  # 🔥 Prevent retry loop

	# ✅ Get the player's current position and biome
	var player_position = LoadHandlerSingleton.get_player_position()
	var biome = LoadHandlerSingleton.get_biome_name(player_position)  # Fetches biome from JSON

	print("🌍 Player is in biome:", biome)  # Debugging output

	# ✅ Default generator is `debuggrasslandsgenerator.gd`
	var generator_path = "res://scripts/localmapgenscripts/debuggrasslandsgenerator.gd"

	# ✅ Use `forestgen.gd` if the biome is "forest"
	if biome == "forest":
		generator_path = "res://scripts/localmapgenscripts/forestgen.gd"

	# ✅ Use debugslumsgen` if the biome is "village-slums"
	elif biome == "village-slums":
		generator_path = "res://scripts/localmapgenscripts/debugslumsgen.gd"

	# ✅ Load the correct generator dynamically
	if not local_map_generators.has(biome):
		var generator_script = load(generator_path)
		if generator_script:
			local_map_generators[biome] = generator_script.new()
			add_child(local_map_generators[biome])  # ✅ Add to scene tree
			print("🛠 DEBUG: Loaded and added generator for biome:", biome)
		else:
			print("❌ ERROR: Failed to load generator for biome:", biome)
			return null  # 🔥 Prevent infinite retries

	# ✅ Call the generator's `generate_map(tile_container)`
	var result = await local_map_generators[biome].generate_map(tile_container)

	# 🚨 Debugging: Verify if result is valid
	if result == null:
		print("❌ ERROR: `generate_map()` returned NULL! **Stopping execution**.")
		return null  # 🔥 Prevent infinite retries
	elif result.size() < 2:
		print("❌ ERROR: `generate_map()` returned an invalid result:", result)
	else:
		print("✅ SUCCESS: `generate_map()` returned a valid map and object layer!")

	return result

func generate_local_map_to_jsons():
	var entry_context = LoadHandlerSingleton.load_entry_context()
	var entry_type = entry_context.get("entry_type", "default")

	if entry_type == "explore":
		print("🧭 Entry type is 'explore' — generating chunked localmap.")
		print("📢 DEBUG: Calling generate_chunked_local_map_to_jsons()")
		await generate_chunked_local_map_to_jsons()
		return
	else:
		print("🎯 Entry type is not 'explore' (got '%s') — fallback to single-chunk generation." % entry_type)
		# 🧪 Placeholder: Single-chunk generation not implemented yet
		# When ready, move the old logic here or route to a helper.
		return

func generate_chunked_local_map_to_jsons():
	print("📢 DEBUG: Calling generate_chunked_local_map_to_jsons() (PRE-LOAD)")

	var player_position = LoadHandlerSingleton.get_player_position()
	var biome = LoadHandlerSingleton.get_biome_name(player_position)
	if LoadHandlerSingleton.has_method("reset_chunk_state"):
		LoadHandlerSingleton.reset_chunk_state()
	var generator = get_generator_for_biome(biome)

	if generator == null:
		print("❌ ERROR: No valid generator found for biome:", biome)
		return

	var temp_tile_container := Node2D.new()
	get_tree().get_root().add_child(temp_tile_container)

	var result = await generator.generate_chunked_map(temp_tile_container)
	temp_tile_container.queue_free()

	if result == null or typeof(result) != TYPE_ARRAY or result.size() < 3:
		print("❌ ERROR: generate_chunked_map() did not return expected chunked data")
		return

	var grid_chunks: Dictionary = result[0]
	var object_chunks: Dictionary = result[1]
	var chunk_blueprints: Dictionary = result[2]
	var biome_key: String = result[3] if result.size() > 3 and typeof(result[3]) == TYPE_STRING else Consts.get_biome_chunk_key(biome)
	var entities: Dictionary = result[4] if result.size() > 4 and typeof(result[4]) == TYPE_DICTIONARY else {}
	var terrain_mods: Dictionary = result[5] if result.size() > 5 and typeof(result[5]) == TYPE_DICTIONARY else {}

	# 💾 Save chunked data
	LoadHandlerSingleton.save_all_chunked_localmap_files(grid_chunks, object_chunks, entities, terrain_mods, biome_key)
	print("✅ Chunked local map JSONs saved successfully.")

	# 🧠 Valid chunks
	var valid_chunks: Array[String] = []
	for chunk_key in grid_chunks.keys():
		if chunk_key.begins_with("chunk_"):
			valid_chunks.append(chunk_key.replace("chunk_", ""))

	var placement := LoadHandlerSingleton.load_temp_localmap_placement()
	if not placement.has("local_map"):
		placement["local_map"] = {}

	placement["local_map"]["valid_chunks"] = valid_chunks
	placement["local_map"]["chunk_blueprints"] = chunk_blueprints.duplicate(true)
	placement["local_map"]["biome_key"] = biome_key  # ✅ Include this!

	var spawn_chunk := Consts.get_spawn_chunk_for_biome(biome)
	placement["local_map"]["spawn_chunk"] = spawn_chunk
	placement["local_map"]["current_chunk_id"] = spawn_chunk
	placement["local_map"]["__chunk_id_set_by"] = "generate_chunked_local_map_to_jsons"

	print("🎯 Spawn chunk for biome '%s' set to: %s" % [biome, spawn_chunk])
	print("📐 Chunk blueprints saved:", chunk_blueprints.keys())
	print("🔒 valid_chunks updated in placement:", valid_chunks)

	LoadHandlerSingleton.save_temp_placement(placement)
	print("📍 Triggering post-save mount placement for:", spawn_chunk)
	LoadHandlerSingleton.chunked_mount_placement(spawn_chunk)

func get_generator_for_biome(biome: String) -> Node:
	var generator_path = "res://scripts/localmapgenscripts/debuggrasslandsgenerator.gd"  # Default

	if biome == "forest":
		generator_path = "res://scripts/localmapgenscripts/forestgen.gd"
	elif biome == "village-slums":
		generator_path = "res://scripts/localmapgenscripts/debugslumsgen.gd"

	# ✅ Load and cache the generator if it hasn't been already
	if not local_map_generators.has(biome):
		var generator_script = load(generator_path)
		if generator_script:
			var generator_instance = generator_script.new()
			local_map_generators[biome] = generator_instance
			add_child(generator_instance)
			print("🛠 Loaded and cached generator for biome:", biome)
		else:
			print("❌ ERROR: Could not load generator for biome:", biome)
			return null

	return local_map_generators[biome]
