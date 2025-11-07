# UILayer/LocalPlayUI/InvButton - res://scenes/play/LocalMap_InvButton.gd
extends TextureButton

func _ready() -> void:
	connect("pressed", Callable(self, "_on_Button_pressed"))

func _on_Button_pressed() -> void:
	var player := get_tree().root.get_node_or_null("LocalMap/Player")
	if player and is_instance_valid(player):
		var grid_pos := Vector2i(int(player.position.x / 88), int(player.position.y / 88))
		var z_level := int(LoadHandlerSingleton.get_current_z_level())

		# 🧾 Load placement and update grid + z
		var placement_data := LoadHandlerSingleton.load_temp_localmap_placement()
		if not placement_data.has("local_map"):
			placement_data["local_map"] = {}

		placement_data["local_map"]["grid_position_local"] = {
			"x": grid_pos.x,
			"y": grid_pos.y
		}
		placement_data["local_map"]["z_level"] = str(z_level)

		LoadHandlerSingleton.save_temp_localmap_placement(placement_data)
		print("💾 Saved position before inventory:", grid_pos, "z:", z_level)

	# (Optional but smart) — also save player state or stats if available
	if LoadHandlerSingleton.has_method("save_player_inventory"):
		LoadHandlerSingleton.save_player_inventory(LoadHandlerSingleton.load_player_inventory())

	# 🔁 Transition to inventory
	SceneManager.change_scene_to_file("res://scenes/play/CharInventory.tscn")
