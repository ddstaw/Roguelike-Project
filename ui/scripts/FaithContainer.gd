extends Node

var selected_button: TextureButton = null
var faith_to_save: String = ""  # Variable to track the selected faith

# Faith-to-divine-skill mapping
const FAITH_TO_DIVINESKILL := {
	"Orthodox Dogmatist": "catechisms",
	"Pious Reformationist": "devotionals",
	"Fundamentalist Zealot": "holy_ghost_power",
	"Sinister Cultist": "infernal_powers",
	"Guided By The Void": "eldritch_invocations",
	"Follower of The Old Ways": "druidic_rituals",
	"Disciple of Rex Mundi": "the_rites_of_rex",
	"Godless": "negation"
}

func _ready():
	# Connect all buttons to the same function, binding faith name
	$Orthslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Orthslot, "Orthodox Dogmatist"))
	$Refoslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Refoslot, "Pious Reformationist"))
	$Fundslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Fundslot, "Fundamentalist Zealot"))
	$Sataslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Sataslot, "Sinister Cultist"))
	$Estoslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Estoslot, "Guided By The Void"))
	$Oldwslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Oldwslot, "Follower of The Old Ways"))
	$Rexmslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Rexmslot, "Disciple of Rex Mundi"))
	$Godlslot.connect("pressed", Callable(self, "_on_faith_button_pressed").bind($Godlslot, "Godless"))

# --- Called whenever a faith button is pressed ---
func _on_faith_button_pressed(button: TextureButton, faith: String):
	# Deselect previous button
	if selected_button:
		selected_button.modulate = Color(0.2, 0.2, 0.2)
		selected_button.disabled = false

	# Highlight the new button
	selected_button = button
	selected_button.modulate = Color(1, 1, 1)
	selected_button.disabled = false

	# Mutate other buttons
	for child in get_children():
		if child != selected_button and child is TextureButton:
			child.modulate = Color(0.2, 0.2, 0.2)

	# Update JSON
	faith_to_save = faith
	update_character_faith_in_json(faith_to_save)

# --- Update JSON: Faith + Divine Skills ---
func update_character_faith_in_json(selected_faith: String):
	var json_path = "user://saves/character_template.json"
	var file = FileAccess.open(json_path, FileAccess.READ_WRITE)

	if not file:
		print("Failed to open character_template.json for reading.")
		return

	var content = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		print("Failed to parse character_template.json:", parse_result)
		return

	var data = json.data

	# --- 1. Ensure character and divineskills exist ---
	if not data.has("character"):
		data["character"] = {}
	if not data.has("divineskills"):
		data["divineskills"] = {}

	# --- 2. Update faith ---
	data["character"]["faith"] = selected_faith

	# --- 3. Reset all divine skills to false ---
	for key in data["divineskills"].keys():
		data["divineskills"][key] = false

	# --- 4. Activate the divine skill matching the faith ---
	if FAITH_TO_DIVINESKILL.has(selected_faith):
		var divine_key = FAITH_TO_DIVINESKILL[selected_faith]
		data["divineskills"][divine_key] = true
	else:
		print("No divine skill mapping found for faith:", selected_faith)

	# --- 5. Write updated data back ---
	file = FileAccess.open(json_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

	print("✅ Updated faith and divine skills:", selected_faith)
