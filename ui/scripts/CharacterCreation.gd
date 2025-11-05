# res://scenes/CharacterCreation.tscn parent node script res://ui/scripts/CharacterCreation.gd
extends Node2D

# ======================================================
# UI REFERENCES
# ======================================================

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
@onready var portrait_manager = $UI/PortraitContainer/PortraitRect
@onready var change_port_arrow = $UI/ChangePortArrow

@onready var popups = $UI/PopupContainer/PopupAnchor

@onready var dev_button = $UI/WorldviewContainer/Devslot
@onready var hum_button = $UI/WorldviewContainer/Humslot
@onready var rat_button = $UI/WorldviewContainer/Ratslot
@onready var nil_button = $UI/WorldviewContainer/Nilslot
@onready var occ_button = $UI/WorldviewContainer/Occslot
@onready var pro_button = $UI/WorldviewContainer/Proslot

@onready var pug_button   = $UI/SkillContainer/Pslot
@onready var brute_button = $UI/SkillContainer/BFslot
@onready var deft_button  = $UI/SkillContainer/DSslot
@onready var bowery_button = $UI/SkillContainer/Bowslot
@onready var firearms_button = $UI/SkillContainer/Firslot
@onready var athletics_button = $UI/SkillContainer/Athslot
@onready var skulduggery_button = $UI/SkillContainer/Skuslot
@onready var acumen_button = $UI/SkillContainer/Acslot
@onready var erudition_button = $UI/SkillContainer/Erslot
@onready var frontiersmanship_button = $UI/SkillContainer/Frslot
@onready var construction_button = $UI/SkillContainer/Coslot
@onready var tailoring_button = $UI/SkillContainer/Taslot
@onready var blacksmithing_button = $UI/SkillContainer/Blslot
@onready var bowmanship_button = $UI/SkillContainer/BoFlslot
@onready var metallurgy_button = $UI/SkillContainer/Meslot
@onready var alchemy_button = $UI/SkillContainer/Alslot

@onready var pyro_button = $UI/SpecialskillContainer/MagickContainer1/Pyroslot
@onready var cyro_button = $UI/SpecialskillContainer/MagickContainer1/Cyroslot
@onready var fulm_button = $UI/SpecialskillContainer/MagickContainer1/Fulslot
@onready var veno_button = $UI/SpecialskillContainer/MagickContainer1/Venslot

@onready var glam_button = $UI/SpecialskillContainer/MagickContainer2/Glamslot
@onready var nec_button = $UI/SpecialskillContainer/MagickContainer2/Necslot
@onready var vito_button = $UI/SpecialskillContainer/MagickContainer2/Vitoslot
@onready var ench_button = $UI/SpecialskillContainer/MagickContainer2/Enslot

@onready var gun_button  = $UI/SpecialskillContainer/TechContainer/Gunslot
@onready var tink_button = $UI/SpecialskillContainer/TechContainer/Tinkslot
@onready var chem_button = $UI/SpecialskillContainer/TechContainer/Chemslot
@onready var exp_button  = $UI/SpecialskillContainer/TechContainer/Expslot
@onready var robo_button = $UI/SpecialskillContainer/TechContainer/Robslot

@onready var to_bg_button: Button = $Col4/ToCharacterBackground


const RACE_DATA := {
	"human": {"racename":"Human","raceflavor":"Humaninfo","racebonus":"Human","key":"h"},
	"elf":   {"racename":"Elf","raceflavor":"Elfinfo","racebonus":"Elf","key":"e"},
	"dwarf": {"racename":"Dwarf","raceflavor":"Dwarfinfo","racebonus":"Dwarf","key":"d"},
	"orc":   {"racename":"Orc","raceflavor":"Orcinfo","racebonus":"Orc","key":"o"},
}

const FAITH_DATA := {
	"orthodox":      {"faithname":"Orthodox Dogmatist",     "faithflavor":"Orthoflav", "faithdes":"catechisms",          "faithbonus":"Orthobonus"},
	"reformist":     {"faithname":"Pious Reformationist",    "faithflavor":"Refoflav",  "faithdes":"devotionals",        "faithbonus":"Refobonus"},
	"fundamentalist":{"faithname":"Fundamentalist Zealot","faithflavor":"Fundflav", "faithdes":"holy_ghost_power",   "faithbonus":"Fundbonus"},
	"satanic":       {"faithname":"Sinister Cultist",      "faithflavor":"Sataflav",  "faithdes":"infernal_powers",    "faithbonus":"Satabonus"},
	"esoteric":      {"faithname":"Guided By The Void",     "faithflavor":"Esotflav",  "faithdes":"eldritch_invocations","faithbonus":"Esotbonus"},
	"oldworld":      {"faithname":"Follower of The Old Ways",    "faithflavor":"Oldwflav",  "faithdes":"druidic_rituals",    "faithbonus":"Oldwbonus"},
	"rexmundi":      {"faithname":"Disciple of Rex Mundi",    "faithflavor":"Rexmflav",  "faithdes":"the_rites_of_rex",   "faithbonus":"Rexmbonus"},
	"godless":       {"faithname":"Godless",      "faithflavor":"Godlflav",  "faithdes":"negation",           "faithbonus":"Godlbonus"},
}

const WORLDVIEW_DATA := {
	"devout":     {"worldviewname":"Devout",         "worldviewflavor":"Devflav", "worldviewdes":"Devdes"},
	"humanist":   {"worldviewname":"Humanist",       "worldviewflavor":"Humflav", "worldviewdes":"Humdes"},
	"rational":   {"worldviewname":"Rationalist",    "worldviewflavor":"Ratflav", "worldviewdes":"Ratdes"},
	"nihilistic": {"worldviewname":"Nihilist",     "worldviewflavor":"Nilflav", "worldviewdes":"Nildes"},
	"occultist":  {"worldviewname":"Occultist",      "worldviewflavor":"Occflav", "worldviewdes":"Occdes"},
	"profit":     {"worldviewname":"Profiteer",  "worldviewflavor":"Proflav", "worldviewdes":"Prodes"},
}

const GSKILL_DATA := {
	"pugilism":        {"gskillname":"Pugilism",        "gskillflavor":"pugflav",        "gskilldes":"pugdes"},
	"brute":           {"gskillname":"Brute Force",     "gskillflavor":"bruteflav",      "gskilldes":"brutedes"},
	"deft":            {"gskillname":"Deft Striking",   "gskillflavor":"deftflav",       "gskilldes":"deftdes"},
	"bowery":          {"gskillname":"Bowery",          "gskillflavor":"boweryflav",     "gskilldes":"bowerydes"},
	"firearms":        {"gskillname":"Firearms",        "gskillflavor":"fireflav",       "gskilldes":"firedes"},
	"athletics":       {"gskillname":"Athletics",       "gskillflavor":"athleticsflav",  "gskilldes":"athleticsdes"},
	"skulduggery":     {"gskillname":"Skulduggery",     "gskillflavor":"skuflav",        "gskilldes":"skudes"},
	"acumen":          {"gskillname":"Acumen",          "gskillflavor":"acumenflav",     "gskilldes":"acumendes"},
	"erudition":       {"gskillname":"Erudition",       "gskillflavor":"eruflav",        "gskilldes":"erudes"},
	"frontiersmanship":{"gskillname":"Frontiersmanship","gskillflavor":"frontflav",      "gskilldes":"frontdes"},
	"construction":    {"gskillname":"Construction",    "gskillflavor":"conflav",        "gskilldes":"condes"},
	"tailoring":       {"gskillname":"Tailoring",       "gskillflavor":"talflav",        "gskilldes":"taldes"},
	"blacksmithing":   {"gskillname":"Blacksmithing",   "gskillflavor":"blacksflav",     "gskilldes":"blacksdes"},
	"bowmanship":      {"gskillname":"Bowmanship",      "gskillflavor":"bowmanflav",     "gskilldes":"bowmandes"},
	"metallurgy":      {"gskillname":"Metallurgy",      "gskillflavor":"metflav",        "gskilldes":"metdes"},
	"alchemy":         {"gskillname":"Alchemy",         "gskillflavor":"alchemyflav",    "gskilldes":"alchemydes"},
}

const SSKILL_DATA := {
	"alchemy":     {"sskillname":"Alchemy",     "sskillflavor":"chemflav", "sskilldes":"chemdes"},
	"cyromancy":   {"sskillname":"Cyromancy",   "sskillflavor":"cyroflav", "sskilldes":"cyrodes"},
	"enchantment": {"sskillname":"Enchantment", "sskillflavor":"enchflav", "sskilldes":"enchdes"},
	"experimentation": {"sskillname":"Experimental Mechanics", "sskillflavor":"expflav", "sskilldes":"expdes"},
	"fulmancy":    {"sskillname":"Fulmancy",    "sskillflavor":"fulmflav", "sskilldes":"fulmdes"},
	"glamour":     {"sskillname":"Glamour",     "sskillflavor":"glamflav", "sskilldes":"glamdes"},
	"gunsmithing": {"sskillname":"Gunsmithing", "sskillflavor":"gunsflav", "sskilldes":"gunsdes"},
	"necromancy":  {"sskillname":"Necromancy",  "sskillflavor":"necrflav", "sskilldes":"necrdes"},
	"pyromancy":   {"sskillname":"Pyromancy",   "sskillflavor":"pyroflav", "sskilldes":"pyrodes"},
	"robotics":    {"sskillname":"Robotics",    "sskillflavor":"roboflav", "sskilldes":"robodes"},
	"tinkering":   {"sskillname":"Tinkering",   "sskillflavor":"tinkflav", "sskilldes":"tinkdes"},
	"venomancy":   {"sskillname":"Venomancy",   "sskillflavor":"venoflav", "sskilldes":"venodes"},
	"vitomancy":   {"sskillname":"Vitomancy",   "sskillflavor":"vitoflav", "sskilldes":"vitodes"},
}


# ======================================================
# STATE
# ======================================================

var current_race: String = "h"
var current_sex: String = "m"

# ======================================================
# READY
# ======================================================

func _ready():
	to_bg_button.pressed.connect(_on_to_character_background_pressed)

	# Connect button signals
	change_port_arrow.connect("pressed", Callable(self, "_on_change_port_arrow_pressed"))

	human_button.connect("pressed", Callable(self, "_on_race_selected").bind("human"))
	dwarf_button.connect("pressed", Callable(self, "_on_race_selected").bind("dwarf"))
	elf_button.connect("pressed", Callable(self, "_on_race_selected").bind("elf"))
	orc_button.connect("pressed", Callable(self, "_on_race_selected").bind("orc"))

	male_button.connect("pressed", Callable(self, "_on_sex_selected").bind("male"))
	female_button.connect("pressed", Callable(self, "_on_sex_selected").bind("female"))
	
		# Faith buttons
	orth_button.connect("pressed", Callable(self, "_on_faith_selected").bind("orthodox"))
	refo_button.connect("pressed", Callable(self, "_on_faith_selected").bind("reformist"))
	fund_button.connect("pressed", Callable(self, "_on_faith_selected").bind("fundamentalist"))
	sata_button.connect("pressed", Callable(self, "_on_faith_selected").bind("satanic"))
	esto_button.connect("pressed", Callable(self, "_on_faith_selected").bind("esoteric"))
	oldw_button.connect("pressed", Callable(self, "_on_faith_selected").bind("oldworld"))
	rexm_button.connect("pressed", Callable(self, "_on_faith_selected").bind("rexmundi"))
	godl_button.connect("pressed", Callable(self, "_on_faith_selected").bind("godless"))

	dev_button.connect("pressed", Callable(self, "_on_worldview_selected").bind("devout"))
	hum_button.connect("pressed", Callable(self, "_on_worldview_selected").bind("humanist"))
	rat_button.connect("pressed", Callable(self, "_on_worldview_selected").bind("rational"))
	nil_button.connect("pressed", Callable(self, "_on_worldview_selected").bind("nihilistic"))
	occ_button.connect("pressed", Callable(self, "_on_worldview_selected").bind("occultist"))
	pro_button.connect("pressed", Callable(self, "_on_worldview_selected").bind("profit"))

	pug_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("pugilism"))
	brute_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("brute"))
	deft_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("deft"))
	bowery_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("bowery"))
	firearms_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("firearms"))
	athletics_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("athletics"))
	skulduggery_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("skulduggery"))
	acumen_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("acumen"))
	erudition_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("erudition"))
	frontiersmanship_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("frontiersmanship"))
	construction_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("construction"))
	tailoring_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("tailoring"))
	blacksmithing_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("blacksmithing"))
	bowmanship_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("bowmanship"))
	metallurgy_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("metallurgy"))
	alchemy_button.connect("pressed", Callable(self, "_on_gskill_selected").bind("alchemy"))

	# MagickContainer1
	pyro_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("pyromancy"))
	cyro_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("cyromancy"))
	fulm_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("fulmancy"))
	veno_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("venomancy"))

	# MagickContainer2
	glam_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("glamour"))
	nec_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("necromancy"))
	vito_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("vitomancy"))
	ench_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("enchantment"))

	# TechContainer
	gun_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("gunsmithing"))
	tink_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("tinkering"))
	chem_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("alchemy"))
	exp_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("experimentation"))
	robo_button.connect("pressed", Callable(self, "_on_sskill_selected").bind("robotics"))
	
# ======================================================
# RACE / SEX LOGIC
# ======================================================

func _on_race_selected(race: String):
	var r = RACE_DATA.get(race, RACE_DATA["human"])
	current_race = r.key
	update_portraits()

	if is_instance_valid(popups):
		var race_obj := Race.new()
		race_obj.racename = r.racename
		race_obj.raceflavor = r.raceflavor
		race_obj.racebonus = r.racebonus
		popups.set_value_race(race_obj)
		popups.show_popup("RacePopup")

func _on_sex_selected(sex: String):
	current_sex = "m" if sex == "male" else "w"
	update_portraits()

func _on_faith_selected(faith_key: String) -> void:
	if not is_instance_valid(popups):
		return
	var f = FAITH_DATA.get(faith_key, FAITH_DATA["orthodox"])
	var faith_obj := Faith.new()
	faith_obj.faithname   = f.faithname
	faith_obj.faithflavor = f.faithflavor
	faith_obj.faithdes    = f.faithdes
	faith_obj.faithbonus  = f.faithbonus

	popups.set_value_faith(faith_obj)
	popups.show_popup("FaithPopup")

func _on_worldview_selected(key: String) -> void:
	if not is_instance_valid(popups):
		return

	var data = WORLDVIEW_DATA.get(key, WORLDVIEW_DATA["devout"])
	var worldview_obj := Worldview.new()
	worldview_obj.Worldviewname   = data.worldviewname
	worldview_obj.Worldviewflavor = data.worldviewflavor
	worldview_obj.Worldviewdes    = data.worldviewdes

	popups.set_value_worldview(worldview_obj)
	popups.show_popup("WVPopup")

func _on_gskill_selected(key: String) -> void:
	if not is_instance_valid(popups):
		return

	var data = GSKILL_DATA.get(key, GSKILL_DATA["pugilism"])
	var gskill_obj := GSkill.new()
	gskill_obj.gskillname   = data.gskillname
	gskill_obj.gskillflavor = data.gskillflavor
	gskill_obj.gskilldes    = data.gskilldes

	popups.set_value_gskill(gskill_obj)
	popups.show_popup("GskillPopup")

# ======================================================
# SPECIAL SKILL LOGIC
# ======================================================

func _on_sskill_selected(key: String) -> void:
	if not is_instance_valid(popups):
		return

	var data = SSKILL_DATA.get(key, SSKILL_DATA["alchemy"])
	var sskill_obj := SSkill.new()
	sskill_obj.sskillname   = data.sskillname
	sskill_obj.sskillflavor = data.sskillflavor
	sskill_obj.sskilldes    = data.sskilldes

	popups.set_value_sskill(sskill_obj)
	popups.show_popup("SskillPopup")



func update_portraits():
	portrait_manager.load_portraits(current_race, current_sex)
	save_current_portrait_to_json()

func _on_change_port_arrow_pressed():
	portrait_manager.cycle_next_portrait()
	save_current_portrait_to_json()

# ======================================================
# SAVE LOGIC
# ======================================================

func save_current_portrait_to_json():
	var file_path = "user://saves/character_template.json"
	var json = JSON.new()
	var file = FileAccess.open(file_path, FileAccess.READ)
	var data := {}

	if file:
		var content = file.get_as_text()
		var parse_result = json.parse(content)
		file.close()

		if parse_result == OK:
			data = json.data
		else:
			push_warning("JSON parse error: %s" % json.error_string)
			return
	else:
		push_warning("Failed to open %s" % file_path)
		return

	if data.has("character"):
		var portrait_path = portrait_manager.portraits[portrait_manager.current_index] if portrait_manager.portraits.size() > 0 else ""
		data["character"]["portrait"] = portrait_path
	else:
		push_warning("'character' missing in JSON data.")
		return

	file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json.stringify(data, "\t", true))
		file.close()
	else:
		push_warning("Failed to save %s" % file_path)

# ======================================================
# NAVIGATION
# ======================================================

func _on_to_character_background_pressed():
	get_tree().change_scene_to_file("res://scenes/CharacterBackground.tscn")
