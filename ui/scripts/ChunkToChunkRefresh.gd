extends Control

func _ready():
	print("🔄 Chunk-to-chunk refresh initiated...")

	await get_tree().process_frame  # Let the engine settle for a frame

	# Now safely load the local map again
	get_tree().change_scene_to_file("res://scenes/play/LocalMap.tscn")
