extends Control
#parent script in res://scenes/play/Inventory_LocalPlay.tscn

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
const WORLD_SCENE := "res://scenes/play/WorldMapTravel.tscn"
const LOCAL_SCENE := "res://scenes/play/LocalMap.tscn"

var _closing := false  # simple debounce so we don't double-trigger


func _ready() -> void:
	print("📦 Inventory scene loaded.")
	appraisal_panel.visible = false  # 👈 hide initially
	_update_weight_label()  # 👈 add this
	
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

	# Explicit types + cast values to String before comparison
	var in_city: bool = (cs.get("incity", "N") as String) == "Y"
	var in_local: bool = (cs.get("inlocalmap", "N") as String) == "Y"
	var in_world: bool = (cs.get("inworldmap", "N") as String) == "Y"

	var target: String = LOCAL_SCENE
	if in_local:
		target = LOCAL_SCENE
	else:
		# Both incity:Y and inworldmap:Y route to the world travel scene
		target = WORLD_SCENE

	print("⬅️ Returning to: ", target)
	get_tree().paused = false
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
