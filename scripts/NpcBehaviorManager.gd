extends Node

const NpcStates = preload("res://constants/npc_states.gd")

var active_npc_positions: Dictionary = {}

func process_visible_npc_turns(visible_chunks: Array, walkability_grid: Array) -> void:
	var local_map = get_tree().root.get_node_or_null("LocalMap")
	if local_map == null:
		return

	var player_position = Vector2i(local_map.player.position.x / 88, local_map.player.position.y / 88)

	active_npc_positions.clear()

	for chunk_id in visible_chunks:
		var chunk_npcs = LoadHandlerSingleton.get_npcs_in_chunk(chunk_id)
		for npc_id in chunk_npcs.keys():
			var npc = chunk_npcs[npc_id]
			var pos = Vector2i(npc["position"]["x"], npc["position"]["y"])
			active_npc_positions[pos] = true

	for chunk_id in visible_chunks:
		var chunk_npcs = LoadHandlerSingleton.get_npcs_in_chunk(chunk_id)
		print("🐾 Processing NPCs in chunk:", chunk_id, "→ count:", chunk_npcs.size())  # 👈 debug

		var changed_npcs := false

		for npc_id in chunk_npcs.keys():
			var npc = chunk_npcs[npc_id]
			print("   🔍 NPC", npc_id, "state=", npc.get("state", "MISSING"))  # 👈 debug

			match npc.get("state", ""):
				NpcStates.DAZZED:
					var moved = process_dazzed_npc(npc_id, chunk_npcs, walkability_grid)
					if moved:
						print("✅ NPC moved:", npc_id, "→", npc["position"])
						changed_npcs = true
				NpcStates.FOLLOW:
					process_follow_npc(npc, player_position)

			if npc.get("mood", NpcMoods.NEUTRAL) == NpcMoods.HOSTILE:
				pass  # Bark, alert nearby NPCs, etc

		if changed_npcs:
			print("💾 Saving updated NPCs for chunk", chunk_id)
			LoadHandlerSingleton.save_chunked_npc_chunk(chunk_id, { "npcs": chunk_npcs })
			MapRenderer.redraw_npcs({ "npcs": chunk_npcs }, local_map.tile_container, chunk_id)


func process_dazzed_npc(npc_id: String, chunk_npcs: Dictionary, walkability_grid: Array) -> bool:
	var npc = chunk_npcs[npc_id]
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	directions.shuffle()

	var current_pos = Vector2i(npc["position"]["x"], npc["position"]["y"])

	for dir in directions:
		var new_pos = current_pos + dir

		if not LoadHandlerSingleton.is_tile_walkable(walkability_grid, new_pos):
			print("🚫 Not walkable for", npc_id, "→", new_pos)
			continue
		if active_npc_positions.has(new_pos):
			print("🚫 Occupied by another NPC:", new_pos)
			continue

		# ✅ Move allowed - mutate original data
		chunk_npcs[npc_id]["position"]["x"] = new_pos.x
		chunk_npcs[npc_id]["position"]["y"] = new_pos.y
		active_npc_positions.erase(current_pos)
		active_npc_positions[new_pos] = true

		print("✅ NPC moved:", npc_id, "from", current_pos, "to", new_pos)
		return true

	print("❌ No valid moves for", npc_id, "at", current_pos)
	return false

func process_follow_npc(npc: Dictionary, player_pos: Vector2i) -> void:
	# Stub for now — will follow later
	pass
