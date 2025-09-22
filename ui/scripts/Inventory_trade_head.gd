# Inventory_trade_head
extends Control  # Inventory_trade is the root node

@onready var right_panel := $Right_Panel
@onready var left_panel := $Container_control/Left_Panel
@onready var title_label := $Container_control/Left_Panel/TitleLabel  # optional, if present

var _vendor_type := ""
var _biome := ""
var _pos := Vector2i.ZERO
var _vendor_id := ""

func set_data(
	player_inventory: Dictionary,
	vendor_inventory: Dictionary,
	pos: Vector2i,
	biome: String,
	vendor_id: String,
	vendor_type: String
) -> void:
	_vendor_type = vendor_type
	_biome = biome
	_pos = pos
	_vendor_id = vendor_id

	right_panel.set_inventory(player_inventory)
	left_panel.set_inventory(vendor_inventory)

	# Label display
	set_label("Trading with " + vendor_type.capitalize())

func set_label(text: String) -> void:
	if title_label:
		title_label.text = text

func set_vendor_type(vtype: String) -> void:
	_vendor_type = vtype

func _ready():
	get_tree().paused = true
	set_process_unhandled_input(true)

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		_close_ui()

func _close_ui():
	get_tree().paused = false
	queue_free()
