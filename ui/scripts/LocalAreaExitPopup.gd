extends Panel

@onready var yes_button = $YesButton
@onready var no_button = $NoButton

func _ready():
	yes_button.pressed.connect(_on_yes_pressed)
	no_button.pressed.connect(_on_no_pressed)

func _on_yes_pressed():
	print("🛫 Area exit confirmed — going to LocaltoWorldRefresh.")
	get_tree().change_scene_to_file("res://scenes/play/LocaltoWorldRefresh.tscn")

func _on_no_pressed():
	print("↩️ Cancelled area exit.")
	queue_free()
