# res://ui/scripts/chrp-control.gd attached to Control
extends Control

@onready var chrp_port = get_node("TopLeftCharInfoControl/chrpplayerinfoCharPort")
@onready var chrp_name = get_node("TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrpnamelabel")
@onready var chrp_race = get_node("TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrp-HBoxContainer-racesex/chrpracelabel")
@onready var chrp_background = get_node("TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrpbackground")
@onready var chrp_faith = get_node("TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrp-HBoxContainer-worldviewfaith/chrpfaithlabel")

func _ready():
	print("📜 CharProfile UI initializing...")

	# ✅ Load JSON data from singleton paths
	var character_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_character_creation_path())
	var combat_stats_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_combat_stats_path())
	var base_attributes_data = LoadHandlerSingleton.load_json_file(LoadHandlerSingleton.get_base_attributes_path())

	# ✅ Populate Character Info
	if character_data:
		chrp_populate_character_data(character_data)
	else:
		print("⚠️ No character creation data found.")

	# ✅ Populate Combat Stats
	if combat_stats_data:
		chrp_populate_combat_stats(combat_stats_data)
	else:
		print("⚠️ No combat stats data found.")

	# ✅ Populate Base Attributes (includes level + XP display)
	if base_attributes_data:
		chrp_populate_base_attributes(base_attributes_data)

		# Also update XP bar if the data exists
		if base_attributes_data.has("experience"):
			update_xp_progress_bar(base_attributes_data["experience"])
	else:
		print("⚠️ No base attributes data found.")

	print("✅ CharProfile UI ready.")

func chrp_populate_character_data(character_data: Dictionary):
	if not character_data.has("character"):
		print("⚠️ Missing 'character' section in JSON.")
		return

	var data = character_data["character"]

	# --- Portrait ---
	if data.has("portrait"):
		var portrait_tex = load(data["portrait"])
		var portrait_node = get_node("TopLeftCharInfoControl/chrpplayerinfoCharPort")
		if portrait_tex and portrait_node:
			portrait_node.texture = portrait_tex
		else:
			print("⚠️ Portrait node or texture missing.")
	else:
		print("⚠️ Portrait path not found in data.")

	# --- Labels mapping (new structure) ---
	var mapping = {
		"name": "TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrpnamelabel",
		"personality": "TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrptitlelabel", # The "Super Duper Guy" label
		"background": "TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrpbackground",
		"race": "TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrp-HBoxContainer-racesex/chrpracelabel",
		"sex": "TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrp-HBoxContainer-racesex/chrpracelabel2",
		"worldview": "TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrp-HBoxContainer-worldviewfaith/chrpworldviewlabel",
		"faith": "TopLeftCharInfoControl/chrp-VBoxContainer-charinfo/chrp-HBoxContainer-worldviewfaith/chrpfaithlabel"
	}

	# --- Apply text values safely ---
	for key in mapping.keys():
		if data.has(key):
			var node = get_node(mapping[key])
			if node:
				node.text = str(data[key])
			else:
				print("⚠️ Node not found for", key, "at", mapping[key])
		else:
			print("⚠️ Character data missing key:", key)

	print("✅ Character info populated successfully.")



		
func chrp_populate_combat_stats(combat_stats_data: Dictionary):
	if not combat_stats_data.has("combat_stats"):
		print("⚠️ Missing 'combat_stats' section in JSON.")
		return

	var stats = combat_stats_data["combat_stats"]

	# --- Armor & Dodge ---
	if stats.has("armor_rating"):
		var armor_label = get_node("RightPanelBottomGearControl/ArmorDodgeControl/ArmorDodgeHbox/chrp-ar")
		armor_label.text = str(stats["armor_rating"]["value"])
	if stats.has("chance_to_dodge"):
		var dodge_label = get_node("RightPanelBottomGearControl/ArmorDodgeControl/ArmorDodgeHbox/chrp-dodge")
		dodge_label.text = str(stats["chance_to_dodge"]["value"]) + "%"

	# --- Core Meters (Health, Stamina, Fatigue, Hunger, Sanity) ---
	var meter_paths = {
		"health": "CenterCurrentMeters/chrp-VBoxContainer-meter-lvl/chrp-health-lvl",
		"stamina": "CenterCurrentMeters/chrp-VBoxContainer-meter-lvl/chrp-stamina-lvl",
		"fatigue": "CenterCurrentMeters/chrp-VBoxContainer-meter-lvl/chrp-fatigue-lvl",
		"hunger": "CenterCurrentMeters/chrp-VBoxContainer-meter-lvl/chrp-hunger-lvl",
		"sanity": "CenterCurrentMeters/chrp-VBoxContainer-meter-lvl/chrp-sanity-lvl"
	}

	for key in meter_paths.keys():
		if stats.has(key) and stats[key].has("current") and stats[key].has("max"):
			var node = get_node(meter_paths[key])
			node.text = str(stats[key]["current"]) + "/" + str(stats[key]["max"])

	# --- Resistances ---
	if stats.has("resistances"):
		var res = stats["resistances"]
		var res_paths = {
			"fire_resistance": "ResistStats/chrp-VBoxContainer-dmgresist-lvl/chrp-fir-lvl",
			"ice_resistance": "ResistStats/chrp-VBoxContainer-dmgresist-lvl/chrp-cold-lvl",
			"poison_resistance": "ResistStats/chrp-VBoxContainer-dmgresist-lvl/chrp-poi-lvl",
			"glamour_resistance": "ResistStats/chrp-VBoxContainer-dmgresist-lvl/chrp-gla-lvl",
			"magic_resistance": "ResistStats/chrp-VBoxContainer-dmgresist-lvl/chrp-mgk-lvl",
			"divine_resistance": "ResistStats/chrp-VBoxContainer-dmgresist-lvl/chrp-div-lvl",
			"dark_resistance": "ResistStats/chrp-VBoxContainer-dmgresist-lvl/chrp-dar-lvl",
			"void_resistance": "ResistStats/chrp-VBoxContainer-dmgresist-lvl/chrp-voi-lvl"
		}
		for r in res_paths.keys():
			if res.has(r) and res[r].has("value"):
				var res_node = get_node(res_paths[r])
				res_node.text = str(res[r]["value"]) + "%"

	
func chrp_populate_base_attributes(base_attributes_data: Dictionary):
	if not base_attributes_data.has("effective_attributes"):
		print("⚠️ Missing 'effective_attributes' in base_attributes_data.")
		return

	print("Base Attributes Data:", base_attributes_data)

	# --- Base Attributes (Left Panel) ---
	var attr_map = {
		"strength": "BaseStats/chrp-VBoxContainer-activelvl/chrp-strength-lvl",
		"perception": "BaseStats/chrp-VBoxContainer-activelvl/chrp-perception-lvl",
		"agility": "BaseStats/chrp-VBoxContainer-activelvl/chrp-agility-lvl",
		"endurance": "BaseStats/chrp-VBoxContainer-activelvl/chrp-endurance-lvl",
		"intelligence": "BaseStats/chrp-VBoxContainer-activelvl/chrp-intelligence-lvl",
		"charisma": "BaseStats/chrp-VBoxContainer-activelvl/chrp-charisma-lvl",
		"willpower": "BaseStats/chrp-VBoxContainer-activelvl/chrp-willpower-lvl"
	}

	for key in attr_map.keys():
		if base_attributes_data["effective_attributes"].has(key):
			var node = get_node(attr_map[key])
			node.text = str(base_attributes_data["effective_attributes"][key])
		else:
			print("Missing base attribute:", key)

	# --- Experience / Level / XP Bar (TopLeftCharInfoControl) ---
	if not base_attributes_data.has("experience"):
		print("⚠️ Missing 'experience' in base_attributes_data.")
		return

	var xp = base_attributes_data["experience"]

	# Level label
	if xp.has("level"):
		var level_label = get_node("TopLeftCharInfoControl/chrp-levelvbox/chrp-levellabel")
		level_label.text = "Level " + str(xp["level"])

	# XP Labels + Progress Bar
	if xp.has("current_xp") and xp.has("xp_to_next_level"):
		var xp_label_left = get_node("TopLeftCharInfoControl/chrp-levelvbox/LvlXpVbox/chrp-playerinfo-exp-meter-all/chrp-xptolevelup")
		var xp_label_right = get_node("TopLeftCharInfoControl/chrp-levelvbox/LvlXpVbox/chrp-playerinfo-exp-meter-all/chrp-xptolevelup2")
		var xp_progress = get_node("TopLeftCharInfoControl/chrp-levelvbox/LvlXpVbox/chrp-playerinfo-exp-meter-all")

		xp_label_left.text = "Current XP: " + str(xp["current_xp"])
		xp_label_right.text = "to next Level: " + str(xp["xp_to_next_level"])
		xp_progress.max_value = xp["xp_to_next_level"]
		xp_progress.value = xp["current_xp"]

		
func update_xp_progress_bar(experience_data: Dictionary):
	if not (experience_data.has("current_xp") and experience_data.has("xp_to_next_level")):
		print("⚠️ Missing 'current_xp' or 'xp_to_next_level' in experience data.")
		return

	var current_xp = experience_data["current_xp"]
	var xp_to_next_level = experience_data["xp_to_next_level"]

	# --- Access XP ProgressBar and labels safely ---
	var xp_progress = get_node("TopLeftCharInfoControl/chrp-levelvbox/LvlXpVbox/chrp-playerinfo-exp-meter-all")
	var xp_label_left = get_node("TopLeftCharInfoControl/chrp-levelvbox/LvlXpVbox/chrp-playerinfo-exp-meter-all/chrp-xptolevelup")
	var xp_label_right = get_node("TopLeftCharInfoControl/chrp-levelvbox/LvlXpVbox/chrp-playerinfo-exp-meter-all/chrp-xptolevelup2")

	# --- Update UI ---
	xp_progress.max_value = xp_to_next_level
	xp_progress.value = current_xp
	xp_label_left.text = "Current XP: " + str(current_xp)
	xp_label_right.text = "to next Level: " + str(xp_to_next_level)

	print("✅ XP Progress updated:", current_xp, "/", xp_to_next_level)
