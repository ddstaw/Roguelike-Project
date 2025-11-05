# res://ui/scripts/Faithslot.gd
extends TextureButton

@export var faith: Faith
@export var popups: Node  # Drag PopupAnchor here in the editor

func _on_pressed() -> void:
	if not is_instance_valid(popups):
		push_warning("⚠️ popups reference missing in FaithSlot.gd")
		return
	if faith:
		popups.set_value_faith(faith)
		popups.show_popup("FaithPopup")
