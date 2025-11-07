extends Control
#parent script in res://scenes/play/Inventory_LocalPlay.tscn // attachecd to parent contrl node
# res://scripts/localmapscripts/Inventory_LocalPlay.gd

@onready var player_weight_label := $PlayerInvWeightLabel
@onready var appraisal_panel := $AppraisalPanel
@onready var appraisal_icon := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainerItem/ItemIcon")
@onready var appraisal_name := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/ItemNameLabel")
@onready var appraisal_dura := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DurabilityLabel")
@onready var appraisal_value := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/ValueLabel")
@onready var appraisal_bonus := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/BonusLabel")
@onready var appraisal_description := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DesLabel")
@onready var appraisal_comparetitle := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/CompareTitle")
@onready var appraisal_compare: RichTextLabel = appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/CompareLabel")
@onready var appraisal_dismantletitle := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DismantleTitle")
@onready var appraisal_dismantle := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DismantleLabel")
@onready var appraisal_special: RichTextLabel = appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/SpecialLabel")
#new labels
@onready var appraisal_divine: RichTextLabel = appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DivineLabel")
@onready var appraisal_attspacer := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/AttachmentsSpacer")
@onready var appraisal_atttile := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/AttachmentsTitle")
@onready var appraisal_attlabel: RichTextLabel = appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/AttachmentsLabel")
@onready var appraisal_ammolabel := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/AmmoLabel")
@onready var appraisal_ammocount := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/AmmoCount")
@onready var appraisal_ammospacer := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/AmmoSpacer")
@onready var appraisal_divinespacer := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DivineSpacer")
@onready var appraisal_duraspacer := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DurabilitySpace")

@onready var drag_preview_root := $DragPreviewCanvas/DragPreviewRoot 

@onready var paperdoll_root: Node2D = $PaperdollRoot


@onready var gear_slots := {
	"back": $GearSlotsControl/GearSlot_Back,
	"belt": $GearSlotsControl/GearSlot_Belt,
	"belt_aux": $GearSlotsControl/GearSlot_BeltAux,
	"cloak": $GearSlotsControl/GearSlot_Cloak,
	"cross_chest": $GearSlotsControl/GearSlot_CrossChest,
	"face": $GearSlotsControl/GearSlot_Face,
	"gloves": $GearSlotsControl/GearSlot_Gloves,
	"head": $GearSlotsControl/GearSlot_Head,
	"left_hand": $GearSlotsControl/GearSlot_LeftHand,
	"left_hand_ammo": $GearSlotsControl/GearSlot_LeftHandAmmo,
	"overcoat": $GearSlotsControl/GearSlot_Overcoat,
	"pack": $GearSlotsControl/GearSlot_Pack,
	"pack_mod_slot": $GearSlotsControl/GearSlot_PackModSlot,
	"pants": $GearSlotsControl/GearSlot_Pants,
	"right_hand": $GearSlotsControl/GearSlot_RightHand,
	"right_hand_ammo": $GearSlotsControl/GearSlot_RightHandAmmo,
	"ring_1": $GearSlotsControl/GearSlot_Ring1,
	"ring_2": $GearSlotsControl/GearSlot_Ring2,
	"shoes": $GearSlotsControl/GearSlot_Shoes,
	"shoulders": $GearSlotsControl/GearSlot_Shoulders,
	"undershirt": $GearSlotsControl/GearSlot_Undershirt,
}


const EMPTY_GEAR_ICONS := {
	"back": preload("res://assets/ui/back_slot.png"),
	"belt": preload("res://assets/ui/belt_slot.png"),
	"belt_aux": preload("res://assets/ui/beltaux_slot.png"),
	"cloak": preload("res://assets/ui/cloak_slot.png"),
	"cross_chest": preload("res://assets/ui/cross_chest_slot.png"),
	"face": preload("res://assets/ui/face_slot.png"),
	"gloves": preload("res://assets/ui/gloves_slot.png"),
	"head": preload("res://assets/ui/head_slot.png"),
	"left_hand": preload("res://assets/ui/left_hand_slot.png"),
	"left_hand_ammo": preload("res://assets/ui/ammo_slot.png"),
	"overcoat": preload("res://assets/ui/overcoat_slot.png"),
	"pack": preload("res://assets/ui/backpack_slot.png"),
	"pack_mod_slot": preload("res://assets/ui/backpackaux_slot.png"),
	"pants": preload("res://assets/ui/pants_slot.png"),
	"right_hand": preload("res://assets/ui/right_hand_slot.png"),
	"right_hand_ammo": preload("res://assets/ui/ammo_slot.png"),
	"ring_1": preload("res://assets/ui/ring_slot.png"),
	"ring_2": preload("res://assets/ui/ring_slot.png"),
	"shoes": preload("res://assets/ui/shoes_slot.png"),
	"shoulders": preload("res://assets/ui/shoulders_slot.png"),
	"undershirt": preload("res://assets/ui/undershirt_slot.png"),
}


const IconBuilder := preload("res://ui/scripts/IconBuilder.gd")
const TAG_INFO = preload("res://constants/tag_info.gd")
const ITEM_DATA := preload("res://constants/item_data.gd")
const WORLD_SCENE := "res://scenes/play/WorldMapTravel.tscn"
const LOCAL_SCENE := "res://scenes/play/LocalMap.tscn"

var _currently_appraised_id: String = ""

var _closing := false  # simple debounce so we don't double-trigger

var equipped_data: Dictionary = {}  # Holds UID per gear slot

var player_inventory: Dictionary = {}


func _ready() -> void:
	appraisal_panel.visible = false  # 👈 hide initially
	_update_weight_label()  # 👈 add this
	player_inventory = LoadHandlerSingleton.load_player_inventory()
	equipped_data = LoadHandlerSingleton.load_player_gear()
	_update_gear_slots()
	_spawn_player_paperdoll()

	
func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_inventory"):
		accept_event()
		_closing = true
		_return_to_current_realm_scene()

func _return_to_current_realm_scene() -> void:
	var data: Dictionary = LoadHandlerSingleton.load_char_state()
	var cs: Dictionary = (data.get("character_state", {}) as Dictionary)

	var in_city: bool = (cs.get("incity", "N") as String) == "Y"
	var in_local: bool = (cs.get("inlocalmap", "N") as String) == "Y"
	var in_world: bool = (cs.get("inworldmap", "N") as String) == "Y"

	var target: String = LOCAL_SCENE if in_local else WORLD_SCENE

	if in_local:
		# ✅ 1. Try to get live in-memory values first
		var mem_grid := Vector2i(-1, -1)
		var mem_z := 0
		if LoadHandlerSingleton.has_method("get_current_local_grid_pos"):
			mem_grid = LoadHandlerSingleton.get_current_local_grid_pos()
		if LoadHandlerSingleton.has_method("get_current_z_level_mem"):
			mem_z = LoadHandlerSingleton.get_current_z_level_mem()

		# ✅ 2. Fallback to JSON if memory is uninitialized
		if mem_grid == Vector2i(-1, -1):
			var lm_place := LoadHandlerSingleton.load_temp_localmap_placement()
			var lm_dict: Dictionary = lm_place.get("local_map", {}) as Dictionary
			var grid_dict: Dictionary = lm_dict.get("grid_position_local", {}) as Dictionary
			mem_grid = Vector2i(int(grid_dict.get("x", 0)), int(grid_dict.get("y", 0)))
			mem_z = int(str(lm_dict.get("z_level", "0")))

		# ✅ 3. Now write those confirmed values back into both placement files
		var lm_place := LoadHandlerSingleton.load_temp_localmap_placement()
		if not lm_place.has("local_map"):
			lm_place["local_map"] = {}
		lm_place["local_map"]["grid_position_local"] = {"x": mem_grid.x, "y": mem_grid.y}
		lm_place["local_map"]["z_level"] = str(mem_z)
		lm_place["local_map"]["spawn_pos"] = {"x": mem_grid.x, "y": mem_grid.y}
		LoadHandlerSingleton.save_temp_placement(lm_place)

		var gen_place := LoadHandlerSingleton.load_temp_placement()
		if not gen_place.has("local_map"):
			gen_place["local_map"] = {}
		gen_place["local_map"]["grid_position_local"] = {"x": mem_grid.x, "y": mem_grid.y}
		gen_place["local_map"]["z_level"] = str(mem_z)
		gen_place["local_map"]["spawn_pos"] = {"x": mem_grid.x, "y": mem_grid.y}
		LoadHandlerSingleton.save_temp_placement(gen_place)

		# ✅ 4. Make sure memory cache matches (safety sync)
		LoadHandlerSingleton.set_current_local_grid_pos(mem_grid)
		LoadHandlerSingleton.set_current_z_level(mem_z)

		print("💾 Synced live grid:", mem_grid, "z:", mem_z)

	print("⬅️ Returning to:", target)
	get_tree().paused = false
	_closing = true
	get_tree().change_scene_to_file(target)

func _update_weight_label() -> void:
	var stats: Dictionary = LoadHandlerSingleton.load_player_weight().get("weight_stats", {})

	var cur := float(stats.get("current_carry_weight", {}).get("value", 0.0))
	var max := int(stats.get("max_carry_weight", {}).get("value", 0))
	var info := StatusManager.get_carry_status(cur, max)

	player_weight_label.text = info["text"]
	player_weight_label.add_theme_color_override("font_color", info["color"])
	player_weight_label.visible = true
	
func show_appraisal(s: Dictionary) -> void:
	if s.is_empty():
		appraisal_panel.visible = false
		_currently_appraised_id = ""
		return

	var new_id := str(s.get("unique_ID", ""))

	# 👇 Check if we're clicking the same item again
	if appraisal_panel.visible and new_id == _currently_appraised_id:
		appraisal_panel.visible = false
		_currently_appraised_id = ""
		return  # cancel out — hide instead

	# 👇 Continue showing new appraisal
	_currently_appraised_id = new_id
	appraisal_panel.visible = true

		# unified icon generation
	var tex: Texture2D = IconBuilder.get_icon_for_item(s)
	appraisal_icon.texture = tex

	# ✅ Basic stats
	appraisal_name.text = s.get("display_name", s.get("base_display_name", "Unknown Item"))
	var item_type = str(s.get("type", "")).to_upper()

	# ✅ Durability
	var has_durability = item_type in ["GEAR", "TOOL", "ARM"]
	
	if has_durability and s.has("current_dura") and s.has("max_dura"):
		var cur_dur: int = int(s["current_dura"])
		var max_dur: int = int(s["max_dura"])
		var ratio: float = float(cur_dur) / float(max_dur)

		var condition_text := ""
		if ratio < 0.01:
			condition_text = "Broken"
		elif ratio < 0.30:
			condition_text = "Miserable Condition"
		elif ratio < 0.50:
			condition_text = "Poor Condition"
		elif ratio < 0.70:
			condition_text = "Fair Condition"
		else:
			condition_text = "Good Condition"

		appraisal_dura.text = "%s %d/%d" % [condition_text, cur_dur, max_dur]
		appraisal_dura.visible = true
		appraisal_duraspacer.visible = true
	else:
		appraisal_dura.visible = false
		appraisal_duraspacer.visible = false


	# ✅ Value
	var value = s.get("value", s.get("avg_value_per", 0))
	appraisal_value.text = "Value: %d" % value
	appraisal_value.visible = value > 0

	# ✅ Bonuses
	var bonuses := []

	match item_type:
		"GEAR":
			var tags: Array = s.get("tags", [])
			if "firearm" in tags:
				if s.has("rng_dmg"):
					var dmg_arr: Array = s.get("rng_dmg", [0, 0])
					var dmg: Vector2i = Vector2i(dmg_arr[0], dmg_arr[1])
					bonuses.append("Ranged Dmg: %d–%d" % [dmg.x, dmg.y])
				if s.has("rng_acc"):
					bonuses.append("Accuracy: %d" % s["rng_acc"])
				if s.has("eff_rg"):
					bonuses.append("Effective Range: %d" % s["eff_rg"])
				if s.has("floor_noise_per_shot"):
					bonuses.append("Sound Profile: %d Noise" % s["floor_noise_per_shot"])
			else:
				if s.has("melee_dmg"):
					bonuses.append("+%s Melee Dmg" % s["melee_dmg"])
				if s.has("ranged_dmg"):
					bonuses.append("+%s Ranged Dmg" % s["ranged_dmg"])
				if s.has("accuracy"):
					bonuses.append("+%s Accuracy" % s["accuracy"])

		"ARM":
			if s.has("def_bonus"):
				bonuses.append("+%s Def" % s["def_bonus"])
			if s.has("dex_bonus"):
				bonuses.append("%+s Dex" % s["dex_bonus"])

		"CON":
			if s.get("can_eat", false):
				bonuses.append("+%s Nutrition" % s.get("food_qty", 0))
			if s.get("med_bleeding", false):
				bonuses.append("Stops Bleeding")
			if s.get("med_general", false):
				bonuses.append("Heals %s Wounds" % s.get("med_general_qty", 0))

		"LOOT", "UTIL":
			if s.get("readable", false):
				bonuses.append("Readable")

	appraisal_bonus.text = String("\n").join(bonuses) if bonuses.size() > 0 else "No special bonuses"
	appraisal_bonus.visible = bonuses.size() > 0
	appraisal_duraspacer.visible = true
	
	# ✅ Ammo Info – loaded / capacity format
	if item_type == "GEAR" and "firearm" in s.get("tags", []):
		var ammo_type: String = s.get("ammo_type", "Unknown")
		var ammo_load: int = s.get("ammo_load", 0)
		var ammo_cap: int = s.get("ammo_cap", 0)

		var ammo_text := "Ammo: %s (%d/%d)" % [ammo_type, ammo_load, ammo_cap]
		appraisal_ammolabel.text = ammo_text
		appraisal_ammolabel.visible = true
		appraisal_ammocount.visible = false  # Hide separate count field
	else:
		appraisal_ammolabel.visible = false
		appraisal_ammocount.visible = false
		appraisal_ammospacer.visible = false


	# ✅ Attachments from item data
	var mods := []
	if s.has("attachments") and s["attachments"] is Array:
		for mod in s["attachments"]:
			mods.append(str(mod)) 

	appraisal_atttile.visible = mods.size() > 0
	appraisal_attlabel.visible = mods.size() > 0
	appraisal_attspacer.visible = mods.size() > 0
	if mods.size() > 0:
		appraisal_attlabel.text = "%s" % ", ".join(mods)

	# ✅ Faith Status (Consecrated / Defiled)
	if s.has("faith_status"):
		var status: String = s["faith_status"]
		match status:
			"Consecrated":
				appraisal_divine.bbcode_enabled = true
				appraisal_divine.text = "[color=blue]Consecrated[/color]"
				appraisal_divine.visible = true
			"Defiled":
				appraisal_divine.bbcode_enabled = true
				appraisal_divine.text = "[color=red]Defiled[/color]"
				appraisal_divine.visible = true
			_:
				appraisal_divine.visible = false
				appraisal_divinespacer.visible = false
	else:
		appraisal_divine.visible = false
	
	# ✅ Description
	appraisal_description.text = str(s.get("des", ""))

	if item_type in ["GEAR", "ARM"]:
		var compare_parts := [
			"[color=green]Ranged Damage +[/color]",
			"[color=green]Effective Range +[/color]",
			"[color=red]Noise Production -[/color]"
		]

		appraisal_compare.bbcode_enabled = true
		appraisal_compare.text = ", ".join(compare_parts)
		appraisal_compare.visible = true
		appraisal_comparetitle.visible = true
	else:
		appraisal_compare.visible = false
		appraisal_comparetitle.visible = false


	# ✅ Dismantle
	if s.has("materials") and s["materials"] is Array and s["materials"].size() > 0:
		var mat_list: Array = s["materials"]
		var dismantle_text := "%s" % ", ".join(mat_list)

		appraisal_dismantle.text = dismantle_text
		appraisal_dismantle.visible = true
		appraisal_dismantletitle.visible = true
	else:
		appraisal_dismantle.visible = false
		appraisal_dismantletitle.visible = false


	# ✅ Tags
	var tag_lines := []
	var tags: Array = s.get("tags", [])
	for tag in tags:
		if TAG_INFO.SPECIAL_TAG_INFO.has(tag):
			var info = TAG_INFO.SPECIAL_TAG_INFO[tag]
			tag_lines.append("[color=%s]%s[/color]" % [info["color"].to_html(), info["text"]])

	appraisal_special.bbcode_enabled = true
	appraisal_special.text = "\n".join(tag_lines)
	appraisal_special.visible = tag_lines.size() > 0


			
func hide_appraisal() -> void:
	appraisal_panel.visible = false


func _update_gear_slots():
	for slot_name in gear_slots.keys():
		var slot: ItemSlot = gear_slots[slot_name]
		var uid: String = equipped_data.get(slot_name, "empty")

		if uid != "empty" and player_inventory.has(uid):
			var item_data: Dictionary = player_inventory[uid]
			var icon: Texture2D = IconBuilder.get_icon_for_item(item_data)
			slot.set_data(item_data, icon)
		else:
			var empty_icon = EMPTY_GEAR_ICONS.get(slot_name, null)
			slot.set_data({}, empty_icon)


func handle_gear_slot_drop(target_slot: ItemSlot, data: Dictionary) -> void:
	var uid = str(data.get("unique_ID", ""))
	if !player_inventory.has(uid):
		return

	# Determine gear slot name from target
	var slot_name = gear_slots.find_key(target_slot)
	if slot_name == null:
		return

	# TODO: Validate item can be equipped in this slot (optional)

	equipped_data[slot_name] = uid
	_update_gear_slots()

func handle_gear_slot_right_click(target_slot: GearSlot) -> void:
	var slot_name = gear_slots.find_key(target_slot)
	if slot_name == null:
		return

	var uid = equipped_data.get(slot_name, "empty")
	if uid == "empty":
		return

	equipped_data[slot_name] = "empty"
	LoadHandlerSingleton.save_player_gear(equipped_data)  # 👈 persist the change
	_update_gear_slots()

func handle_gear_slot_equip(target_slot: GearSlot, uid: String) -> void:
	var slot_name = gear_slots.find_key(target_slot)
	if slot_name == null:
		return

	# Make sure the item exists in the inventory
	if not player_inventory.has(uid):
		print("❌ UID not found in player inventory:", uid)
		return

	equipped_data[slot_name] = uid
	LoadHandlerSingleton.save_player_gear(equipped_data)  # ✅ Save change
	_update_gear_slots()
	print("✅ Equipped", uid, "to slot", slot_name)

func _spawn_player_paperdoll():
	var player_scene = preload("res://scenes/actors/PlayerPaperdoll.tscn")
	var paperdoll_instance = player_scene.instantiate()
	
	var camera := paperdoll_instance.get_node_or_null("Camera2D")
	if camera:
		camera.enabled = false
	
	# Optionally scale up
	paperdoll_instance.scale = Vector2(3, 3)

	# Position it centered in the paperdoll area
	paperdoll_instance.position = Vector2(100, 100)  # tweak for visual centering

	# Strip off unnecessary functionality if needed (movement, input, FOV, etc.)
	paperdoll_instance.set_process(false)
	paperdoll_instance.set_physics_process(false)

	# Apply current looks
	var looks = LoadHandlerSingleton.load_player_looks()
	if looks:
		paperdoll_instance.apply_appearance(looks)

	paperdoll_root.add_child(paperdoll_instance)
