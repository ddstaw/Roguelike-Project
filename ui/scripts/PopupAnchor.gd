# res://ui/scripts/PopupAnchor.gd
extends Control

@onready var popups_ui: Node = $Popups

func hide_all_popups() -> void:
	if is_instance_valid(popups_ui):
		popups_ui.hide_all_popups()

func show_popup(name: String) -> void:
	if is_instance_valid(popups_ui):
		popups_ui.show_popup(name)

# Optional: proxy setters if you’re calling from elsewhere
func set_value_race(race):
	if is_instance_valid(popups_ui):
		popups_ui.set_value_race(race)

func set_value_faith(f):
	if is_instance_valid(popups_ui):
		popups_ui.set_value_faith(f)

func set_value_worldview(wv):
	if is_instance_valid(popups_ui):
		popups_ui.set_value_worldview(wv)

func set_value_gskill(g):
	if is_instance_valid(popups_ui):
		popups_ui.set_value_gskill(g)

func set_value_sskill(s):
	if is_instance_valid(popups_ui):
		popups_ui.set_value_sskill(s)
