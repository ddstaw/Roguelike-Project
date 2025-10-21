extends Button
const ItemData = preload("res://constants/item_data.gd")

@export var blueprint_id: String = ""
@export var display_name: String = ""

@onready var name_label: Label = $Label  # match your node

func _ready() -> void:
	if display_name != "":
		name_label.text = display_name

func init(bp_id: String) -> void:
	blueprint_id = bp_id
	var entry: Dictionary = ItemData.ITEM_PROPERTIES.get(bp_id, {})

	display_name = entry.get("base_display_name", bp_id)
	
	if name_label:
		name_label.text = display_name
	else:
		await ready  # wait until ready signal fires
		name_label.text = display_name

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_MIDDLE]:
		get_viewport().set_input_as_handled()
		return
