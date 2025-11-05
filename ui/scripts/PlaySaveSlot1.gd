# res://scenes/LoadGame.tscn - saveslot1 script
extends Button

func _ready():
	connect("pressed", Callable(self, "_on_Button_pressed"))

func _on_Button_pressed():
	var save_slot = 1  # change this for slot2 / slot3
	var char_active_path = "user://saves/save%d/world/char_active%d.json" % [save_slot, save_slot]

	if not FileAccess.file_exists(char_active_path):
		show_character_creation_prompt(save_slot)
		return

	var file = FileAccess.open(char_active_path, FileAccess.READ)
	var j = JSON.new()
	if j.parse(file.get_as_text()) != OK:
		file.close()
		show_character_creation_prompt(save_slot)
		return
	file.close()

	var is_active = j.data.get("is_active", false)
	if not is_active:
		show_character_creation_prompt(save_slot)
	else:
		load_existing_game(save_slot)


# 🧭 If an active character exists, load the correct scene
func load_existing_game(save_slot: int):
	var load_handler = LoadHandlerSingleton
	load_handler.set_current_save_slot(save_slot)

	var state_data = load_handler.load_char_state()
	var char_state = state_data.get("character_state", {})

	var in_localmap = char_state.get("inlocalmap", "N")
	var in_worldmap = char_state.get("inworldmap", "N")
	var in_city = char_state.get("incity", "N")

	# 🧩 Logic: if localmap = Y → LocalMap; else → WorldMapTravel
	var scene_path := ""
	if in_localmap == "Y":
		scene_path = "res://scenes/play/LocalMap.tscn"
	else:
		scene_path = "res://scenes/play/WorldMapTravel.tscn"

	print("🧭 Loading save slot %d scene: %s" % [save_slot, scene_path])
	get_tree().change_scene_to_file(scene_path)


# 🪄 If no active character, prompt new creation
func show_character_creation_prompt(save_slot):
	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Create a new character?"
	dialog.title = "No Character"
	add_child(dialog)
	dialog.connect("confirmed", Callable(self, "_on_create_new_character_confirmed").bind(save_slot))
	dialog.connect("canceled", Callable(self, "_on_create_new_character_canceled"))
	dialog.popup_centered()


func _on_create_new_character_confirmed(save_slot):
	var handler_file_path = "user://saves/load_handler.json"
	var save_file_path = "user://saves/save" + str(save_slot) + "/"
	var file = FileAccess.open(handler_file_path, FileAccess.WRITE)
	if file:
		var json_data = {
			"selected_save_slot": save_slot,
			"save_file_path": save_file_path
		}
		file.store_string(JSON.stringify(json_data))
		file.close()

	get_tree().change_scene_to_file("res://scenes/CharacterCreation.tscn")


func _on_create_new_character_canceled():
	print("Character creation canceled.")
