extends TextureButton

@export var gskill: GSkill = null:
	set(value):
		gskill = value

func _on_mouse_entered():
	if gskill == null:
		return
		
	Popups.GskillPopup(Rect2i( Vector2i(global_position) , Vector2i(size) ), gskill) #setups position

func _on_mouse_exited():
	Popups.HideGskillPopup
