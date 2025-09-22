extends Panel

func _ready():
	print("✅ Dialogue popup is now active!")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		print("❌ Closing dialogue popup")
		get_tree().paused = false
		get_parent().queue_free()
