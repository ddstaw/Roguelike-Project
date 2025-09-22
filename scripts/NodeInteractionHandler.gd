#NodeInteractionHandler.gd
extends Node

var travel_log_control: Node = null  # set this from PlayerVisual or LocalMap
var last_interaction_pos: Vector2i
var last_interaction_tile_data: Dictionary

const NodeLootContainer := preload("res://ui/scripts/NodeLootContainer.gd")

# -- put this above the functions that use it --
func _ctx_for_pos(pos: Vector2i) -> Dictionary:
	# You said you want BOTH biome (name/string you use elsewhere) and biome_key (register key).
	# If get_localmap_biome_key() already returns the key (e.g., "gef"),
	# and you also want a display name, keep both fields available.
	var biome_key: String = LoadHandlerSingleton.get_localmap_biome_key()
	# If you have a mapping from key -> human name, do it here; else just duplicate key.
	var biome_name: String = biome_key  # or Constants.get_biome_name_from_key(biome_key)
	var z_key: String     = str(LoadHandlerSingleton.get_localmap_z_key()) # force string
	var chunk_key: String = LoadHandlerSingleton.get_chunk_key_for_pos(pos)

	return {
		"biome": biome_name,
		"biome_key": biome_key,
		"z": z_key,
		"chunk": chunk_key
	}


func handle_interaction(pos: Vector2i, tile_data: Dictionary) -> void:
	var node_type: String = tile_data.get("type", "none") as String
	var category: String = tile_data.get("category", "none") as String

	match node_type:
		"bush": _handle_bush(pos, tile_data)
		"flowers": _handle_flowers(pos, tile_data)
		"tree": _handle_tree(pos, tile_data)
		"water": _handle_water(pos, tile_data)
		_:
			_log("You don’t find anything useful here.")

func _handle_bush(pos: Vector2i, tile_data: Dictionary) -> void:
	var time_data: Dictionary = LoadHandlerSingleton.get_time_and_date()
	var current_dt: Dictionary = {
		"date": time_data.get("gamedate", "Unknown"),
		"time": time_data.get("gametime", "Unknown")
	}
	_interact_with_loot_node(pos, tile_data, current_dt)

func _handle_tree(pos: Vector2i, tile_data: Dictionary) -> void:
	var time_data := LoadHandlerSingleton.get_time_and_date()
	var current_dt := {
		"date": time_data.get("gamedate", "Unknown"),
		"time": time_data.get("gametime", "Unknown")
	}
	_interact_with_loot_node(pos, tile_data, current_dt)

func _handle_flowers(pos: Vector2i, tile_data: Dictionary) -> void:
	var time_data := LoadHandlerSingleton.get_time_and_date()
	var current_dt := {
		"date": time_data.get("gamedate", "Unknown"),
		"time": time_data.get("gametime", "Unknown")
	}
	_interact_with_loot_node(pos, tile_data, current_dt)

func _handle_water(pos: Vector2i, tile_data: Dictionary) -> void:
	_log(tile_data.get("message", ""))


func _log(msg: String) -> void:
	if travel_log_control:
		travel_log_control.add_message_to_log(msg)

func get_tile_interaction_data(tile_type: String) -> Dictionary:
	var type := "none"
	var category := "none"
	var message := "… There's nothing to interact with here."

	if tile_type.begins_with("bush"):
		type = "bush"
		category = "open"
		message = "You rustle through the bush’s branches…"
	elif tile_type.begins_with("tree"):
		type = "tree"
		category = "open"
		message = "If I had an axe, I could cut this down."
	elif tile_type.begins_with("flowers"):
		type = "flowers"
		category = "open"
		message = "You examine the blooming flowers."
	elif tile_type.begins_with("water") or tile_type.contains("POND"):
		type = "water"
		category = "tool"
		message = "If I had a fishing pole or liquid container, I could do something here."

	return {
		"type": type,
		"category": category,
		"message": message
	}

func _show_inventory_and_node_transfer(pos: Vector2i, tile_data: Dictionary) -> void:
	last_interaction_pos = pos
	last_interaction_tile_data = tile_data

	var ui_layer := get_tree().root.get_node_or_null("LocalMap/UILayer")
	if ui_layer == null:
		push_warning("❌ UILayer not found.")
		return

	var ctx: Dictionary = _ctx_for_pos(pos)
	var biome: String      = String(ctx["biome"])
	var z_key: String      = str(ctx["z"])   # was String(ctx["z"])
	var chunk_coords := LoadHandlerSingleton.get_current_chunk_coords()
	var chunk_key := "chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]
	var biome_key: String  = String(ctx["biome_key"])

	var node_type: String = String(tile_data.get("type", "none"))
	var node_id: String   = "%s_%d_%d" % [node_type, pos.x, pos.y]

	var node_data: Dictionary = LoadHandlerSingleton.get_node_entry(
		biome,
		z_key,
		chunk_key,
		biome_key,
		node_id
	)
	if node_data.is_empty():
		push_warning("⚠️ Node data not found!")
		return

	var inventory_scene := preload("res://ui/scenes/Inventory_mini.tscn")
	var inventory_instance := inventory_scene.instantiate()
	ui_layer.add_child(inventory_instance)

	var transfer_win := inventory_instance.get_node("NodeTransferWindow/PanelContainer")
	if transfer_win == null:
		push_error("❌ NodeTransferWindow not found inside Inventory_mini!")
		return

	transfer_win.set_data(
		node_data,  # pass full node dict, not just inventory
		LoadHandlerSingleton.load_player_inventory_dict(),
		node_type,
		biome,       # from ctx
		z_key,
		chunk_key,
		biome_key,
		node_id
	)

	var label_node := inventory_instance.get_node("NodeTransferWindow/PanelContainer/Label")
	if label_node:
		label_node.text = "Looting " + node_type.capitalize()

	inventory_instance.position = Vector2(0, 0)
	inventory_instance.visible = true

func handle_object_interaction(pos: Vector2i, obj_data: Dictionary) -> void:
	var node_type: String = obj_data.get("type", "none") as String

	match node_type:
		"bed":
			_handle_bed(pos, obj_data)
		"woodchest":
			_handle_woodchest(pos, obj_data)
		"mount":
			_handle_mount(pos, obj_data)
		_:
			_log("You examine the object, but nothing happens.")

func _handle_bed(pos: Vector2i, obj_data: Dictionary) -> void:
	_log("This bed looks comfortable.")
	# TODO: trigger rest menu or sleep logic

func _handle_woodchest(pos: Vector2i, obj_data: Dictionary) -> void:
	_log("I open the chest.")
	var time_data := LoadHandlerSingleton.get_time_and_date()
	var current_dt := {
		"date": time_data.get("gamedate", "Unknown"),
		"time": time_data.get("gametime", "Unknown")
	}
	_interact_with_storage(pos, obj_data, current_dt)


func _handle_mount(pos: Vector2i, obj_data: Dictionary) -> void:
	_log("My transport awaits.")
	var time_data := LoadHandlerSingleton.get_time_and_date()
	var current_dt := {
		"date": time_data.get("gamedate", "Unknown"),
		"time": time_data.get("gametime", "Unknown")
	}
	_interact_with_mount(pos, obj_data)


func handle_npc_interaction(pos: Vector2i, npc_data: Dictionary) -> void:
	var npc_type: String = npc_data.get("type", "none")
	
	match npc_type:
		"CRE0001":
			_handle_orangecat(pos, npc_data)
		"CRE0002":
			_handle_greensnake(pos, npc_data)
		"NPC0001":
			_handle_bluewizard(pos, npc_data)
		_:
			_handle_generic_npc(pos, npc_data)

func _handle_orangecat(pos: Vector2i, npc_data: Dictionary) -> void:
	_log("The orange cat looks at you.")
	_show_dialogue()
	# TODO: maybe add affection score or pet UI

func _handle_greensnake(pos: Vector2i, npc_data: Dictionary) -> void:
	_log("The green snake slithers quietly.")
	# TODO: potential combat trigger?

func _handle_bluewizard(pos: Vector2i, npc_data: Dictionary) -> void:
	_log("The wizard nods sagely and shows you his wares.")

	var time_data := LoadHandlerSingleton.get_time_and_date()
	var current_dt := {
		"date": time_data.get("gamedate", "Unknown"),
		"time": time_data.get("gametime", "Unknown")
	}

	_interact_with_vendor(pos, npc_data, current_dt)

func _handle_generic_npc(pos: Vector2i, npc_data: Dictionary) -> void:
	_log("They glance your way but say nothing.")

func _show_chest_or_mount_inventory():
	print("🧳 Attempting to open chest or mount inventory...")

	var ui_layer := get_tree().root.get_node_or_null("LocalMap/UILayer/NodeTransferWindow")
	print("🧳 ui_layer found:", ui_layer != null)

	if ui_layer == null:
		push_warning("❌ UI layer for inventory not found.")
		return

	var inventory_scene := preload("res://ui/scenes/Inventory_chest.tscn")
	var inventory_instance := inventory_scene.instantiate()

	print("📦 Chest inventory instance created:", inventory_instance != null)

	ui_layer.add_child(inventory_instance)
	print("✅ Chest inventory added to UI layer")

	inventory_instance.position = Vector2(0, 0)
	inventory_instance.visible = true

func _open_trade_inventory(
	player_inv: Dictionary,
	vendor_inv: Dictionary,
	vendor_type: String,
	pos: Vector2i,
	biome: String,
	vendor_id: String
) -> void:
	var ui_layer := get_tree().root.get_node_or_null("LocalMap/UILayer/NodeTransferWindow")
	if ui_layer == null:
		push_warning("❌ UILayer not found. Trade UI will not show.")
		return

	var trade_scene := preload("res://ui/scenes/Inventory_trade.tscn")
	var trade_instance := trade_scene.instantiate()
	trade_instance.name = "TradeInventoryUI"
	ui_layer.add_child(trade_instance)

	trade_instance.set_data(player_inv, vendor_inv, pos, biome, vendor_id, vendor_type)

	trade_instance.position = Vector2(0, 0)
	trade_instance.visible = true
	get_tree().paused = true

func _show_dialogue() -> void:
	print("🗨️ Attempting to show dialogue popup...")

	var ui_layer := get_tree().root.get_node_or_null("LocalMap/UILayer/NodeTransferWindow")
	if ui_layer == null:
		push_warning("❌ UI layer for dialogue not found.")
		return

	var dialogue_scene := preload("res://ui/scenes/dialogue.tscn")
	var dialogue_instance := dialogue_scene.instantiate()

	print("📘 Dialogue instance created:", dialogue_instance != null)

	ui_layer.add_child(dialogue_instance)
	dialogue_instance.position = Vector2(0, 0)
	dialogue_instance.visible = true

	get_tree().paused = true
	print("⏸ Game paused for dialogue")
	
func _interact_with_loot_node(pos: Vector2i, tile_data: Dictionary, current_datetime: Dictionary) -> void:
	last_interaction_pos = pos
	last_interaction_tile_data = tile_data

	var node_type: String = String(tile_data.get("type", "none"))
	var message: String   = String(tile_data.get("message", ""))
	if message != "":
		_log(message)

	var ctx: Dictionary   = _ctx_for_pos(pos)
	var biome: String     = String(ctx["biome"])
	var z_key: String     = str(ctx["z"])   # was String(ctx["z"])
	var chunk_coords := LoadHandlerSingleton.get_current_chunk_coords()
	var chunk_key := "chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]
	var biome_key: String = String(ctx["biome_key"])
	var node_id: String   = "%s_%d_%d" % [node_type, pos.x, pos.y]

	LoadHandlerSingleton.ensure_node_entry_with_loot(
		biome,
		z_key,
		chunk_key,
		biome_key,
		node_id,
		node_type,
		pos,
		current_datetime
	)

	_show_inventory_and_node_transfer(pos, tile_data)
func _open_dual_inventory(
	player_inv: Dictionary,
	other_inv: Dictionary,
	label_text: String,
	container_type: String,   # "storage" or "mount" (source type)
	pos: Vector2i,
	biome: String,
	container_id: String,
	z_key: String = "",
	chunk_key: String = "",
	biome_key: String = ""
) -> void:
	var ui_layer := get_tree().root.get_node_or_null("LocalMap/UILayer")
	if ui_layer == null:
		push_warning("❌ UILayer not found. Inventory UI will not show.")
		return

	var chest_ui := preload("res://ui/scenes/Inventory_chest.tscn").instantiate()
	chest_ui.name = "ChestInventoryUI"
	ui_layer.add_child(chest_ui)

	# Derive a display type without changing the signature:
	# - if storage, use the prefix of container_id (e.g. "woodchest_25_5" -> "woodchest")
	# - else use "mount" (or whatever container_type already is)
	var display_type := container_type
	if container_type == "storage" and container_id != "":
		var us := container_id.find("_")
		if us != -1:
			display_type = container_id.substr(0, us)  # e.g. "woodchest"

	# ✅ Let the scene handle populating panels + setting TitleLabel based on display_type
	chest_ui.set_data(
		player_inv,
		other_inv,
		pos,
		biome,
		container_id,
		display_type  # <- "woodchest" / "mount" / etc.
	)

	# Panels still need their source types for saving
	var player_panel: Node = chest_ui.get_node("Player_Panel")
	player_panel.inventory_source_type = "player"

	var other_panel: Node = chest_ui.get_node("Container_control/Storage_Panel")
	other_panel.inventory_source_type = container_type  # keep "storage" or "mount" for persistence paths

	if container_type == "storage":
		other_panel.biome_id = biome
		other_panel.storage_id = container_id
		other_panel.z_key = z_key
		other_panel.chunk_key = chunk_key
		other_panel.biome_key = biome_key

		print("📦 Opening storage:", container_id,
			  "display_type:", display_type,
			  "pos:", pos,
			  "chunk:", LoadHandlerSingleton.get_chunk_key_for_pos(pos))

	chest_ui.position = Vector2(0, 0)
	chest_ui.visible = true
	get_tree().paused = true

	print("📦 Opened dual inventory:",
		  "source_type:", container_type,
		  "display_type:", display_type,
		  "| Player keys:", player_inv.keys(),
		  "| Other keys:", other_inv.keys())


func _interact_with_storage(pos: Vector2i, tile_data: Dictionary, timestamp: Dictionary) -> void:
	var storage_type: String = String(tile_data.get("storage_type", "woodchest"))

	var ctx: Dictionary   = _ctx_for_pos(pos)
	var biome: String     = String(ctx["biome"])
	var z_key: String     = str(ctx["z"])
	var chunk_coords := LoadHandlerSingleton.get_current_chunk_coords()
	var chunk_key := "chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]
	var biome_key: String = String(ctx["biome_key"])
	var storage_id: String = "%s_%d_%d" % [storage_type, pos.x, pos.y]

	LoadHandlerSingleton.ensure_storage_entry_with_loot(
		biome,
		z_key,
		chunk_key,
		biome_key,
		storage_id,
		storage_type,
		pos,
		timestamp
	)

	var player_inv: Dictionary = LoadHandlerSingleton.load_player_inventory_dict()
	var storage_register: Dictionary = LoadHandlerSingleton.load_storage_register(biome)
	var storage_inv: Dictionary = storage_register[z_key][chunk_key][biome_key][storage_id]["inventory"]

	# 🔑 Pass the correct chunk_key into _open_dual_inventory
	_open_dual_inventory(
		player_inv,
		storage_inv,
		"",
		"storage",
		pos,
		biome,
		storage_id,
		z_key,
		chunk_key,   # ✅ now Storage_Panel knows the correct chunk
		biome_key
	)




func _interact_with_mount(pos: Vector2i, obj_data: Dictionary) -> void:
	var player_inv := LoadHandlerSingleton.load_player_inventory_dict()
	var mount_inv := LoadHandlerSingleton.load_mount_inv()

	_log("You check your mount’s saddlebags.")
	# 🔑 Call updated _open_dual_inventory
	_open_dual_inventory(player_inv, mount_inv, "Mount Inventory", "mount", pos, "", "mount")

func _interact_with_vendor(pos: Vector2i, tile_data: Dictionary, current_datetime: Dictionary) -> void:
	var vendor_type: String = tile_data.get("type", "unknown")

	var ctx: Dictionary   = _ctx_for_pos(pos)
	var biome: String     = String(ctx["biome"])
	var z_key: String     = String(ctx["z"])
	var chunk_coords := LoadHandlerSingleton.get_current_chunk_coords()
	var chunk_key := "chunk_%d_%d" % [chunk_coords.x, chunk_coords.y]
	var biome_key: String = String(ctx["biome_key"])

	var vendor_id: String = "%s_%d_%d" % [vendor_type, pos.x, pos.y]

	LoadHandlerSingleton.ensure_vendor_entry_with_loot(
		biome,
		z_key,
		chunk_key,
		biome_key,
		vendor_id,
		vendor_type,
		pos,
		current_datetime
	)

	var player_inv: Dictionary = LoadHandlerSingleton.load_player_inventory_dict()
	var vendor_register: Dictionary = LoadHandlerSingleton.load_vendor_register(biome)
	var vendor_inv: Dictionary = vendor_register[z_key][chunk_key][biome_key][vendor_id]["inventory"]

	_open_trade_inventory(player_inv, vendor_inv, vendor_type, pos, biome, vendor_id)

func try_handle_npc_interaction(pos: Vector2i, npc_chunk: Dictionary) -> void:
	if not npc_chunk.has("npcs"):
		return
	
	for npc_id in npc_chunk["npcs"].keys():
		var npc = npc_chunk["npcs"][npc_id]
		var npc_pos = Vector2i(npc["position"]["x"], npc["position"]["y"])
		if npc_pos == pos:
			handle_npc_interaction(pos, npc)
			return

