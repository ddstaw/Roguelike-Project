extends TextureButton

@export var race: Race = null:
	set(value):
		race = value

func _on_mouse_entered():
	if race == null:
		return
		
	Popups.RacePopup(Rect2i( Vector2i(global_position) , Vector2i(size) ), race) #setups position
	
func _on_mouse_exited():
	Popups.HideRacePopup

