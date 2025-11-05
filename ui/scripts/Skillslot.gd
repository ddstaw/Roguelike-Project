# res://ui/scripts/Skillslot.gd
extends TextureButton

@export var gskill: GSkill
@export var popups: Node  # Assigned in CharacterCreation or via editor

func _pressed() -> void:
	if gskill == null or not is_instance_valid(popups):
		return
	popups.set_value_gskill(gskill)
	popups.show_popup("GskillPopup")
