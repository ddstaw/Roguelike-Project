extends Node2D

func _ready():
	$AnimationPlayer.play("fading")
	await get_tree().create_timer(6).timeout
	$AnimationPlayer.play("fadeout")
	await get_tree().create_timer(3).timeout
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	# The fade_out function in FadeTransition should handle the scene change after the fade completes
	# Ensure the FadeTransition.gd script changes the scene after the fade effect completes
