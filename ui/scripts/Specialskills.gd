# res://ui/scripts/Specialskills.gd
extends TextureButton

@export var sskill: SSkill = null:
	set(value):
		sskill = value

@export var popups: Node  # this is assigned from CharacterCreation

func _pressed() -> void:
	if sskill == null:
		return
	if not popups:
		push_warning("⚠️ popups reference missing in Sskillslot.gd")
		return

	popups.set_value_sskill(sskill)
	popups.show_popup("SskillPopup")
