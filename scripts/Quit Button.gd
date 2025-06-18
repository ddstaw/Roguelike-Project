extends Button

func _ready():
	connect("pressed", Callable(self, "_on_Button_pressed"))

func _on_Button_pressed():
	get_tree().quit()  # This function closes the game when the button is pressed
