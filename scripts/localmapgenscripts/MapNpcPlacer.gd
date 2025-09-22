# NpcPlacer.gd 
extends Node

func place_npcs(grid: Array, placed_objects: Dictionary, chunk_key: String, origin: Vector2i, npc_rules: Dictionary, excluded_positions := {}) -> Dictionary:
	var placed_npcs := {}
	var blocked := excluded_positions.duplicate()

	print("🐾 [NPC Placer] Starting NPC placement for chunk:", chunk_key)
	print("📜 Received NPC rules:", npc_rules)

	# Mark object-occupied tiles as blocked
	for obj_id in placed_objects:
		var pos = placed_objects[obj_id].get("position", {})
		if pos.has("x") and pos.has("y"):
			blocked[Vector2i(pos["x"], pos["y"])] = true

	# Mark unwalkable tile types
	for x in range(grid.size()):
		for y in range(grid[x].size()):
			var tile = grid[x][y]
			var tname = tile.get("tile", "")
			if tname in ["water", "bridge", "tree", "bush", "flowers", "bed", "candelabra"]:
				blocked[Vector2i(x, y)] = true

	# For each NPC rule
	for npc_group in npc_rules.keys():
		var rule = npc_rules[npc_group]
		print("👥 Processing NPC group:", npc_group, "→ rule:", rule)

		if not rule.get("initial_spawn", false):
			print("🚫 Skipping", npc_group, "- initial_spawn disabled.")
			continue

		var max_count = rule.get("max_per_chunk", 0)
		var min_count = rule.get("min_per_chunk", 0)
		var spawn_chance = rule.get("spawn_chance", 1.0)
		var npc_types = rule.get("types", [])
		if npc_types.size() == 0:
			print("⚠️ Skipping", npc_group, "- no NPC types listed.")
			continue

		if randf() > spawn_chance:
			print("🎲 Skipping", npc_group, "- spawn chance failed.")
			continue

		var target_count = randi_range(min_count, max_count)
		print("✅ Spawning", target_count, "NPC(s) from group:", npc_group)

		var spawn_attempts = 0
		var spawned = 0

		while spawned < target_count and spawn_attempts < 50:
			var rx = randi() % grid.size()
			var ry = randi() % grid[0].size()
			var pos = Vector2i(rx, ry)

			if blocked.has(pos):
				spawn_attempts += 1
				continue

			var npc_id = "%s_%s_%d" % [npc_group, chunk_key, spawned]
			var npc_type = npc_types[randi() % npc_types.size()]
			
			placed_npcs[npc_id] = {
				"id": npc_id,
				"type": npc_type,
				"position": { "x": rx, "y": ry, "z": 0 },
				"state": "dazzed"
			}

			blocked[pos] = true
			spawned += 1
			print("🌟 Placed", npc_id, "at", pos)

	if placed_npcs.is_empty():
		print("📭 No NPCs placed in chunk:", chunk_key)
	else:
		print("📦 NPCs placed in", chunk_key, ":", placed_npcs.keys())

	return placed_npcs
