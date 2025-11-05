# res://ui/scripts/Raceslot.gd
extends TextureButton

@export var race: Race
@export var popups: Node  # Must be set in CharacterCreation scene

func _on_pressed() -> void:
	if not popups:
		push_warning("⚠️ popups reference missing in RaceSlot.gd")
		return
	if race:
		popups.set_value_race(race)
		popups.show_popup("RacePopup")
