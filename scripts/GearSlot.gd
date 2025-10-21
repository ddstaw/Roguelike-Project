# res://scripts/GearSlot.gd
extends ItemSlot
class_name GearSlot

@export var slot_type: String = ""  # Optional for future use

func _ready():
	super._ready()

func set_data(stack: Dictionary, tex: Texture2D) -> void:
	super.set_data(stack, tex)
	count.visible = false  # Gear slots don't need quantity shown

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var parent = get_parent()
		while parent and not parent.has_method("handle_gear_slot_right_click"):
			parent = parent.get_parent()

		if parent:
			parent.handle_gear_slot_right_click(self)
		accept_event()

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var parent = get_parent()
	while parent and not parent.has_method("handle_gear_slot_equip"):
		parent = parent.get_parent()

	if parent and data.has("unique_ID"):
		var uid: String = str(data["unique_ID"])
		parent.handle_gear_slot_equip(self, uid)

	DragLayer._clear_drag_preview()
