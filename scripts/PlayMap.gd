extends Button

# Load the CombineJSON script
var CombineJSONClass = preload("res://scripts/CombineJSON.gd")

func _ready():
	# Connect the button's pressed signal
	self.pressed.connect(_on_pressed)

func _on_pressed():
	# Create an instance of the CombineJSON script
	var combine_json_instance = CombineJSONClass.new()
	
	# Call the combine_json_files function on the instance
	combine_json_instance.combine_json_files()
	
	print("Map and world name combined into playing_map.json.")

	get_tree().change_scene_to_file("res://scenes/CultureMap.tscn")
