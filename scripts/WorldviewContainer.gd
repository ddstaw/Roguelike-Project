extends Node

var selected_button: TextureButton = null
var worldview_to_save: String = ""  # Track which worldview was selected

func _ready():
	# Connect all worldview buttons
	$Devslot.connect("pressed", Callable(self, "_on_worldview_button_pressed").bind($Devslot, "Devout"))
	$Humslot.connect("pressed", Callable(self, "_on_worldview_button_pressed").bind($Humslot, "Humanist"))
	$Ratslot.connect("pressed", Callable(self, "_on_worldview_button_pressed").bind($Ratslot, "Rationalist"))
	$Nilslot.connect("pressed", Callable(self, "_on_worldview_button_pressed").bind($Nilslot, "Nihilist"))
	$Occslot.connect("pressed", Callable(self, "_on_worldview_button_pressed").bind($Occslot, "Occultist"))
	$Proslot.connect("pressed", Callable(self, "_on_worldview_button_pressed").bind($Proslot, "Profiteer"))

func _on_worldview_button_pressed(button: TextureButton, worldview: String):
	# Deselect previous
	if selected_button:
		selected_button.modulate = Color(0.2, 0.2, 0.2)
		selected_button.disabled = false

	# Select new one
	selected_button = button
	selected_button.modulate = Color(1, 1, 1)
	selected_button.disabled = false

	# Mutate all others
	for child in get_children():
		if child != selected_button and child is TextureButton:
			child.modulate = Color(0.2, 0.2, 0.2)

	# Save worldview choice
	worldview_to_save = worldview
	update_character_worldview_in_json(worldview_to_save)


func update_character_worldview_in_json(selected_worldview: String):
	var json_path = "user://saves/character_template.json"
	var file = FileAccess.open(json_path, FileAccess.READ_WRITE)

	if file:
		var content = file.get_as_text()
		var json = JSON.new()
		var parse_result = json.parse(content)

		if parse_result == OK:
			var data = json.data
			if data.has("character"):
				data["character"]["worldview"] = selected_worldview
			else:
				data["character"] = { "worldview": selected_worldview }

			# Save back to file
			file = FileAccess.open(json_path, FileAccess.WRITE)
			file.store_string(JSON.stringify(data, "\t"))
			file.close()
		else:
			print("Failed to parse character_template.json:", parse_result)
	else:
		print("Failed to open character_template.json for reading.")
