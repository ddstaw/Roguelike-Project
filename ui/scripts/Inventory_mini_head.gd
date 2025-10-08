# res://ui/scenes/Inventory_mini.tscn parent control node script
extends Control

@onready var player_panel := $Left_Panel
@onready var player_weight_label := $PlayerInvWeightLabel
@onready var appraisal_panel := $AppraisalPanel
@onready var appraisal_icon := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainerItem/ItemIcon")
@onready var appraisal_name := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/ItemNameLabel")
@onready var appraisal_dura := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DurabilityLabel")
@onready var appraisal_value := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/ValueLabel")
@onready var appraisal_bonus := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/BonusLabel")
@onready var appraisal_description := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DesLabel")
@onready var appraisal_comparetitle := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/CompareTitle")
@onready var appraisal_compare := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/CompareLabel")
@onready var appraisal_dismantle := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DismantleLabel")
@onready var appraisal_special: RichTextLabel = appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/SpecialLabel")
@onready var appraisal_dismantletitle := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DismantleTitle")

const ITEM_DATA := preload("res://constants/item_data.gd")
const TAG_INFO = preload("res://constants/tag_info.gd")

func _ready():
	get_tree().paused = true
	refresh_weight_labels()
	set_process_unhandled_input(true)
	appraisal_panel.visible = false  # 👈 hide initially

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_close_ui()

func _close_ui():
	get_tree().paused = false
	queue_free()

func refresh_weight_labels():
	print("🔄 Refresh weight labels (mini)")
	_update_weight_labels_deferred()

# Defer so we pull updated stats after transfer/save
func _update_weight_labels_deferred() -> void:
	await get_tree().process_frame
	_update_weight_labels()

func _update_weight_labels():
	var stats: Dictionary = LoadHandlerSingleton.load_player_weight().get("weight_stats", {})
	print("🐛 Raw weight_stats from load_player_weight():", stats)

	var cur := float(stats.get("current_carry_weight", {}).get("value", 0.0))
	var max := int(stats.get("max_carry_weight", {}).get("value", 0))
	print("⚖️ Calculated cur/max:", cur, "/", max)

	var player_info := StatusManager.get_carry_status(cur, max)
	player_weight_label.text = player_info["text"]
	player_weight_label.add_theme_color_override("font_color", player_info["color"])
	player_weight_label.visible = true
	
func show_appraisal(s: Dictionary) -> void:
	if s.is_empty():
		appraisal_panel.visible = false
		return

	appraisal_panel.visible = true

	# ✅ Set icon
	var tex: Texture2D = null
	if s.has("img_path"):
		var img_path: String = s["img_path"]
		if img_path != "" and ResourceLoader.exists(img_path):
			tex = ResourceLoader.load(img_path) as Texture2D
	appraisal_icon.texture = tex

	# ✅ Basic stats
	appraisal_name.text = s.get("base_display_name", "Unknown Item")

	var item_type = str(s.get("type", "")).to_upper()
	var has_durability = item_type in ["GEAR", "TOOL", "ARM"]

	if has_durability and s.has("durability") and s.has("max_durability"):
		var cur_dur = int(s.get("durability", 0))
		var max_dur = int(s.get("max_durability", 100))
		var ratio = float(cur_dur) / float(max_dur)

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
	else:
		appraisal_dura.visible = false

	# ✅ Value
	var value = s.get("value", s.get("avg_value_per", 0))
	appraisal_value.text = "Value: %d" % value
	appraisal_value.visible = value > 0

	# ✅ Bonuses
	var bonuses := []

	match item_type:
		"GEAR":
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

	# ✅ Description
	appraisal_description.text = str(s.get("des", ""))

	# ✅ Compare logic
	if item_type in ["GEAR", "ARM"]:
		appraisal_compare.text = "DEF << 5\nDEX >> 5"
		appraisal_compare.visible = true
		appraisal_comparetitle.visible = true
	else:
		appraisal_compare.visible = false
		appraisal_comparetitle.visible = false

	# ✅ Dismantle
	var can_dismantle: bool = s.get("dismantle", false)
	appraisal_dismantle.visible = can_dismantle
	appraisal_dismantletitle.visible = can_dismantle
	if can_dismantle:
		appraisal_dismantle.text = "Dismantlable Item"

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
