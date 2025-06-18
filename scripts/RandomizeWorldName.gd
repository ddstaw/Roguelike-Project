extends Button

func _pressed():
	var world_name_generator = get_node("/root/NewGame/WorldNameGeneratorNode")
	world_name_generator.generate_world_name()
