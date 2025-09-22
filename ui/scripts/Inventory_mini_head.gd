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
@onready var appraisal_compare := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/CompareLabel")
@onready var appraisal_dismantle := appraisal_panel.get_node("MarginContainer/ScrollContainer/VBoxContainer/MarginContainer/VBoxContainer/DismantleLabel")

const ITEM_DATA := preload("res://constants/item_data.gd")

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

	# ✅ Extract item_ID and definition
	var item_id: String = str(s.get("item_ID", ""))
	var item_def: Dictionary = ITEM_DATA.ITEM_PROPERTIES.get(item_id, {})

	# ✅ Set icon
	var tex: Texture2D = null
	if item_def.has("img_path") and ResourceLoader.exists(item_def["img_path"]):
		tex = ResourceLoader.load(item_def["img_path"]) as Texture2D
	appraisal_icon.texture = tex

	# ✅ Basic stats
	appraisal_name.text = str(s.get("display_name", "")).capitalize()
	appraisal_dura.text = "Good Condition %s/%s" % [s.get("durability", 0), s.get("max_durability", 100)]
	appraisal_value.text = "Value: %s" % str(s.get("value", 0))

	# ✅ Bonuses (explicitly typed)
	var def: int = int(s.get("def_bonus", 0))
	var dex: int = int(s.get("dex_bonus", 0))
	appraisal_bonus.text = "+%s Def, %+s Dex" % [def, dex]

	# ✅ Description
	appraisal_description.text = str(s.get("des", ""))

	# 🔄 Dummy compare logic
	appraisal_compare.text = "DEF << 5\nDEX >> 5"

	# 🔧 Placeholder dismantle list
	appraisal_dismantle.text = "Metal Scraps, Leather"

func hide_appraisal() -> void:
	appraisal_panel.visible = false
