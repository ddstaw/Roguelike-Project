extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var preview_root := $DragPreviewRoot
	if preview_root.get_child_count() > 0:
		var preview := preview_root.get_child(0)
		if preview:
			var mouse_pos = get_viewport().get_mouse_position()
			preview.global_position = mouse_pos + Vector2(16, 16)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_clear_drag_preview()

func _clear_drag_preview() -> void:
	var preview_root := $DragPreviewRoot
	for child in preview_root.get_children():
		child.queue_free()
	visible = false
