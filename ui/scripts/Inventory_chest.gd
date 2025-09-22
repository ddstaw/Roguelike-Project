# res://ui/scripts/Inventory_chest.gd
extends Control  # or whatever the root node is

@onready var player_panel := $Player_Panel
@onready var storage_panel := $Container_control/Storage_Panel
@onready var title_label := $TitleLabel
@onready var player_weight_label := $PlayerInvWeightLabel
@onready var mount_weight_label := $MountInvWeightLabel
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

var _register_type := ""
var _biome := ""
var _pos := Vector2i.ZERO
var _container_id := ""

func set_data(player_inventory: Dictionary, chest_inventory: Dictionary, pos: Vector2i, biome: String, container_id: String, container_type: String) -> void:
	_register_type = container_type
	_biome = biome
	_pos = pos
	_container_id = container_id

	player_panel.set_inventory(player_inventory)
	player_panel._refresh_grid()  # 👈 force refresh after setting data

	storage_panel.set_inventory(chest_inventory)
	storage_panel._refresh_grid()
	print("📦 set_data called with container_type:", container_type)
	print("📦 TitleLabel node valid?", is_instance_valid(title_label))

	match container_type.to_lower():
		"mount":     set_label("Transfer to Saddle Bags")
		"woodchest": set_label("Abandoned Wood Chest")
		_:           set_label("Searching Chest")
	
	_update_weight_labels(container_type)
	
func set_label(text: String) -> void:
	if title_label:
		title_label.text = text
	print("📝 Setting TitleLabel to:", text)

func set_register_type(rtype: String) -> void:
	_register_type = rtype

func _ready():
	get_tree().paused = true
	set_process_unhandled_input(true)
	appraisal_panel.visible = false  # 👈 hide initially

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_close_ui()

func _close_ui():
	get_tree().paused = false
	queue_free()
	
func refresh_weight_labels():
	print("🔄 Refresh weight labels called! _register_type =", _register_type)
	_update_weight_labels_deferred(_register_type)

# Wait 1 frame before refreshing weights
func _update_weight_labels_deferred(container_type: String) -> void:
	await get_tree().process_frame
	_update_weight_labels(container_type)
	
func _update_weight_labels(container_type: String) -> void:
	var stats: Dictionary = LoadHandlerSingleton.load_player_weight().get("weight_stats", {})

	# --- Player
	var cur := float(stats.get("current_carry_weight", {}).get("value", 0.0))
	var max := int(stats.get("max_carry_weight", {}).get("value", 0))
	var player_info := StatusManager.get_carry_status(cur, max)

	player_weight_label.text = player_info["text"]
	player_weight_label.add_theme_color_override("font_color", player_info["color"])
	player_weight_label.visible = true

	# --- Mount
	if container_type == "mount":
		var mcur := float(stats.get("current_mount_carry_weight", {}).get("value", 0.0))
		var mmax := int(stats.get("max_mount_carry_weight", {}).get("value", 0))
		var mount_info := StatusManager.get_carry_status(mcur, mmax)

		mount_weight_label.text = mount_info["text"]
		mount_weight_label.add_theme_color_override("font_color", mount_info["color"])
		mount_weight_label.visible = true
	else:
		mount_weight_label.visible = false

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
