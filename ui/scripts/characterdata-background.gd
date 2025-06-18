extends Control  # Assuming the main scene node type is Control

func _ready():
	# Load JSON data from the specified path
	var character_data = load_character_data()  # Load the character data from JSON

	# Populate the character data container with character information
	populate_character_data(character_data)


# Function to load the character data JSON from the specified path
func load_character_data():
	var json_path = "user://saves/character_template.json"  # Correct path for your data
	var file = FileAccess.open(json_path, FileAccess.READ)

	if file == null:
		print("Error: Failed to open character_template.json for reading.")
		return {}

	var content = file.get_as_text()
	var json = JSON.new()  # Create a new JSON object
	var parse_result = json.parse(content)

	# Check if parsing was successful
	if parse_result != OK:
		print("Error loading character data:", parse_result)
		file.close()
		return {}

	file.close()
	return json.data  # Access the parsed data directly from the JSON object


# Function to populate character data based on the structured layout
func populate_character_data(character_data):
	# Access nodes directly by their unique names
	var charport = $charport  # Assuming node is named 'charport'
	var charname = $charname  # Assuming node is named 'charname'
	var charfaith = $charfaith  # Assuming node is named 'charfaith'
	var chargskills = $chargskills  # Assuming node is named 'chargskills'
	var charsskills = $charsskills  # Assuming node is named 'charsskills'

	# Check if nodes are loaded correctly and print guidance if not found
	if charport == null:
		print("Error: charport node not found.")
	if charname == null:
		print("Error: charname node not found.")
	if charfaith == null:
		print("Error: charfaith node not found.")
	if chargskills == null:
		print("Error: chargskills node not found.")
	if charsskills == null:
		print("Error: charsskills node not found.")

	# If any node was not found, stop execution to avoid further errors
	if charport == null or charname == null or charfaith == null or chargskills == null or charsskills == null:
		return  # Stop execution here to avoid setting text on null nodes

	# Attempt to load the character portrait texture
	var portrait_texture = load(character_data["character"]["portrait"])
	if portrait_texture == null:
		print("Error: Failed to load portrait texture from path:", character_data["character"]["portrait"])
	else:
		# Set character portrait
		charport.texture = portrait_texture
		charport.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	# Debug print the character data to verify correct loading
	print("Character Data:", character_data)

	# Set character name and race, with the race capitalized and formatted
	if character_data["character"].has("name") and character_data["character"].has("race"):
		var name = str(character_data["character"]["name"])
		var race = str(character_data["character"]["race"]).capitalize()  # Capitalize the race
		charname.text = name + ", " + race
		print("Setting Name and Race:", charname.text)
	else:
		print("Error: Name or Race not found in character data.")

	# Set character faith without extra text
	if character_data["character"].has("faith"):
		charfaith.text = str(character_data["character"]["faith"])
		print("Setting Faith:", charfaith.text)
	else:
		print("Error: Faith not found in character data.")

	# Set general skills marked true
	chargskills.text = get_active_skills(character_data["skills"])
	print("Setting General Skills:", chargskills.text)

	# Set magick/tech skills marked true
	charsskills.text = get_active_magicktech(character_data["magicktech"])
	print("Setting Magick/Tech Skills:", charsskills.text)


# Helper function to get active skills marked true with full flavor names
func get_active_skills(skills):
	var skill_names = {
		"acumen": "Acumen",
		"alchemy": "Alchemy",
		"athletics": "Athletics",
		"blacksmithing": "Blacksmithing",
		"bowery": "Bowery",
		"bowmanship": "Bowmanship",
		"bruteforce": "Brute Force",
		"construction": "Construction",
		"deftstriking": "Deft Striking",
		"erudition": "Erudition",
		"firearms": "Firearms",
		"frontiersmanship": "Frontiersmanship",
		"metallurgy": "Metallurgy",
		"pugilism": "Pugilism",
		"skullduggery": "Skullduggery",
		"tailoring": "Tailoring"
	}
	var active_skills = []
	for skill in skills:
		if skills[skill] and skill in skill_names:
			active_skills.append(skill_names[skill])
	return ", ".join(active_skills)


# Helper function to get active magick/tech skills marked true with full flavor names
func get_active_magicktech(magicktech):
	var magicktech_names = {
		"chem": "Chemistry",
		"cyro": "Cyromancy",
		"ench": "Enchantments",
		"exp": "Experimental Weaponry",
		"fulm": "Fulmimancy",
		"glam": "Glamourmancy",
		"guns": "Gunsmithing",
		"necr": "Necromancy",
		"pyro": "Pyromancy",
		"robo": "Robotics",
		"thau": "Thaumaturgy",
		"tink": "Tinkering",
		"veno": "Venomancy",
		"vito": "Vitomancy",
		"wand": "Wandcraft"
	}
	var active_magicktech = []
	for skill in magicktech:
		if magicktech[skill] and skill in magicktech_names:
			active_magicktech.append(magicktech_names[skill])
	return ", ".join(active_magicktech)
