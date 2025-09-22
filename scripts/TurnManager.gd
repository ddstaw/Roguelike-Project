extends Node

# Centralized turn handler for player + world simulation
func end_player_turn(time_cost_minutes: int = 1) -> void:
	var local_map = get_tree().root.get_node_or_null("LocalMap")
	if not local_map:
		print("❌ TurnManager: No LocalMap found.")
		return

	TimeManager.pass_minutes(time_cost_minutes)

	var visible_chunks = local_map.get_visible_chunks()  # Use the new getter

	# ✅ Use the array-style walkability grid instead of the dictionary
	var walkability_grid = LoadHandlerSingleton.get_walkability_grid_for_chunk(local_map.get_current_chunk_id())

	NpcBehaviorManager.process_visible_npc_turns(visible_chunks, walkability_grid)

	# Optional: update visuals
	local_map.update_object_visibility(
		Vector2i(local_map.player.position.x / 88, local_map.player.position.y / 88)
	)
	local_map.update_time_label()
	local_map.update_date_label()
	local_map.update_local_progress_bars()
	local_map.update_local_flavor_image()
