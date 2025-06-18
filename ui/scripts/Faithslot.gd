extends TextureButton

@export var faith: Faith = null:
	set(value):
		faith = value

func _on_mouse_entered():
	if faith == null:
		return
		
	Popups.FaithPopup(Rect2i( Vector2i(global_position) , Vector2i(size) ), faith) #setups position

func _on_mouse_exited():
	Popups.HideFaithPopup
