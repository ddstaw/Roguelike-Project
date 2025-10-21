# res://scripts/ItemSlot.gd
extends Control
class_name ItemSlot

signal item_clicked(slot: ItemSlot, shift: bool)  # 🆕 Scene-aware signal

@export var icon_padding: int = 4  # tweak in Inspector

var icon: TextureRect
var count: Label
var is_selected := false
var normal_style := StyleBoxFlat.new()
var selected_style := StyleBoxFlat.new()
var item_data: Dictionary = {}  # 🆕 Optional: store stack info if needed later
var stack_id: String = ""
var _drag_start_position := Vector2.ZERO


func _ready() -> void:
	icon = get_node_or_null("Icon") as TextureRect
	if icon == null:
		icon = TextureRect.new()
		icon.name = "Icon"
		add_child(icon)

	count = get_node_or_null("Count") as Label
	if count == null:
		count = Label.new()
		count.name = "Count"
		add_child(count)

	# Define styles
	normal_style.bg_color = Color(0, 0, 0, 0)  # Transparent
	selected_style.bg_color = Color(0.8, 0.6, 0.1, 0.5)  # Goldish with alpha
	var custom_font: Font = load("res://ui/inv_count_font.tres")
	count.add_theme_font_override("font", custom_font)
	count.add_theme_font_size_override("font_size", 30) #count font size set here

	_apply_icon_layout()
	_apply_count_layout()
	_update_visual_state()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_drag_start_position = event.position
			else:
				var shift_pressed := Input.is_action_pressed("ui_shift")
				is_selected = true
				_update_visual_state()
				emit_signal("item_clicked", self, shift_pressed)
				accept_event()

	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			if _drag_start_position.distance_to(event.position) > 10:
				# do nothing here, just let Godot call _get_drag_data()
				pass


func _update_visual_state() -> void:
	if is_selected:
		add_theme_stylebox_override("panel", selected_style)
	else:
		add_theme_stylebox_override("panel", normal_style)


func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_apply_icon_layout()  # keep padding on resize

func _apply_icon_layout() -> void:
	if icon == null: return   # guard against early notifications
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = icon_padding
	icon.offset_top = icon_padding
	icon.offset_right = -icon_padding
	icon.offset_bottom = -icon_padding
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon.size_flags_vertical = Control.SIZE_EXPAND_FILL

func _apply_count_layout() -> void:
	count.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	count.anchor_right = 1.0
	count.anchor_bottom = 1.0
	count.offset_right = -6
	count.offset_bottom = -6
	count.custom_minimum_size = Vector2(24, 16)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

func set_data(stack: Dictionary, tex: Texture2D) -> void:
	if icon == null or count == null:
		await ready
	icon.texture = tex
	var q: int = int(stack.get("qty", 1))
	count.text = str(q) if q > 1 else ""
	count.visible = q > 1
	tooltip_text = str(stack.get("display_name", stack.get("item_ID", "Item")))

	stack_id = str(stack.get("unique_ID", ""))  # ✅ Save ID for transfer
	name = stack_id  # Optional but helpful for debugging
	
	set_meta("data", stack)  # 🆕 Required for drag-and-drop!

func _get_drag_data(at_position: Vector2) -> Variant:
	print("📦 _get_drag_data called on", name)

	if stack_id != "":
		var drag_data := {
			"type": "action",
			"action_type": "item",
			"unique_ID": stack_id,
			"display_name": tooltip_text,
			"icon": icon.texture
		}

		var preview := TextureRect.new()
		preview.texture = icon.texture
		preview.expand = true
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.custom_minimum_size = Vector2(72, 72)

		# ✅ Add to global DragLayer
		var drag_root = DragLayer.get_node("DragPreviewRoot")
		for child in drag_root.get_children():
			child.queue_free()
		drag_root.add_child(preview)
		DragLayer.visible = true

		set_drag_preview(preview)
		return drag_data

	return null



func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("type") == "action"

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var parent = get_parent()
	while parent:
		if parent.has_method("handle_gear_slot_drop"):
			parent.handle_gear_slot_drop(self, data)
			break
		elif parent.has_method("handle_slot_drop"):
			parent.handle_slot_drop(self, data)
			break
		parent = parent.get_parent()

	DragLayer._clear_drag_preview()

func _make_preview() -> Control:
	var drag_preview := TextureRect.new()
	drag_preview.texture = icon.texture
	drag_preview.expand = true
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return drag_preview
