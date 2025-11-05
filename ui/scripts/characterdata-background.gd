extends Control

func _ready():
	var character_data = load_character_data()
	populate_character_data(character_data)

# --- Load Character Data ---
func load_character_data():
	var json_path = "user://saves/character_template.json"
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		print("Error: Failed to open character_template.json for reading.")
		return {}
	var content = file.get_as_text()
	var json := JSON.new()
	var ok := json.parse(content)
	if ok != OK:
		print("Error loading character data:", ok)
		file.close()
		return {}
	file.close()
	return json.data

# --- Canonicalization helpers ---
const FAITH_CANON := {
	"Orthodox Dogmatist": "Orthodox",
	"Pious Reformationist": "Reformation",
	"Fundamentalist Zealot": "Fundamentalist",
	"Sinister Cultist": "Sinister Cultist",
	"Guided By The Void": "Void",
	"Follower of The Old Ways": "Old Ways",
	"Disciple of Rex Mundi": "Rex Mundi",
	"Godless": "Godless"
}

const WV_CANON := {
	"Devout": "Devout",
	"Humanist": "Humanist",
	"Rationalist": "Rationalist",
	"Nihilist": "Nihilist",
	"Esoteric": "Occultist",   # matches your constants’ “Occultist”
	"Materialist": "Profiteer" # matches your constants’ “Profiteer”
}

func to_canonical_faith(s:String) -> String:
	return FAITH_CANON.get(s, s)

func to_canonical_worldview(s:String) -> String:
	return WV_CANON.get(s, s)

# --- Populate Character Data on Scene Load ---
func populate_character_data(character_data):
	if not character_data.has("character"):
		print("Error: Missing 'character' section in data.")
		return

	# Node refs
	var charport = $HBoxContainer/charport
	var charname = $HBoxContainer/VBoxContainer/charname
	var charpersonality = $HBoxContainer/VBoxContainer/charpersonality
	var charworldview = $HBoxContainer/VBoxContainer/WorldviewFaithlabels/charworldview
	var charfaith = $HBoxContainer/VBoxContainer/WorldviewFaithlabels/charfaith
	var charrace = $HBoxContainer/VBoxContainer/RaceSexlabels/charrace
	var charsex = $HBoxContainer/VBoxContainer/RaceSexlabels/charsex
	var chargskills = $chargskills
	var charsskills = $charsskills

	# Portrait
	if character_data["character"].has("portrait"):
		var portrait_texture = load(character_data["character"]["portrait"])
		if portrait_texture:
			charport.texture = portrait_texture
			charport.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT

	# Name / Race / Sex
	if character_data["character"].has("name"):
		charname.text = str(character_data["character"]["name"])
	charrace.text = str(character_data["character"].get("race","Unknown")).capitalize()
	charsex.text = str(character_data["character"].get("sex","Undefined")).capitalize()

	# Faith / Worldview (display original strings)
	charfaith.text = str(character_data["character"].get("faith","Unknown"))
	charworldview.text = str(character_data["character"].get("worldview","Undefined"))

	# Personality (use canonical keys for lookup)
	if character_data["character"].has("faith") and character_data["character"].has("worldview"):
		var faith_raw = str(character_data["character"]["faith"])
		var wv_raw = str(character_data["character"]["worldview"])
		var faith_key = to_canonical_faith(faith_raw)
		var wv_key = to_canonical_worldview(wv_raw)
		var persona = generate_personality(faith_key, wv_key)
		charpersonality.text = persona["title"]
		# Persist to JSON
		save_personality_to_json(persona)
	else:
		charpersonality.text = "Undefined Personality"

	# Skills
	if character_data.has("skills"):
		chargskills.text = get_active_skills(character_data["skills"])
	if character_data.has("magicktech"):
		charsskills.text = get_active_magicktech(character_data["magicktech"])

# --- Personality Generator ---
func generate_personality(faith_key: String, wv_key: String) -> Dictionary:
	var data = preload("res://constants/worldviewfaithpersona.gd").WORLDVIEW_FAITH_PERSONA
	if data.has(faith_key) and data[faith_key].has(wv_key):
		return data[faith_key][wv_key]
	# Fallback
	return {
		"title": faith_key + " " + wv_key,
		"type": "Undefined",
		"desc": "An undefined but intriguing personality."
	}

# --- Save personality back to JSON ---
func save_personality_to_json(persona: Dictionary) -> void:
	var json_path = "user://saves/character_template.json"
	var file = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		print("Could not open character_template.json to save personality.")
		return
	var content = file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		print("Failed parsing JSON while saving personality.")
		return
	var data:Dictionary = json.data
	if not data.has("character"):
		data["character"] = {}

	# Minimal required field per your ask:
	data["character"]["personality"] = str(persona.get("title","Unknown"))

	# Optional helpful extras (harmless if you keep them):
	data["character"]["personality_type"] = str(persona.get("type",""))
	data["character"]["personality_desc"] = str(persona.get("desc",""))

	# Write back
	var w = FileAccess.open(json_path, FileAccess.WRITE)
	if w:
		w.store_string(JSON.stringify(data, "\t"))
		w.close()

# --- General Skills ---
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
	var active := []
	for s in skills:
		if skills[s] and s in skill_names:
			active.append(skill_names[s])
	return ", ".join(active)

# --- Magick / Tech Skills ---
func get_active_magicktech(magicktech):
	var names = {
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
		"tink": "Tinkering",
		"veno": "Venomancy",
		"vito": "Vitomancy"
	}
	var active := []
	for s in magicktech:
		if magicktech[s] and s in names:
			active.append(names[s])
	return ", ".join(active)
