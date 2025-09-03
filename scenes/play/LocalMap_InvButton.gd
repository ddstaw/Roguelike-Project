extends TextureButton

func _ready():
	connect("pressed", Callable(self, "_on_Button_pressed"))

func _on_Button_pressed():
	SceneManager.change_scene_to_file("res://scenes/play/CharInventory.tscn")
