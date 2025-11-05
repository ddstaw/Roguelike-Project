# res://scripts/TurnManager.gd
extends Node

## Holds the live LocalMap instance when one exists
var local_map_ref: Node = null

func end_player_turn(time_cost_minutes: int = 1) -> void:
# ⚙️ DEV NOTE — TURN ORDER CRITICAL
# This function’s order is intentional. Do NOT reorder cleanup or await calls.
#
# BUG HISTORY:
#   • NPCs vanished every other turn because the cleanup ran *after* the frame flush.
#     That caused newly drawn sprites to be deleted on the next process tick.
#   • Ghost NPCs appeared when cleanup was disabled or delayed, leaving stale sprites.
#
# FIX PRINCIPLE:
#   ✅ Always clean the NPCContainer *before* the first `await get_tree().process_frame`
#      so the scene tree is empty when new NPCs are redrawn.
#   ✅ The AI and persistence updates occur first (so data is fresh),
#      then cleanup, then frame flush, then redraw.
#
# TL;DR — keep the sequence:
#     1. AI + Save → 2. Cleanup → 3. await → 4. Redraw → 5. UI refresh
#
# Altering this order will reintroduce flicker, ghost sprites, or vanish loops.

	if local_map_ref == null:
		print("❌ TurnManager: No active LocalMap reference.")
		return

	var local_map = local_map_ref
	TimeManager.pass_minutes(time_cost_minutes)

	var visible_chunks = local_map.get_visible_chunks()
	var walkability_grid = LoadHandlerSingleton.get_walkability_grid_for_chunk(local_map.get_current_chunk_id())

	print("🕐 --- END PLAYER TURN START ---")
	print("📍 visible_chunks:", visible_chunks)
	print("📍 current_chunk_id:", local_map.get_current_chunk_id())
	print("📍 player_z (raw):", LoadHandlerSingleton.get_current_z_level())

	# ✅ Update visibility immediately (lighting, FOV, etc.)
	local_map.update_object_visibility(Vector2i(local_map.player.position.x / 88, local_map.player.position.y / 88))

	# 1️⃣ Run AI + persist JSON (this modifies and saves NPC data)
	NpcBehaviorManager.process_visible_npc_turns(visible_chunks, walkability_grid)

	# ✅ Clean out NPC containers *before* any await, so ghosts are removed now
	var underlay := local_map.get_node_or_null("NPCUnderlayContainer")
	var main := local_map.get_node_or_null("NPCContainer")
	if underlay == null or main == null:
		print("⚠️ Could not find NPC containers — skipping redraw.")
		return

		print("🧱 Underlay container:", underlay)
		print("🧱 Main container:", main)

	# 🧹 Clean both containers before we await — prevents stale or ghost sprites
		for child in main.get_children():
			if child and child.is_inside_tree():
				child.queue_free()

		for child in underlay.get_children():
			if child and child.is_inside_tree():
				child.queue_free()

		print("🧹 Pre-redraw cleanup complete for both containers, now redrawing NPCs.")
	
	# 2️⃣ Allow save I/O to finish before redrawing
	await get_tree().process_frame
	print("✅ Frame flush complete, beginning redraw phase")

	var player_z := str(LoadHandlerSingleton.get_current_z_level())

	# 3️⃣ Redraw visible NPCs for current Z (sync version)
	var total_drawn := 0
	for chunk_id in visible_chunks:
		print("🔎 Checking chunk before load:", chunk_id)
		var cur_npcs: Dictionary = LoadHandlerSingleton.get_npcs_in_chunk_z(chunk_id, player_z)
		print("📂 Loaded NPCs for", chunk_id, "count:", cur_npcs.size())

		for npc_id in cur_npcs.keys():
			var npc = cur_npcs[npc_id]
			if npc.has("position"):
				var pos = npc["position"]
				print("📍 Loaded pos:", npc_id, "→", pos)

		if not cur_npcs.is_empty():
			MapRenderer.redraw_npcs({ "npcs": cur_npcs }, main, chunk_id, false)
			if local_map.has_method("apply_fov_to_npc_layers"):
				local_map.apply_fov_to_npc_layers()
			total_drawn += cur_npcs.size()
		else:
			print("🚫 No NPCs found for", chunk_id, "after load.")

	# 🔽 3B — NEW: Draw underlay (Z-1) NPCs below the player’s level
	var below_z := str(int(player_z) - 1)
	for chunk_id in visible_chunks:
		var below_npcs: Dictionary = LoadHandlerSingleton.get_npcs_in_chunk_z(chunk_id, below_z)
		if below_npcs != null and not below_npcs.is_empty():
			print("⬇️ Rendering below-Z NPCs for", chunk_id, "→ count:", below_npcs.size())
			MapRenderer.redraw_npcs({ "npcs": below_npcs }, underlay, chunk_id, true)
			if local_map.has_method("apply_fov_to_npc_layers"):
				local_map.apply_fov_to_npc_layers()
	print("🧍 NPCs redrawn this turn:", total_drawn)

	# ✅ Let the engine process one frame so the moved sprites commit visually
	local_map.queue_redraw()

	# 4️⃣ Refresh UI labels (NOT visibility again)
	local_map.update_time_label()
	local_map.update_date_label()
	local_map.update_local_progress_bars()
	local_map.update_local_flavor_image()

	print("✅ --- END PLAYER TURN COMPLETE ---")
	if local_map_ref and local_map_ref.has_method("_sync_fov_after_load"):
		local_map_ref.call_deferred("_sync_fov_after_load")
	
