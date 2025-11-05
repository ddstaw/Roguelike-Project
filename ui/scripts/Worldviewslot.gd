# res://ui/scripts/Worldviewslot.gd
extends TextureButton

@export var worldview: Worldview
@export var popups: Node  # assign this in CharacterCreation when creating/instancing

func _pressed() -> void:
	if worldview == null or not is_instance_valid(popups):
		return
	popups.set_value_worldview(worldview)
	popups.show_popup("WVPopup")
