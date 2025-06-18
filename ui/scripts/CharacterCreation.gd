extends Node2D

# Declare variables at the top
@onready var orth_button = $UI/FaithContainer/Orthslot
@onready var refo_button = $UI/FaithContainer/Refoslot
@onready var fund_button = $UI/FaithContainer/Fundslot
@onready var sata_button = $UI/FaithContainer/Sataslot
@onready var esto_button = $UI/FaithContainer/Estoslot
@onready var oldw_button = $UI/FaithContainer/Oldwslot
@onready var rexm_button = $UI/FaithContainer/Rexmslot
@onready var godl_button = $UI/FaithContainer/Godlslot
@onready var human_button = $UI/RaceInfo/humanslot
@onready var dwarf_button = $UI/RaceInfo/dwarfslot
@onready var elf_button = $UI/RaceInfo/elfslot
@onready var orc_button = $UI/RaceInfo/orcslot
@onready var male_button = $UI/SexBox/malebutton
@onready var female_button = $UI/SexBox/femalebutton
@onready var portrait_manager = $UI/PortraitContainer/PortraitRect  # Ensure this is a global variable
@onready var change_port_arrow = $UI/ChangePortArrow

var current_race = "h"  # Default to human ('h')
var current_sex = "m"   # Default to male ('m')

func _ready():
	# Connect buttons to their respective functions
	change_port_arrow.connect("pressed", Callable(self, "_on_change_port_arrow_pressed"))
	human_button.connect("pressed", Callable(self, "_on_race_selected").bind("human"))
	dwarf_button.connect("pressed", Callable(self, "_on_race_selected").bind("dwarf"))
	elf_button.connect("pressed", Callable(self, "_on_race_selected").bind("elf"))
	orc_button.connect("pressed", Callable(self, "_on_race_selected").bind("orc"))
	male_button.connect("pressed", Callable(self, "_on_sex_selected").bind("male"))
	female_button.connect("pressed", Callable(self, "_on_sex_selected").bind("female"))
	orth_button.connect("pressed", Callable(self, "_on_faith_selected").bind("Orthodox Dogmatist"))
	refo_button.connect("pressed", Callable(self, "_on_faith_selected").bind("Pious Reformationist"))
	fund_button.connect("pressed", Callable(self, "_on_faith_selected").bind("Fundamentalist Zealot"))
	sata_button.connect("pressed", Callable(self, "_on_faith_selected").bind("Sinister Cultist"))
	esto_button.connect("pressed", Callable(self, "_on_faith_selected").bind("Guided By The Void"))
	oldw_button.connect("pressed", Callable(self, "_on_faith_selected").bind("Follower of The Old Ways"))
	rexm_button.connect("pressed", Callable(self, "_on_faith_selected").bind("Disciple of Rex Mundi"))
	godl_button.connect("pressed", Callable(self, "_on_faith_selected").bind("Godless"))
	
func _on_race_selected(race: String):
	match race:
		"human":
			current_race = "h"
		"elf":
			current_race = "e"
		"dwarf":
			current_race = "d"
		"orc":
			current_race = "o"
	update_portraits()

func _on_sex_selected(sex: String):
	match sex:
		"male":
			current_sex = "m"
		"female":
			current_sex = "w"
	update_portraits()

func update_portraits():
	portrait_manager.load_portraits(current_race, current_sex)
	save_current_portrait_to_json()

# Function to cycle through portraits when the arrow button is pressed
func _on_change_port_arrow_pressed():
	portrait_manager.cycle_next_portrait()
	save_current_portrait_to_json()

# Function to save the currently displayed portrait to the JSON file
func save_current_portrait_to_json():
	var file_path = "user://saves/character_template.json"
	var json = JSON.new()  # Create a new instance of JSON
	var data = {}  # Variable to store the JSON data

	# Attempt to read existing JSON data
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()  # Read the file content
		var parse_result = json.parse(content)  # Parse the content
		file.close()  # Close after reading

		if parse_result == OK:
			data = json.data  # Load existing data if parsing is successful
			print("Successfully read JSON data:", data)  # Debug print to confirm data read
		else:
			print("JSON parsing error: ", json.error_string)
			return
	else:
		print("Failed to open file for reading: ", file_path)
		return

	# Check if the "character" section exists and update the "portrait" field
	if "character" in data:
		var portrait_path = portrait_manager.portraits[portrait_manager.current_index] if portrait_manager.portraits.size() > 0 else ""
		print("Setting portrait path to:", portrait_path)  # Debug print to check the path being set
		data["character"]["portrait"] = portrait_path
	else:
		print("Error: 'character' section not found in JSON data.")
		return

	# Write the updated JSON data back to the file without overwriting other data
	file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json.stringify(data, "\t", true))  # Save the updated data with formatting
		file.close()
		print("Successfully saved updated JSON data.")  # Debug print to confirm save
	else:
		print("Failed to open file for writing: ", file_path)


func _on_to_character_background_pressed():
	pass # Replace with function body.
