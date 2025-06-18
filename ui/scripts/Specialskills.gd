extends TextureButton

@export var sskill: SSkill = null:
	set(value):
		sskill = value

func _on_mouse_entered():
	if sskill == null:
		return
		
	Popups.SskillPopup(Rect2i( Vector2i(global_position) , Vector2i(size) ), sskill) #setups position

func _on_mouse_exited():
	Popups.HideSskillPopup
