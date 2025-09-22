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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("🖱️ ItemSlot click detected on:", name)
		var shift_pressed := Input.is_action_pressed("ui_shift")
		is_selected = true
		_update_visual_state()
		emit_signal("item_clicked", self, shift_pressed)  # 🆕 Shift-aware click
		accept_event()

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
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	count.offset_right = -7 #itemslot offset
	count.offset_bottom = -7 #itemslot offset
	count.custom_minimum_size = Vector2(24, 16) #itemslot count font size


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
