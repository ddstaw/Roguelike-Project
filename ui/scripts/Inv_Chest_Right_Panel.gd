extends Panel
#inv_chest
#Container_control/Storage_Panel

const IconBuilder := preload("res://ui/scripts/IconBuilder.gd")
const ITEM_DATA := preload("res://constants/item_data.gd")
const SLOT_SCENE := preload("res://scenes/play/ItemSlot.tscn")

@onready var filter_bar: HBoxContainer   = $LeftVBox/FilterBar  # ✅ This is still correct if LeftVBox is a child of Left_Panel
@onready var sort_bar: HBoxContainer     = get_parent().get_node("SortBar")
@onready var inv_scroll: ScrollContainer = get_parent().get_node("GridFrame/InvScroll")
@onready var inv_grid: GridContainer     = get_parent().get_node("GridFrame/InvScroll/GridPadding/VBoxContainer/InventoryGrid")
@onready var sort_label: Label           = get_parent().get_node("SortBar/SortLabel")
@onready var grid_frame: Panel           = get_parent().get_node("GridFrame")
@export var biome_id: String = "" # For storage_register saves (only needed for "storage" type)
@export var inventory_source_type: String = ""  # "player", "mount", "storage"
@export var storage_id: String = ""   # unique chest ID (ex: "woodchest_4_3")
@export var z_key: String = ""        # which z-level this storage lives in
@export var chunk_key: String = ""    # which chunk this storage lives in
@export var biome_key: String = ""    # biome segment this storage belongs to
@onready var take_all_button: Button = get_parent().get_parent().get_node_or_null("TakeAllButton")
@onready var inv_root := get_parent().get_parent()

var world_pos: Vector2i = Vector2i.ZERO  # optional, track chest position
var _inventory: Dictionary = {}
var _filter: String = "All"
var _sort: String = "NEW"   # keep uppercase normalization
var _filter_group := ButtonGroup.new()
var _sort_group := ButtonGroup.new()
var _icon_cache: Dictionary = {}
var _sort_desc := true      # first click: desc (newest/heaviest/highest first)

# colors/styles (tweak to match your gold/white scheme)
var COLOR_GOLD := Color(0.72, 0.64, 0.29, 1.0)
var COLOR_WHITE := Color.WHITE  # can be const too, but var keeps it consistent
var COLOR_BLACK := Color.BLACK
var COLOR_DIM := Color(0.8, 0.8, 0.8, 1.0)

var _sb_filter_on := StyleBoxFlat.new()
var _sb_filter_off := StyleBoxFlat.new()

# Remember direction per sort key (true=desc ">", false=asc "<")
var _sort_dir_for := {
	"NEW": true,
	"NAME": true,
	"WEIGHT": true,
	"VALUE": true,
}

func _ready():
	await get_tree().process_frame  # Waits one frame
	_setup_scroll()
	var vbar := inv_scroll.get_v_scroll_bar()
	vbar.custom_minimum_size = Vector2(20, 0)  # wider for easy grabbing

	if !_validate_nodes():
		return

	# active filter: gold background + gold border
	_sb_filter_on.bg_color = COLOR_GOLD
	_sb_filter_on.border_color = COLOR_GOLD
	_sb_filter_on.border_width_left = 1
	_sb_filter_on.border_width_top = 1
	_sb_filter_on.border_width_right = 1
	_sb_filter_on.border_width_bottom = 1

	# inactive filter: black background + white border
	_sb_filter_off.bg_color = Color(0, 0, 0, 1)   # solid black
	_sb_filter_off.border_color = Color(1, 1, 1, 1) # white border
	_sb_filter_off.border_width_left = 1
	_sb_filter_off.border_width_top = 1
	_sb_filter_off.border_width_right = 1
	_sb_filter_off.border_width_bottom = 1
	
	_setup_scroll()
	_wire_filter_buttons()
	_wire_sort_buttons()
	_refresh_grid()
	
	# Bring InvScroll above any stray overlays without reparenting:
	inv_scroll.z_as_relative = false
	inv_scroll.z_index = 1000
	
	 # 👇 Wire up the button
	if is_instance_valid(take_all_button):
		take_all_button.pressed.connect(_on_take_all_pressed)
		print("🔗 TakeAllButton wired to Storage_Panel")
	else:
		push_warning("⚠️ TakeAllButton not found from Storage_Panel")
	
func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(inv_scroll):
		return
	
	if event.is_action_pressed("ui_cancel"):
		print("❌ Closing inventory")
		# Hide or free the top-level inventory popup
		get_parent().queue_free()  # <- This removes the entire scene instance

	
	# --- Mouse Wheel Scrolling ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			inv_scroll.scroll_vertical += 64
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			inv_scroll.scroll_vertical -= 64
			accept_event()

	# --- Arrow Key Support ---
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP:
				inv_scroll.scroll_vertical -= 64
				accept_event()
			KEY_DOWN:
				inv_scroll.scroll_vertical += 64
				accept_event()


# --- add this: make sure the nodes exist ---
func _validate_nodes() -> bool:
	var ok := true
	if filter_bar == null: push_error("FilterBar not found at LeftVBox/FilterBar"); ok = false
	if sort_bar == null:   push_error("SortBar not found at /root/Inventory_LocalPlay/SortBar"); ok = false
	if inv_scroll == null: push_error("InvScroll not found at LeftVBox/GridFrame/InvScroll"); ok = false
	if inv_grid == null:   push_error("InventoryGrid not found at LeftVBox/GridFrame/InvScroll/InventoryGrid"); ok = false
	if sort_label == null: push_warning("SortLabel not found (optional).")
	return ok

func _refresh_grid() -> void:
	# --- Debug ---
	print("🔄 Refreshing STORAGE PANEL | keys:", _inventory.keys())

	# Clear old slots
	for c in inv_grid.get_children():
		c.queue_free()

	# Collect stacks to display
	var items := _collect_visible_stacks()
	print("👀 Storage inventory has:", items.size(), "items")

	# Build slots
	for s in items:
		var slot: ItemSlot = SLOT_SCENE.instantiate() as ItemSlot
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		inv_grid.add_child(slot)

		var tex := IconBuilder.get_icon_for_item(s)
		slot.call_deferred("set_data", s, tex)

		# ✅ Wire slot click → appraisal
		slot.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				inv_root.show_appraisal(s)
		)

		# Debug connection info
		print("📛 Attempting to connect to method _on_slot_clicked on:", self.name)
		print("📛 Has method _on_slot_clicked?", self.has_method("_on_slot_clicked"))

		var result := slot.item_clicked.connect(self._on_slot_clicked)
		print("🔌 Connecting Storage_Panel _on_slot_clicked, result:", result)

		# Optional backup listener
		slot.item_clicked.connect(func(attached_slot, shift):
			print("🟢 Storage inline signal:", attached_slot.name, "| shift:", shift)
		)

	# --- Scroll behavior fix ---
	var slot_height: int = 72 + 6
	var columns: int = inv_grid.columns
	var rows: int = ceil(items.size() / float(columns))
	var grid_height: int = rows * slot_height

	inv_grid.size_flags_vertical = Control.SIZE_FILL
	inv_grid.custom_minimum_size = Vector2(0, grid_height)

	inv_grid.queue_sort()
	inv_grid.call_deferred("minimum_size_changed")

	print("Grid height:", inv_grid.get_combined_minimum_size().y)
	print("Scroll viewport height:", inv_scroll.get_size().y)

func _hydrate_inventory(inv: Dictionary) -> Dictionary:
	var new_inv := inv.duplicate(true)
	for k in new_inv.keys():
		var s: Dictionary = new_inv[k]
		if typeof(s) == TYPE_DICTIONARY:
			s["_sort_key"] = _stack_sort_key(s)
	return new_inv


func _setup_scroll() -> void:
	# Scroll modes
	inv_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	inv_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	# ScrollContainer itself must accept input
	inv_scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	inv_scroll.set_focus_mode(Control.FOCUS_ALL)

	# Make the vertical scrollbar interactive
	var vbar := inv_scroll.get_v_scroll_bar()
	vbar.visible = true  # Or false if you want to hide it but still use it
	vbar.mouse_filter = Control.MOUSE_FILTER_STOP
	vbar.set_focus_mode(Control.FOCUS_ALL)

	# Slot spacing
	inv_grid.add_theme_constant_override("h_separation", 6)
	inv_grid.add_theme_constant_override("v_separation", 6)



func _wire_filter_buttons() -> void:
	_filter_group.allow_unpress = false
	var default_set := false
	for n in filter_bar.get_children():
		if n is Button:
			var b := n as Button
			b.toggle_mode = true
			b.button_group = _filter_group

			# Remember base text (like we did for sort buttons, optional)
			if !b.has_meta("base_text"):
				b.set_meta("base_text", b.text.strip_edges())

			b.pressed.connect(func():
				var base := str(b.get_meta("base_text", b.text))
				_filter = _canonical_filter(base)
				_update_filter_visuals()
				_refresh_grid()
			)

			if !default_set and _canonical_filter(b.text) == "ALL":
				b.button_pressed = true
				_filter = "ALL"
				default_set = true

	if !default_set:
		for n in filter_bar.get_children():
			if n is Button:
				(n as Button).button_pressed = true
				_filter = _canonical_filter((n as Button).text)
				break

	_update_filter_visuals()

func _update_filter_visuals() -> void:
	for n in filter_bar.get_children():
		if n is Button:
			var btn := n as Button
			var pressed := btn.button_pressed
			var sb: StyleBox = _sb_filter_on if pressed else _sb_filter_off

			btn.flat = false  # ensure background draws
			btn.add_theme_stylebox_override("normal",  sb)
			btn.add_theme_stylebox_override("hover",   sb)
			btn.add_theme_stylebox_override("pressed", sb)
			btn.add_theme_stylebox_override("focus",   sb)
			btn.add_theme_stylebox_override("disabled", sb)

			var text_col: Color = Color.BLACK if pressed else COLOR_WHITE
			btn.add_theme_color_override("font_color",        text_col)
			btn.add_theme_color_override("font_hover_color",  text_col)
			btn.add_theme_color_override("font_pressed_color",text_col)

func _wire_sort_buttons() -> void:
	_sort_group.allow_unpress = false
	var default_set := false
	if sort_label:
		sort_label.add_theme_color_override("font_color", COLOR_DIM)

	for n in sort_bar.get_children():
		if n is Button:
			var b := n as Button
			b.toggle_mode = true
			b.flat = true
			b.button_group = _sort_group

			# Store canonical label text once (e.g., "New", "Name", "Weight", "Value")
			if !b.has_meta("base_text"):
				b.set_meta("base_text", b.text.strip_edges())

			# Switching to this sort (becomes pressed)
			b.toggled.connect(func(pressed: bool):
				if pressed:
					var base := str(b.get_meta("base_text", b.text)).strip_edges()
					var key := base.to_upper()
					if key != _sort:
						_sort = key
						_sort_desc = bool(_sort_dir_for.get(_sort, true))
						_rebuild_sort_keys_if_needed()
						_update_sort_visuals()
						_update_sort_button_labels()
						_refresh_grid()
			)

			# Pressing an already-active button flips direction
			b.pressed.connect(func():
				var base := str(b.get_meta("base_text", b.text)).strip_edges()
				var key := base.to_upper()
				if key == _sort:
					_sort_desc = not _sort_desc
					_sort_dir_for[_sort] = _sort_desc  # remember for later
					_rebuild_sort_keys_if_needed()
					_update_sort_button_labels()
					_refresh_grid()
			)

			# Default to New >
			if !default_set and str(b.get_meta("base_text", b.text)).strip_edges().to_upper() == "NEW":
				b.button_pressed = true
				_sort = "NEW"
				_sort_desc = true
				_sort_dir_for["NEW"] = true
				default_set = true

	if !default_set:
		for n in sort_bar.get_children():
			if n is Button:
				(n as Button).button_pressed = true
				var base := str((n as Button).get_meta("base_text", (n as Button).text)).strip_edges()
				_sort = base.to_upper()
				_sort_desc = bool(_sort_dir_for.get(_sort, true))
				break

	_update_sort_visuals()
	_update_sort_button_labels()


func _update_sort_visuals() -> void:
	for b in sort_bar.get_children():
		if b is Button:
			var pressed := (b as Button).button_pressed
			var col := COLOR_GOLD if pressed else COLOR_WHITE
			(b as Button).add_theme_color_override("font_color", col)
			(b as Button).add_theme_color_override("font_pressed_color", col)
			(b as Button).add_theme_color_override("font_hover_color", col)


# In Player_Panel.gd


	var items := _collect_visible_stacks()
	print("👀 Storage inventory has:", items.size(), "items")

	for s in items:
		var slot: ItemSlot = SLOT_SCENE.instantiate() as ItemSlot
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		inv_grid.add_child(slot)

		var tex := IconBuilder.get_icon_for_item(s)
		slot.call_deferred("set_data", s, tex)

		var ok := slot.item_clicked.connect(self._on_slot_clicked)
		print("🔌 Connecting Storage_Panel _on_slot_clicked:", ok)

		slot.item_clicked.connect(func(attached_slot, shift):
			print("🟢 Player inline signal:", attached_slot.name, "| shift:", shift)
		)
		inv_grid.queue_sort()
		inv_grid.call_deferred("minimum_size_changed")

	# ... rest unchanged ...

func _on_slot_clicked(slot: ItemSlot, shift: bool) -> void:
	if shift:
		var stack_id: String = slot.stack_id
		var from_inv: Dictionary = _inventory
		var to_panel = get_node("../../Player_Panel")

		if to_panel == null:
			push_warning("❌ Could not find Player_Panel for transfer.")
			return

		var to_inv: Dictionary = to_panel._inventory
		LoadHandlerSingleton.transfer_item(from_inv, to_inv, stack_id)

		_save_inventory()
		to_panel._save_inventory()

		_refresh_grid()
		to_panel._refresh_grid()
		
		var chest_ui = get_parent()
		if chest_ui.has_method("refresh_weight_labels"):
			chest_ui.refresh_weight_labels

func _collect_visible_stacks() -> Array[Dictionary]:
	var arr: Array[Dictionary] = []
	for k in _inventory.keys():
		var s := _inventory[k] as Dictionary
		if _pass_filter(s):
			arr.append(s)

	match _sort:
		"NEW":
			arr.sort_custom(func(a, b):
				var ka := int(a.get("_sort_key", _stack_sort_key(a)))
				var kb := int(b.get("_sort_key", _stack_sort_key(b)))
				return ka > kb if _sort_desc else ka < kb
			)
		"NAME":
			arr.sort_custom(func(a, b):
				var aa := _alpha_key(a)
				var bb := _alpha_key(b)
				if aa == bb:
					# stable tie-breaker (keeps order predictable)
					var ua := str(a.get("unique_ID", ""))
					var ub := str(b.get("unique_ID", ""))
					return ua < ub if _sort_desc == false else ua > ub
				return aa < bb if _sort_desc == false else aa > bb
			)
		"WEIGHT":
			arr.sort_custom(func(a, b):
				var wa := float(a.get("weight", 0.0))
				var wb := float(b.get("weight", 0.0))
				if wa == wb:
					# stable tie-breaker
					var aa := str(a.get("display_name",""))
					var bb := str(b.get("display_name",""))
					return aa < bb if _sort_desc else aa > bb
				return wa > wb if _sort_desc else wa < wb
			)
		"VALUE":
			arr.sort_custom(func(a, b):
				var va := _value_key(a)
				var vb := _value_key(b)
				if va == vb:
					# Stable tie-breaker (uses name; flip with direction to keep UX consistent)
					var aa := str(a.get("display_name", ""))
					var bb := str(b.get("display_name", ""))
					return aa < bb if _sort_desc else aa > bb
				return va > vb if _sort_desc else va < vb
			)
		_:
			# fallback: by unique_ID desc/asc
			arr.sort_custom(func(a, b):
				var ua: Variant = a.get("unique_ID", "")
				var ub: Variant = b.get("unique_ID", "")
				if typeof(ua) == TYPE_INT and typeof(ub) == TYPE_INT:
					return int(ua) > int(ub) if _sort_desc else int(ua) < int(ub)
				var sa := str(ua)
				var sb := str(ub)
				return sa > sb if _sort_desc else sa < sb
			)


	return arr


func _pass_filter(s: Dictionary) -> bool:
	if _filter == "ALL":
		return true

	var id: String = str(s.get("item_ID", ""))
	var t: String  = str(s.get("type", "")).to_upper()  # e.g., "CON", "MAT", "GEAR", "ARM", "LOOT"

	match _filter:
		"GEAR":
			return id.begins_with("GEA") or t == "GEAR"
		"ARM":
			return id.begins_with("ARM") or t == "ARM"
		"CON":
			return id.begins_with("CON") or t == "CON"
		"MATS":
			return id.begins_with("MAT") or t == "MAT"
		"LOOT":
			return id.begins_with("LOOT") or id.begins_with("LUT") or t == "LOOT"
		_:
			return true

func _icon_for(item_id: String) -> Texture2D:
	if _icon_cache.has(item_id):
		return _icon_cache[item_id]

	var def := (ITEM_DATA.ITEM_PROPERTIES.get(item_id, {}) as Dictionary)
	if def.is_empty():
		push_warning("[Icon] No item def for id: " + item_id)
		_icon_cache[item_id] = null
		return null

	var path: String = str(def.get("img_path", ""))
	if path == "":
		push_warning("[Icon] No img_path for id: " + item_id)
		_icon_cache[item_id] = null
		return null

	# Verify the resource actually exists (helps catch typos)
	if !ResourceLoader.exists(path):
		push_warning("[Icon] Resource not found: " + path + " (id=" + item_id + ")")
		_icon_cache[item_id] = null
		return null

	var tex := ResourceLoader.load(path) as Texture2D
	if tex == null:
		push_warning("[Icon] Failed to load Texture2D at: " + path + " (id=" + item_id + ")")

	_icon_cache[item_id] = tex
	return tex

# Build YYYYMMDDHHMM as an integer. Bigger = newer.
func _stack_sort_key(s: Dictionary) -> int:
	var date_str := str(s.get("date", "January 1, 1970")).strip_edges()
	var time_str := str(s.get("time", "12:00 AM")).strip_edges()

	# --- Date: "September 23, 1822"
	var y := 1970
	var m := 1
	var d := 1
	var parts := date_str.replace(",", "").split(" ")
	if parts.size() >= 3:
		m = _month_to_number(parts[0])
		d = int(parts[1])
		y = int(parts[2])

	# --- Time via TimeManager if available; else fallback
	var hh := 0
	var mm := 0
	if has_node("/root/TimeManager"):
		var tm := get_node("/root/TimeManager")
		var mil: String = tm.convert_to_military_time(time_str)  # "0950", "1445", ...
		if mil.length() == 4:
			hh = int(mil.substr(0, 2))
			mm = int(mil.substr(2, 2))
	else:
		var t := time_str.split(" ")
		var hm := (t[0] if t.size() > 0 else "12:00").split(":")
		hh = int(hm[0])
		mm = int(hm[1]) if hm.size() > 1 else 0
		var period := (t[1] if t.size() > 1 else "AM").to_upper()
		if period == "PM" and hh < 12: hh += 12
		if period == "AM" and hh == 12: hh = 0

	# YYYYMMDDHHMM numeric key
	return y * 100000000 + m * 1000000 + d * 10000 + hh * 100 + mm


func _month_to_number(name: String) -> int:
	match name.to_upper():
		"JANUARY": return 1
		"FEBRUARY": return 2
		"MARCH": return 3
		"APRIL": return 4
		"MAY": return 5
		"JUNE": return 6
		"JULY": return 7
		"AUGUST": return 8
		"SEPTEMBER": return 9
		"OCTOBER": return 10
		"NOVEMBER": return 11
		"DECEMBER": return 12
		_: return 1

func _rebuild_sort_keys_if_needed() -> void:
	if _sort == "NEW":
		for k in _inventory.keys():
			var s: Dictionary = _inventory[k]
			s["_sort_key"] = _stack_sort_key(s)

# Helper (optional but tidy)
func _weight_key(s: Dictionary) -> float:
	return float(s.get("weight", 0.0))
	
func _value_key(s: Dictionary) -> int:
	return int(s.get("value", 0))

func _alpha_key(s: Dictionary) -> String:
	return str(s.get("display_name", "")).strip_edges().to_lower()


func _default_dir_for(key: String) -> bool:
	# true = descending (">"), false = ascending ("<")
	match key:
		"NAME":
			return false  # A→Z by default
		_:
			return true   # NEW/WEIGHT/VALUE default to desc

func _update_sort_button_labels() -> void:
	for n in sort_bar.get_children():
		if n is Button:
			var b := n as Button
			var base_text := str(b.get_meta("base_text", b.text)).strip_edges()
			var key := base_text.to_upper()
			var desc := bool(_sort_dir_for.get(key, true))
			var arrow := " >" if desc else " <"
			b.text = base_text + arrow

func _canonical_filter(label: String) -> String:
	var u := label.strip_edges().to_upper()
	match u:
		"ALL": return "ALL"
		"CON", "CONSUMABLES": return "CON"
		"GEAR", "GEAR": return "GEAR"
		"ARM", "ARMOR", "ARMOUR": return "ARM"
		"MAT", "MATS", "MATERIALS": return "MATS"
		"LOOT": return "LOOT"
		_: return u

func _save_inventory() -> void:
	match inventory_source_type:
		"player":
			LoadHandlerSingleton.save_player_inventory(_inventory)

		"mount":
			LoadHandlerSingleton.save_mount_inv(_inventory)

		"storage":
			if biome_id == "" or storage_id == "" or z_key == "" or chunk_key == "" or biome_key == "":
				push_warning("❌ Missing storage context — cannot save storage.")
				return

			LoadHandlerSingleton.update_storage_inventory(
				biome_id,
				z_key,
				chunk_key,
				biome_key,
				storage_id,
				_inventory
			)

		_:
			push_warning("❌ Unknown inventory source type: %s" % inventory_source_type)
	
	var chest_ui := get_parent()
	if chest_ui and chest_ui.has_method("refresh_weight_labels"):
		print("📢 Player_Panel triggered refresh on parent")
		chest_ui.refresh_weight_labels()
		
func set_inventory(inv: Dictionary) -> void:
	_inventory = inv  # reference, not copy

	# ✅ Normalize each stack before sorting/display
	for uid in _inventory.keys():
		LoadHandlerSingleton.normalize_stack_stats(_inventory[uid])

	_rebuild_sort_keys_if_needed()
	_refresh_grid()

func _on_take_all_pressed() -> void:
	print("📥 [Storage_Panel] Take All pressed")

	var root := get_parent().get_parent() # Inventory_chest
	if root == null:
		push_warning("❌ Could not find Inventory_chest root")
		return

	var player_panel := root.get_node_or_null("Player_Panel")
	if player_panel == null:
		push_warning("❌ Player_Panel not found")
		return

	var to_inv: Dictionary = player_panel._inventory
	var keys := _inventory.keys().duplicate()

	print("📦 TakeAll will transfer", keys.size(), "items")

	for stack_id in keys:
		if not _inventory.has(stack_id):
			continue
		print("➡️ Moving stack:", stack_id)
		LoadHandlerSingleton.transfer_item(_inventory, to_inv, stack_id)

	# Save both sides
	_save_inventory()
	player_panel._save_inventory()
	LoadHandlerSingleton.recalc_player_and_mount_weight()

	# Refresh both panels
	_refresh_grid()
	player_panel._refresh_grid()

	if root.has_method("refresh_weight_labels"):
		root.refresh_weight_labels()
