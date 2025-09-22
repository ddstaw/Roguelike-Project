extends Panel
#nodelootcontainer
#this script is attached to NodeTransferWindow/PanelContainer, child of parent NodeTransferWindow (control), 
#which itself is a child of parent Inventory_mini

@onready var loot_grid: GridContainer = get_node("ScrollContainer/MarginContainer/VBoxContainer/GridContainer")
@onready var header_label: Label = get_parent().get_node("Label")
@export var biome_id: String = ""
@export var node_id: String = ""
@export var z_key: String = ""
@export var chunk_key: String = ""
@export var biome_key: String = ""
@onready var inv_root := get_tree().root.get_node_or_null("LocalMap/UILayer/Inventory_mini")



const SLOT_SCENE := preload("res://scenes/play/ItemSlot.tscn")
const ITEM_DATA := preload("res://constants/item_data.gd")

# --- Data refs ---
var _wrapped_node_dict: Dictionary = {}  # the full node entry (with "inventory", last_looted, etc.)
var node_inventory: Dictionary = {}      # reference to wrapped["inventory"]
var _inventory: Dictionary = {}          # alias to node_inventory (same reference)
var player_inventory: Dictionary = {}
var take_all_button: Button

func _ready():
	print("✅ NodeTransferWindow ready")
	await get_tree().process_frame  # wait until children are ready
	_refresh_grid()
	take_all_button = get_node("../TakeAllButton")
	header_label = get_node("../Label")

	if is_instance_valid(take_all_button):
		print("🔗 Found TakeAllButton at:", take_all_button.get_path())
		take_all_button.pressed.connect(_on_take_all_pressed)
	else:
		push_warning("⚠️ TakeAllButton not found at ../TakeAllButton")

func set_context(biome: String, z: String, chunk: String, biome_key: String, id: String) -> void:
	biome_id = biome
	z_key = z
	chunk_key = chunk
	self.biome_key = biome_key
	node_id = id

	
func set_data(
	node_data: Dictionary,
	player_inv: Dictionary,
	node_type := "",
	biome := "",
	z_key := "",
	chunk_key := "",
	biome_key := "",
	node_id := ""
) -> void:
	# Store context for saving later
	self.biome_id = biome
	self.z_key = z_key
	self.chunk_key = chunk_key
	self.biome_key = biome_key
	self.node_id = node_id

	# Extract node inventory
	node_inventory = node_data.get("inventory", {})
	_inventory = node_inventory  # alias for display

	# Player inv reference
	player_inventory = player_inv

	# Header label
	if has_node("../Label"):
		var label = get_node("../Label") as Label
		match node_type.to_lower():
			"bush":    label.text = "Looting Bush"
			"tree":    label.text = "Looting Tree"
			"flowers": label.text = "Looting Flowers"
			_:         label.text = "Looting"

	print("📌set_data| biome:%s z:%s chunk:%s biome_key:%s node_id:%s"
		  % [biome, z_key, chunk_key, biome_key, node_id])
	_render_loot()

	
func _render_loot() -> void:
	print("PINGPONG 🧪 Rendering node inventory... Total items:", node_inventory.size())
	for c in loot_grid.get_children():
		c.queue_free()

	for key in node_inventory.keys():
		var item: Dictionary = node_inventory[key]
		var slot = SLOT_SCENE.instantiate()
		var tex = _icon_for(str(item.get("item_ID","")))
		slot.set_data(item, tex)
		loot_grid.add_child(slot)
		slot.item_clicked.connect(self._on_slot_clicked)
		
func _icon_for(item_id: String) -> Texture2D:
	var def: Dictionary = ITEM_DATA.ITEM_PROPERTIES.get(item_id, {}) as Dictionary
	var path: String = def.get("img_path", "")
	if path == "" or !ResourceLoader.exists(path):
		return null
	return load(path) as Texture2D

func _on_slot_clicked(slot: ItemSlot, shift: bool) -> void:
	if not shift:
		return

	var stack_id := slot.stack_id
	print("🖱️ Node slot clicked:", stack_id, " shift:", shift)

	# Transfer FROM node (_inventory) TO player
	var player_panel := get_node_or_null("../../Left_Panel")
	if player_panel == null:
		push_warning("⚠️ Could not find Left_Panel (player inventory).")
		return

	var to_inv: Dictionary = player_panel._inventory

	# This mutates _inventory (== node_inventory)
	LoadHandlerSingleton.transfer_item(_inventory, to_inv, stack_id)

	# Now persist both sides
	_save_node_inventory()
	player_panel._save_inventory()
	
	LoadHandlerSingleton.recalc_player_and_mount_weight()
	
	_refresh_grid()
	player_panel._refresh_grid()
	
	# Then refresh UI
	var mini_ui := get_tree().root.get_node_or_null("LocalMap/UILayer/Inventory_mini")
	if mini_ui and mini_ui.has_method("refresh_weight_labels"):
		mini_ui.call_deferred("refresh_weight_labels")
	
func _save_node_inventory() -> void:
	# Hard logs so we SEE when we save, and with what.
	_print_ctx("_save_node_inventory (before)")
	print("   • node_inventory keys:", node_inventory.keys())

	if biome_id == "" or node_id == "" or z_key == "" or chunk_key == "" or biome_key == "":
		push_warning("❌ Missing node context — cannot save node inventory.")
		return

	# Persist the flat dict into the register’s "inventory" field
	LoadHandlerSingleton.update_node_inventory(
		biome_id,
		z_key,
		chunk_key,
		biome_key,
		node_id,
		node_inventory
	)

	_print_ctx("_save_node_inventory (after)")

func _print_ctx(where: String) -> void:
	print("📌", where, "| biome:", biome_id, " z:", z_key, " chunk:", chunk_key, " biome_key:", biome_key, " node_id:", node_id)


func _save_inventory() -> void:
	if biome_id == "" or node_id == "" or z_key == "" or chunk_key == "" or biome_key == "":
		push_warning("❌ Missing node context — cannot save node inventory.")
		return

	LoadHandlerSingleton.update_node_inventory(
		biome_id,
		z_key,
		chunk_key,
		biome_key,
		node_id,
		node_inventory  # ✅ flat dict, not wrapped
	)

func set_inventory(inv: Dictionary) -> void:
	_wrapped_node_dict = inv  # ✅ preserve full context
	_inventory = inv["inventory"] if inv.has("inventory") else inv
	node_inventory = _inventory

	# ✅ Normalize inventory stacks
	for uid in _inventory.keys():
		LoadHandlerSingleton.normalize_stack_stats(_inventory[uid])

	_refresh_grid()

	
func _refresh_grid() -> void:
	print("🔄 [NodeTransfer] Refresh grid with keys:", node_inventory.keys())
	for c in loot_grid.get_children():
		c.queue_free()

	# --- Force node grid to 3 columns ---
	loot_grid.columns = 3

	for key in node_inventory.keys():
		var item: Dictionary = node_inventory[key]
		var slot = SLOT_SCENE.instantiate()
		var tex = _icon_for(str(item.get("item_ID","")))
		slot.set_data(item, tex)
		loot_grid.add_child(slot)

		# ✅ Appraisal on click
		slot.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if inv_root and inv_root.has_method("show_appraisal"):
					inv_root.show_appraisal(item)
		)

		# 🔁 Transfer handling
		slot.item_clicked.connect(self._on_slot_clicked)

	# Optional: auto-resize loot grid height
	var slot_height: int = 72 + 6
	var rows: int = ceil(node_inventory.size() / float(loot_grid.columns))
	var grid_height: int = rows * slot_height
	loot_grid.custom_minimum_size = Vector2(0, grid_height)

	# Refresh weight label (unchanged)
	var mini_ui := get_tree().root.get_node_or_null("LocalMap/UILayer/Inventory_mini")
	if mini_ui and mini_ui.has_method("refresh_weight_labels"):
		mini_ui.refresh_weight_labels()


func _on_take_all_pressed() -> void:
	print("📥 Take All pressed")

	var player_panel := get_node_or_null("../../Left_Panel")
	if player_panel == null:
		push_warning("⚠️ Left_Panel not found for take-all")
		return

	var to_inv: Dictionary = player_panel._inventory
	var keys := node_inventory.keys()

	for stack_id in keys:
		if not node_inventory.has(stack_id):
			continue  # safety check
		LoadHandlerSingleton.transfer_item(node_inventory, to_inv, stack_id)

	# Save both sides
	_save_node_inventory()
	player_panel._save_inventory()

	LoadHandlerSingleton.recalc_player_and_mount_weight()

	# Refresh both panels
	_refresh_grid()
	player_panel._refresh_grid()
	
	# Then refresh UI
	var mini_ui := get_tree().root.get_node_or_null("LocalMap/UILayer/Inventory_mini")
	if mini_ui and mini_ui.has_method("refresh_weight_labels"):
		mini_ui.call_deferred("refresh_weight_labels")
