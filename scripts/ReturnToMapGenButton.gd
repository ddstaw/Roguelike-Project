extends Button

func _ready():
	connect("pressed", Callable(self, "_on_Button_pressed"))

func _on_Button_pressed():
	get_tree().change_scene_to_file("res://scenes/NewGame.tscn")
