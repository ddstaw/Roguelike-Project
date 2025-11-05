extends Node2D

@onready var slot_nodes := {
	1: get_node("SaveSlot1"),
	2: get_node("SaveSlot2"),
	3: get_node("SaveSlot3")
}

func _ready():
	refresh_save_slots()


func refresh_save_slots():
	for i in range(1, 4):
		load_save_slot_info(i)


func load_save_slot_info(slot_num: int):
	var slot = slot_nodes[slot_num]
	if slot == null:
		return

	var world_name := "No World Data"
	var date_created := ""
	var char_name := "(no active character)"
	var char_persona := ""
	var portrait_path := "res://ui/p/blank.png"
	var is_active := false

	# 🌍 Load World Info
	var world_path = "user://saves/save%d/world/basemapdata%d.json" % [slot_num, slot_num]
	if FileAccess.file_exists(world_path):
		var f = FileAccess.open(world_path, FileAccess.READ)
		var j = JSON.new()
		if j.parse(f.get_as_text()) == OK:
			var data = j.data
			if data.size() > 0:
				world_name = data[0].get("world_name", "Unnamed World")
				date_created = data[0].get("date_created", "")
		f.close()

	# 🧍 Load Character Active Status
	var active_path = "user://saves/save%d/world/char_active%d.json" % [slot_num, slot_num]
	if FileAccess.file_exists(active_path):
		var f = FileAccess.open(active_path, FileAccess.READ)
		var j = JSON.new()
		if j.parse(f.get_as_text()) == OK:
			is_active = j.data.get("is_active", false)
		f.close()

	# 💾 Load Character Info if active
	if is_active:
		var char_path = "user://saves/save%d/characterdata/character_creation-save%d.json" % [slot_num, slot_num]
		if FileAccess.file_exists(char_path):
			var f = FileAccess.open(char_path, FileAccess.READ)
			var j = JSON.new()
			if j.parse(f.get_as_text()) == OK:
				var char_data = j.data.get("character", {})
				char_name = char_data.get("name", "Unknown")
				char_persona = char_data.get("personality", "")
				portrait_path = char_data.get("portrait", "res://ui/p/blank.png")
			f.close()

	# 🎨 Update UI Elements for this slot
	update_slot_ui(slot_num, world_name, date_created, char_name, char_persona, portrait_path, is_active)


func update_slot_ui(slot_num: int, world_name: String, date_created: String, char_name: String, char_persona: String, portrait_path: String, is_active: bool):
	var slot = slot_nodes[slot_num]
	if slot == null:
		return

	var prefix = "SS" + str(slot_num)
	slot.get_node("%sWorldName" % prefix).text = world_name
	slot.get_node("%sWorldGenerated" % prefix).text = date_created
	slot.get_node("%sName" % prefix).text = char_name
	slot.get_node("%sPersona" % prefix).text = char_persona

	# 🖼️ Portrait
	var portrait_node = slot.get_node("TextureRect" + str(slot_num))
	if portrait_path != "" and FileAccess.file_exists(portrait_path):
		portrait_node.texture = load(portrait_path)
	else:
		portrait_node.texture = preload("res://ui/p/blank.png")

	# 💡 Dim inactive slots
	if not is_active:
		slot.modulate = Color(0.6, 0.6, 0.6, 1.0)
	else:
		slot.modulate = Color(1, 1, 1, 1.0)
