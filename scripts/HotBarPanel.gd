# res://scripts/HotBarPanel.gd
extends Panel

const ITEM_DATA := preload("res://constants/item_data.gd")
const EMPTY_SLOT_ICON := preload("res://assets/ui/empty_hotbar_slot.png")

@onready var hotbar_slots := [
	$HotbarSlots/HotbarSlot1,
	$HotbarSlots/HotbarSlot2,
	$HotbarSlots/HotbarSlot3,
	$HotbarSlots/HotbarSlot4,
	$HotbarSlots/HotbarSlot5,
	$HotbarSlots/HotbarSlot6,
	$HotbarSlots/HotbarSlot7,
	$HotbarSlots/HotbarSlot8,
	$HotbarSlots/HotbarSlot9,
]

@onready var hotbar_label: Label = $HotbarLabel
@onready var hotbar_up_btn: TextureButton = $HotbarUpBtn
@onready var hotbar_down_btn: TextureButton = $HotbarDownBtn


var hotbar_data: Dictionary
var player_inventory: Dictionary
var current_hotbar_id: int = 1
var _icon_cache: Dictionary = {}


func _ready():
	print("🔷 HotBarPanel _ready at path:", get_path())
	_load_hotbar_data()
	_update_hotbar_slots()
	
	# 🔁 Hook up signal to auto-refresh hotbar when inventory changes
	if LoadHandlerSingleton.has_signal("inventory_changed"):
		print("🔷 HotBarPanel sees inventory_changed signal, connecting…")
		LoadHandlerSingleton.inventory_changed.connect(refresh_from_storage)
		
	hotbar_up_btn.pressed.connect(_next_hotbar)
	hotbar_down_btn.pressed.connect(_prev_hotbar)
	

func _load_hotbar_data():
	hotbar_data = LoadHandlerSingleton.load_player_hotbar()
	player_inventory = LoadHandlerSingleton.load_player_inventory_dict()
	current_hotbar_id = int(hotbar_data.get("current_hotbar", 1))

func _update_hotbar_slots():
	var hotbars: Array = hotbar_data.get("hotbars", [])
	var hotbar: Dictionary = hotbars.filter(func(h): return h["id"] == current_hotbar_id).front()
	var slot_ids: Array = hotbar.get("slots", [])

	hotbar_label.text = str(current_hotbar_id)

	for i in range(hotbar_slots.size()):
		var slot: ItemSlot = hotbar_slots[i]
		var uid = slot_ids[i] if i < slot_ids.size() else null

		if uid == null or !player_inventory.has(uid):
			slot.set_data({}, EMPTY_SLOT_ICON)  # Show empty placeholder
		else:
			var item_data: Dictionary = player_inventory[uid]
			var icon: Texture2D = _get_icon_for(item_data)
			slot.set_data(item_data, icon)


func _get_icon_for(item: Dictionary) -> Texture2D:
	var uid := str(item.get("unique_ID", ""))
	if !_icon_cache.has(uid):
		var tex: Texture2D = null

		if item.has("img_layers"):
			var layers := item["img_layers"] as Array
			tex = _generate_layered_icon(layers)
		else:
			var def: Dictionary = ITEM_DATA.ITEM_PROPERTIES.get(str(item.get("item_ID", "")), {})
			var fallback: String = str(def.get("img_path", ""))
			if fallback != "" and ResourceLoader.exists(fallback):
				tex = ResourceLoader.load(fallback) as Texture2D

		_icon_cache[uid] = tex
	return _icon_cache.get(uid, null)


func _generate_layered_icon(layer_paths: Array) -> Texture2D:
	if layer_paths.is_empty():
		return null

	var base_image: Image = null

	for i in range(layer_paths.size()):
		var path: String = layer_paths[i]
		if !ResourceLoader.exists(path):
			push_warning("Missing layer path: %s" % path)
			continue

		var tex := ResourceLoader.load(path) as Texture2D
		if tex == null:
			continue

		var img: Image = tex.get_image()
		if base_image == null:
			base_image = img.duplicate()
			continue

		var is_overlay: bool = path.to_lower().find("overlay") != -1

		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var base_col := base_image.get_pixel(x, y)
				var layer_col := img.get_pixel(x, y)

				var final_col: Color = base_col

				if is_overlay:
					final_col.r = clamp(base_col.r + layer_col.r * layer_col.a, 0.0, 1.0)
					final_col.g = clamp(base_col.g + layer_col.g * layer_col.a, 0.0, 1.0)
					final_col.b = clamp(base_col.b + layer_col.b * layer_col.a, 0.0, 1.0)
					final_col.a = max(base_col.a, layer_col.a)
				else:
					final_col = layer_col.blend(base_col)

				base_image.set_pixel(x, y, final_col)

	var final_tex := ImageTexture.create_from_image(base_image)
	return final_tex
	
func _next_hotbar():
	var ids := _get_sorted_hotbar_ids()
	if ids.is_empty():
		push_error("No hotbar IDs found")
		return

	var index := ids.find(current_hotbar_id)
	if index == -1:
		current_hotbar_id = ids[0]  # fallback to first
	else:
		current_hotbar_id = ids[(index + 1) % ids.size()]  # wrap forward

	hotbar_data["current_hotbar"] = current_hotbar_id
	LoadHandlerSingleton.save_player_hotbar(hotbar_data)
	_update_hotbar_slots()


func _prev_hotbar():
	var ids := _get_sorted_hotbar_ids()
	if ids.is_empty():
		push_error("No hotbar IDs found")
		return

	var index := ids.find(current_hotbar_id)
	if index == -1:
		current_hotbar_id = ids[0]  # fallback to first
	else:
		current_hotbar_id = ids[(index - 1 + ids.size()) % ids.size()]  # wrap backward

	hotbar_data["current_hotbar"] = current_hotbar_id
	LoadHandlerSingleton.save_player_hotbar(hotbar_data)
	_update_hotbar_slots()



func _get_sorted_hotbar_ids() -> Array:
	var ids: Array = []
	var hotbars = hotbar_data.get("hotbars", [])
	
	for h in hotbars:
		var id = h.get("id", null)
		if id == null:
			continue
		# Convert whatever type to int
		id = int(id)
		if !ids.has(id):
			ids.append(id)
	
	ids.sort()
	return ids
func handle_slot_drop(target_slot: ItemSlot, data: Dictionary) -> void:
	if data.get("type", "") != "action" or data.get("action_type", "") != "item":
		return

	var uid: String = str(data.get("unique_ID", ""))
	if uid == "" or !player_inventory.has(uid):
		push_warning("Invalid UID or not found in player inventory: %s" % uid)
		return

	# Find slot index being dropped onto
	var index := hotbar_slots.find(target_slot)
	if index == -1:
		push_warning("Slot not found in hotbar_slots array")
		return

	# Update the current hotbar's data
	for h in hotbar_data.get("hotbars", []):
		if int(h.get("id", -1)) == current_hotbar_id:
			var slots: Array = h.get("slots", [])

			# Remove any existing instance of this UID in the hotbar
			for i in range(slots.size()):
				if slots[i] == uid:
					slots[i] = null  # clear previous assignment
					break

			# Set the new slot index to the UID
			if index < slots.size():
				slots[index] = uid

			break  # done with this hotbar

	# Save and refresh
	hotbar_data["current_hotbar"] = current_hotbar_id
	LoadHandlerSingleton.save_player_hotbar(hotbar_data)
	_update_hotbar_slots()

func refresh_from_storage():
	print("🔁 HotBarPanel received inventory_changed → refreshing from storage.")
	hotbar_data = LoadHandlerSingleton.load_player_hotbar()
	player_inventory = LoadHandlerSingleton.load_player_inventory_dict()
	_update_hotbar_slots()
