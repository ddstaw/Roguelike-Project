## res://scripts/NpcBehaviorManager.gd
extends Node

const NpcStates = preload("res://constants/npc_states.gd")

var active_npc_positions: Dictionary = {}
func process_visible_npc_turns(visible_chunks: Array, walkability_grid: Array) -> void:
	var local_map = get_tree().root.get_node_or_null("LocalMap")
	if local_map == null:
		return

	var player_position = Vector2i(local_map.player.position.x / 88, local_map.player.position.y / 88)
	var player_z_level: int = int(LoadHandlerSingleton.get_current_z_level())

	var ACTIVE_Z_RANGE: int = 5
	var VALID_Z_MIN: int = -2
	var VALID_Z_MAX: int = 5

	active_npc_positions.clear()

	# --- Collect visible NPC positions (for FOV / collision)
	for chunk_id in visible_chunks:
		var chunk_npcs = LoadHandlerSingleton.get_npcs_in_chunk(chunk_id)
		for npc_id in chunk_npcs.keys():
			var npc = chunk_npcs[npc_id]
			var pos = Vector2i(npc["position"]["x"], npc["position"]["y"])
			active_npc_positions[pos] = true

	# --- Process every valid Z within range
	for z_to_check in range(VALID_Z_MIN, VALID_Z_MAX + 1):
		if abs(player_z_level - z_to_check) > ACTIVE_Z_RANGE:
			continue

		for chunk_id in visible_chunks:
			var z_str := str(z_to_check)
			var chunk_npcs = LoadHandlerSingleton.get_npcs_in_chunk_z(chunk_id, z_str)
			if chunk_npcs == null or chunk_npcs.is_empty():
				continue

			var changed_npcs := false

			for npc_id in chunk_npcs.keys():
				var npc = chunk_npcs[npc_id]
				var npc_z: int = int(npc.get("position", {}).get("z", z_to_check))

				# Skip NPCs outside range entirely
				if npc_z < VALID_Z_MIN or npc_z > VALID_Z_MAX:
					continue

				# --- Process AI and movement (applies to all Zs)
				match npc.get("state", ""):
					NpcStates.DAZZED:
						if process_dazzed_npc(npc_id, chunk_npcs, walkability_grid):
							changed_npcs = true
					NpcStates.FOLLOW:
						process_follow_npc(npc, player_position)

				# --- Hostility check for cross-Z targeting
				if npc.get("mood", NpcMoods.NEUTRAL) == NpcMoods.HOSTILE:
					register_cross_z_target(npc_id, npc_z)

			# --- Save updated data back to the correct Z-level JSON
			if changed_npcs:
				for npc_id in chunk_npcs.keys():
					var npc = chunk_npcs[npc_id]
					print("💾 Saving NPC:", npc_id, "→", npc["position"])
				LoadHandlerSingleton.save_chunked_npc_chunk_z(chunk_id, { "npcs": chunk_npcs }, z_str)
	# 🚫 No redraw logic here — visuals handled in TurnManager after all processing completes


# Temporary stub at top or bottom of the same script:
func register_cross_z_target(npc_id: String, npc_z: int) -> void:
	# TODO: Integrate with projectile / spell targeting later
	#print("🎯 Registered cross-Z target:", npc_id, "on z=", npc_z)
	return



func process_dazzed_npc(npc_id: String, chunk_npcs: Dictionary, walkability_grid: Array) -> bool:
	var npc = chunk_npcs[npc_id]
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	directions.shuffle()

	var current_pos = Vector2i(npc["position"]["x"], npc["position"]["y"])

	for dir in directions:
		var new_pos = current_pos + dir

		if not LoadHandlerSingleton.is_tile_walkable(walkability_grid, new_pos):
			#print("🚫 Not walkable for", npc_id, "→", new_pos)
			continue
		if active_npc_positions.has(new_pos):
			print("🚫 Occupied by another NPC:", new_pos)
			continue

		# ✅ Move allowed - mutate original data
		chunk_npcs[npc_id]["position"]["x"] = new_pos.x
		chunk_npcs[npc_id]["position"]["y"] = new_pos.y
		active_npc_positions.erase(current_pos)
		active_npc_positions[new_pos] = true

		#print("✅ NPC moved:", npc_id, "from", current_pos, "to", new_pos)
		return true

	#print("❌ No valid moves for", npc_id, "at", current_pos)
	return false

func process_follow_npc(npc: Dictionary, player_pos: Vector2i) -> void:
	# Stub for now — will follow later
	pass
