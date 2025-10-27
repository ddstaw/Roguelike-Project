extends Control

const FaithInfo = preload("res://constants/faith_info.gd")
const FaithConvictionTitles = preload("res://constants/faith_conviction_titles.gd")

@onready var faith_title: Label = $"RightPanel/BottomPanel_Background/Panel/FaithPowerTitle"
@onready var scroll_vbox: VBoxContainer = $"RightPanel/BottomPanel_Background/Panel/ScrollContainer/VBoxContainer"
@onready var level_label: Label = $"RightPanel/TopPanel_Background/FaithLevelTitle"
@onready var faith_port: TextureRect = $"LeftPanel/LeftPanel_Background/LeftPanel_Background_Content/FaithPort"
@onready var faith_desc: RichTextLabel = $"LeftPanel/LeftPanel_Background/LeftPanel_Background_Content/FaithDesc"
@onready var xp_bar = $RightPanel/TopPanel_Background/Panel/XPBar
@onready var current_xp_label = $RightPanel/TopPanel_Background/XPLabels/CurrentXP
@onready var next_xp_label = $RightPanel/TopPanel_Background/XPLabels/NextXP

var current_faith: String = ""
var current_port: String = ""

func _ready():
	current_faith = LoadHandlerSingleton.detect_player_faith()
	current_port = get_faith_port_path(current_faith)
	load_faith_data()
	print("🧭 user:// expands to:", ProjectSettings.globalize_path("user://"))

# 🧠 Load and populate Faith UI
func load_faith_data():
	for child in scroll_vbox.get_children():
		child.queue_free()

	faith_title.text = get_power_title_for_faith(current_faith)
	faith_port.texture = load(current_port)

	var conviction_level: int = LoadHandlerSingleton.get_conviction_level_for_faith(current_faith)
	var skills: Array = FaithSkills.FAITH_SKILLS.get(current_faith, [])

	for s in skills:
		var skill_entry = preload("res://ui/scenes/FaithSkillTemplate.tscn").instantiate()

		# Text setup
		skill_entry.get_node("SkillHBox/SkillVBox/SkillName").text = s["name"].to_upper()
		skill_entry.get_node("SkillHBox/SkillVBox/SkillDesc").text = s["desc"]

		# Icon setup (gated vs unlocked)
		var icon_tex: Texture2D
		if conviction_level >= s["conviction_req"]:
			icon_tex = load(s["icon"])
		else:
			icon_tex = load(get_gated_icon_path(s["conviction_req"]))
		skill_entry.get_node("SkillHBox/SkillIcon").texture = icon_tex

		scroll_vbox.add_child(skill_entry)

	level_label.text = "Conviction Level %d: %s" % [
	conviction_level,
	LoadHandlerSingleton.get_conviction_rank_title(conviction_level, current_faith)
	]
	# 🕯️ Faith description
	faith_desc.bbcode_enabled = true
	faith_desc.text = FaithInfo.FAITH_INFO.get(current_faith, "[color=gray]Unknown faith or no description found.[/color]")
	
	# 🎚 XP Bar setup
	var current_xp = LoadHandlerSingleton.get_current_xp_for_faith(current_faith)
	var xp_to_next = LoadHandlerSingleton.get_xp_to_next_level_for_faith(current_faith)
	var ratio = LoadHandlerSingleton.get_xp_progress_ratio_for_faith(current_faith)

	xp_bar.value = ratio * 100.0
	current_xp_label.text = "Current Conviction XP: %d" % current_xp
	next_xp_label.text = "To Next Level: %d" % (xp_to_next - current_xp)

# 🔒 Locked (gated) placeholder icons
func get_gated_icon_path(req_level: int) -> String:
	match req_level:
		1: return "res://assets/ui/faith/con_unlock/conunlock_1.png"
		3: return "res://assets/ui/faith/con_unlock/conunlock_3.png"
		5: return "res://assets/ui/faith/con_unlock/conunlock_5.png"
		_: return "res://assets/ui/faith/con_unlock/conunlock_1.png"


# 🏷️ Faith Title
func get_power_title_for_faith(faith: String) -> String:
	match faith:
		"infernal_powers":      return "Infernal Powers"
		"catechisms":           return "Catechisms"
		"devotionals":          return "Devotionals"
		"holy_ghost_power":     return "Holy Ghost Power"
		"druidic_rituals":      return "Druidic Rituals"
		"the_rites_of_rex":     return "The Rites of Rex"
		"eldritch_invocations": return "Eldritch Invocations"
		"negation":             return "Negation"
		_:                      return "Negation"


# 🖼️ Faith Portrait Loader
func get_faith_port_path(faith: String) -> String:
	match faith:
		"infernal_powers":      return "res://assets/ui/faith/sin_port.png"
		"catechisms":           return "res://assets/ui/faith/ortho_port.png"
		"devotionals":          return "res://assets/ui/faith/reform_port.png"
		"holy_ghost_power":     return "res://assets/ui/faith/fund_port.png"
		"druidic_rituals":      return "res://assets/ui/faith/oldways_port.png"
		"the_rites_of_rex":     return "res://assets/ui/faith/rex_port.png"
		"eldritch_invocations": return "res://assets/ui/faith/void_port.png"
		"negation":             return "res://assets/ui/faith/godless_port.png"
		_:                      return "res://assets/ui/faith/godless_port.png"
