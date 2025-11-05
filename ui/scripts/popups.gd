# UI/PopupContainer/PopupAnchor/Popups script res://ui/scripts/popups.gd
extends Control

const FaithInfo = preload("res://constants/faith_info.gd")


@onready var popups := {
	"RacePopup": $RacePopup,
	"FaithPopup": $FaithPopup,
	"WVPopup": $WVPopup,
	"SskillPopup": $SskillPopup,
	"GskillPopup": $GskillPopup,
	"DskillPopup": $DskillPopup
}

var active_popup: Control


func _ready():
	add_to_group("popups")

func hide_all_popups() -> void:
	for p in popups.values():
		if is_instance_valid(p):
			p.hide()
	active_popup = null

func show_popup(name: String) -> void:
	hide_all_popups()
	if not popups.has(name):
		push_warning("Popup '%s' not found" % name)
		return
	var p: Control = popups[name]
	if not is_instance_valid(p):
		return
	p.position = Vector2.ZERO
	p.show()
	active_popup = p

# ======================================================
# RACE POPUP
# ======================================================

func set_value_race(race: Race):
	%Racename.text = race.racename
	%Raceflavor.text = set_flavortext_effect(race.raceflavor)
	%Racebonus.text = set_bonustext_effect(race.racebonus)

func set_flavortext_effect(raceflavor: String) -> String:
	match raceflavor:
		"Humaninfo": return "Beggers and Kings, Saints and Devils.The most common race on the planet, but hardly respectable.\n\nSkilled in both [color=89cff0]Tech[/color] and [color=#ff20fe]Magick[/color]"
		"Dwarfinfo": return "The mountain folk, the technological forebearers.A hardy and innovative people but often too smart for their own good.\n\nInclined towards [color=89cff0]Technological Disciplines[/color]"
		"Elfinfo": return "The forest dwellers, nymphs of the woods.The oldest race and most mystic, making them somewhat flightly and shrill.\n\nInclined towards [color=#ff20fe]Arcane Traditions[/color]"
		"Orcinfo": return "The children of the earth, possessing a frightening vitality. Treated by the other races as \nlow-bred brutes, their lives are typically no bed of roses.\n\nSkilled in both [color=89cff0]Tech[/color] and [color=#ff20fe]Magick[/color]"
		_: return raceflavor

func set_bonustext_effect(racebonus: String) -> String:
	match racebonus:
		"Human": return "Racial Bonus: [color=yellow]+1[/color] to [color=yellow]All Attributes[/color]"
		"Dwarf": return "Racial Bonus: [color=yellow]+2[/color] to [color=red]Strength[/color] and [color=89cff0]Endurance[/color]"
		"Elf": return "Racial Bonus: [color=yellow]+2[/color] to [color=purple]Perception[/color] and [color=green]Charisma[/color]"
		"Orc": return "Racial Bonus: [color=yellow]+2[/color] to [color=red]Strength[/color] and [color=orange]Agility[/color]"
		_: return racebonus


# ======================================================
# FAITH POPUP
# ======================================================

func set_value_faith(faith: Faith):
	%Faithname.text = faith.faithname
	%Faithflavor.text = set_flavortext_effect_faith(faith.faithflavor)
	%Faithdes.text = set_descriptext_effect(faith.faithdes)
	%Faithbonus.text = set_bonustext_effect_faith(faith.faithbonus)

# --- your existing Faith flavor, desc, and bonus text functions remain unchanged ---


# ======================================================
# WORLDVIEW POPUP
# ======================================================

func set_value_worldview(worldview: Worldview):
	%WVname.text = worldview.Worldviewname
	%WVflavor.text = set_flavortext_effect_worldview(worldview.Worldviewflavor)
	%WVdes.text = set_descriptext_effect_worldview(worldview.Worldviewdes)


# ======================================================
# GENERAL SKILL POPUP
# ======================================================

func set_value_gskill(gskill: GSkill):
	%Gskillname.text = gskill.gskillname
	%Gskillflavor.text = set_flavortext_effect_gskill(gskill.gskillflavor)
	%Gskilldes.text = set_gskilldescriptext_effect(gskill.gskilldes)


# ======================================================
# SPECIAL SKILL POPUP
# ======================================================

func set_value_sskill(sskill: SSkill):
	%Sskillname.text = sskill.sskillname
	%Sskillflavor.text = set_flavortext_effect_sskill(sskill.sskillflavor)
	%Sskilldes.text = set_sskilldescriptext_effect(sskill.sskilldes)


# ======================================================
# FAITH TEXT HELPERS
# ======================================================

func set_flavortext_effect_faith(faithflavor: String) -> String:
	match faithflavor:
		"Orthoflav": return "[i]I Suffer for Your Glory[/i]"
		"Refoflav": return "[i]I am your Servant O' Mighty Lord[/i]"
		"Fundflav": return "[i]He Manifests through my Body![/i]"
		"Sataflav": return "[i]Do What Thou Will[/i]"
		"Esotflav": return "[i]I hear, I obey[/i]"
		"Oldwflav": return "[i]I Walk the Ancient Ways[/i]"
		"Rexmflav": return "[i]By Rex's Beard![/i]"
		"Godlflav": return "[i]Spare me that God Nonsense[/i]"
		_: return faithflavor

func set_descriptext_effect(faithdes: String) -> String:
	# Try to pull matching lore block from constants
	if FaithInfo.FAITH_INFO.has(faithdes):
		return FaithInfo.FAITH_INFO[faithdes].strip_edges()
	else:
		push_warning("⚠️ Faith key '%s' not found in FAITH_INFO" % faithdes)
		return "[color=red]Missing description for %s[/color]" % faithdes

func set_bonustext_effect_faith(faithbonus: String) -> String:
	match faithbonus:
		"Orthobonus": return "Discordant to [color=#ff20fe]Magick Practitioners[/color]\nAffinitive to [color=89cff0]Technologists[/color]"
		"Refobonus": return "Indifferent to both paths"
		"Fundbonus", "Satabonus", "Esotbonus": return "Affinitive to [color=#ff20fe]Magick Practitioners[/color]\nIndifferent to [color=89cff0]Technologists[/color]"
		"Oldwbonus": return "Affinitive to [color=#ff20fe]Magick Practitioners[/color]\nDiscordant to [color=89cff0]Technologists[/color]"
		"Rexmbonus": return "Discordant to [color=#ff20fe]Magick Practitioners[/color]\nAffinitive to [color=89cff0]Technologists[/color]"
		"Godlbonus": return "Indifferent to [color=#ff20fe]Magick[/color]\nAffinitive to [color=89cff0]Technology[/color]"
		_: return faithbonus


# ======================================================
# WORLDVIEW TEXT HELPERS
# ======================================================

func set_flavortext_effect_worldview(worldviewflavor: String) -> String:
	match worldviewflavor:
		"Devflav": return "[i]My Resolve Comes From My Faith (or Lack Thereof)[/i]"
		"Humflav": return "[i]All we have in this Cold World is each other.[/i]"
		"Ratflav": return "[i]Everything happens for reasons,\nI intend to find as many of those reasons as possible.[/i]"
		"Nilflav": return "[i]Another pointless struggle, Why do I bother?[/i]"
		"Occflav": return "[i]There is something more to all this,\nWhat exactly I'm not sure?[/i]"
		"Proflav": return "[i]Get what you can and keep it, screw the rest.[/i]"
		_: return worldviewflavor

func set_descriptext_effect_worldview(worldviewdes: String) -> String:
	match worldviewdes:
		"Devdes": return "You are firm in your resolve that your chosen faith contains all the answers. Some may call you a zealot or blind follower, but it is they who are blind to the simple truth."
		"Humdes": return "You believe in the slow but eventual triumph of mankind, no matter their race, life is life, man is man, brotherhood is brotherhood. It is an obvious fact of nature that we would die alone but together we can stumble towards heaven even under this dark night. "
		"Ratdes": return "You believe in Cold Rationality — things make sense, things click together. Science and Reason teaches us to map the hidden shapes of our reality. Nothing is beyond our ken."
		"Nildes": return "You believe in Nothing, and why should you not? What does this life hold but injustice and pain and lies? You may have your faith, your little stories, but ultimately dust is dust. Only children and fools hide from this truth, but not you - you walk through this cold life with your eyes open, hope is just another childhood tale you've abandoned. "
		"Occdes": return "You don't know what it is, but there is this nagging feeling there's something just beyond your reach. You seek gnosis, you seek hidden knowledge, you have your personal faith and it brings you comfort but you know there are more dark corners in this earth waiting to be discovered. "
		"Prodes": return "Life is to be enjoyed, how do you do this? Money. People these days overcomplicate things, life is short, why waste time when it could be savored? You intend to get yourself a piece and damn the rest.  "
		_: return worldviewdes


# ======================================================
# GENERAL SKILL TEXT HELPERS
# ======================================================

func set_flavortext_effect_gskill(gskillflavor: String) -> String:
	match gskillflavor:
		"pugflav": return "[i]The Gentle Art of Fisticuffs[/i]"
		"acumenflav": return "[i]The Art of Tradecraft[/i]"
		"alchemyflav": return "[i]The Simple Sciences[/i]"
		"athleticsflav": return "[i]The Vigorous Pursuit[/i]"
		"blacksflav": return "[i]The Art of Hammer and Anvil[/i]"
		"boweryflav": return "[i]The Noble Craft of Arrow and String[/i]"
		"bruteflav": return "[i]The Savage Power of Sheer Might[/i]"
		"deftflav": return "[i]The Dance of the Blade[/i]"
		"conflav": return "[i]Denbuilding and Furnishings[/i]"
		"eruflav": return "[i]The Aristocratic Obligation[/i]"
		"fireflav": return "[i]The Gunner's Art[/i]"
		"metflav": return "[i]The Knowledge of Fire and Ore[/i]"
		"frontflav": return "[i]The Skill of Rugged Individualism[/i]"
		"skuflav": return "[i]The Criminal Professions[/i]"
		"talflav": return "[i]The Skill of Needle and Thread[/i]"
		"bowmanflav": return "[i]Distance with Deadly Intent[/i]"
		_: return gskillflavor

func set_gskilldescriptext_effect(gskilldes: String) -> String:
	match gskilldes:
		"pugdes": return "Sometimes guns misfire, sometimes spells miscast, you must take things into your own hands. The art of pugilism is both a science and a philosophy, requiring not just brawn but rhythm and nerve. Masters of the fist are seldom caught off guard and can turn any tavern into an arena."
		"acumendes": return "Buy for better prices, sell for better prices, see more inventory, and never be cheated. The shrewd understand that in commerce, information and timing are worth more than gold. Acumen lets you read a merchant's eyes as easily as a ledger."
		"alchemydes": return "The skill of the cunning folk, those who brew simple potions and poisons from herbs and minerals. The alchemist’s workshop smells of strange flowers and stranger fumes, a place where science and sorcery meet over a bubbling crucible."
		"athleticsdes": return "The body is a temple, and you are its priest. Athletics governs your ability to climb, swim, run, and push through exhaustion. It is the difference between victory and collapse when the journey grows long."
		"blacksdes": return "The production of metal armors, weapons, and shields. The blacksmith’s hammer is the heartbeat of civilization, ringing out in forges from the mountains to the city slums. Those who master the anvil shape not only steel but destiny."
		"bowerydes": return "The production of stringed ranged weapons—bows, crossbows, and the art of fletching. The bowyer’s work bridges craftsmanship and war, their hands calloused not from battle but from precision and patience."
		"brutedes": return "The advanced techniques for greatswords, great axes, and other heavy weapons. Brute force is not mindless rage—it’s the art of channeling your will through muscle and momentum until the world yields before you."
		"deftdes": return "The assassin’s art—the advanced techniques for daggers, short swords, and quick, decisive strikes. Deft striking favors the subtle, those who prefer to end fights before they truly begin."
		"condes": return "The handiwork knowhow for the construction of beds, chests, walls, and furnishings. Construction represents self-sufficiency and permanence—the art of building a place where one may endure and rest."
		"erudes": return "The ability to read, to write, and to know the greater world beyond your doorstep. Erudition grants access to lore, history, and languages—knowledge is its own weapon, and the mind its whetstone."
		"firedes": return "You don’t need a doctorate to pull a trigger—but understanding the mechanism makes the difference between a click and a bang. Firearms skill determines your accuracy, your reload speed, and your relationship with recoil."
		"metdes": return "The old art of turning mineral into metal. Metallurgy is the backbone of progress—smelting, refining, and alloying the materials that make machines and miracles alike."
		"frontdes": return "Living off the land, making campfires, waterskins, traps, and shelters. Frontiersmanship defines your survival instinct—the knack for thriving where civilization ends."
		"skudes": return "It is a sad state of affairs, but many an adventurer is driven to criminal talents. Skulduggery covers lockpicking, pickpocketing, and the delicate art of not getting caught."
		"taldes": return "The fashionable craft of cloth and leather. Tailoring marries practicality and vanity—the ability to clothe kings, thieves, and beggars in equal measure."
		"bowmandes": return "Strike your foes from a distance with ease. Bowmanship combines patience, precision, and instinct—the line between hunter and hunted drawn with a single arrow."
		_: return gskilldes


# ======================================================
# SPECIAL SKILL TEXT HELPERS
# ======================================================

func set_flavortext_effect_sskill(sskillflavor: String) -> String:
	match sskillflavor:
		"chemflav": return "[color=7f9aa3]The Discipline of Reactive Formulations[/color]"
		"cyroflav": return "[color=2b8dbf]The Tradition of Gelid Mysteries[/color]"
		"enchflav": return "[color=6B4AD4]The Tradition of Mystic Imbuing[/color]"
		"expflav": return "[color=7f9aa3]The Discipline of Radical Armament Design[/color]"
		"fulmflav": return "[color=e4d70d]The Tradition of Tempestology[/color]"
		"glamflav": return "[color=fa14d7]The Tradition of Phantasmagoria[/color]"
		"gunsflav": return "[color=7f9aa3]The Discipline of Mechanized Ballistics[/color]"
		"necrflav": return "[color=5b5b5b]The Loathesome Tradition of Revenants[/color]"
		"pyroflav": return "[color=b21515]The Tradition of Conflagration[/color]"
		"roboflav": return "[color=7f9aa3]The Discipline of Automaton Engineering[/color]"
		"tinkflav": return "[color=7f9aa3]The Discipline of Mechanical Craftwork[/color]"
		"venoflav": return "[color=32ba35]The Tradition of Venefic Arts[/color]"
		"vitoflav": return "[color=0adfbe]The Tradition of Restorative Arts[/color]"
		_: return sskillflavor

func set_sskilldescriptext_effect(sskilldes: String) -> String:
	match sskilldes:
		"chemdes": return "Taught in City Universities and by village academics. Chemistry governs the blending of substances, crafting explosives, elixirs, and toxic concoctions that can alter the tide of battle."
		"cyrodes": return "An elemental school taught by the Druids of the Elf Havens. Cyromancy commands frost and cold, freezing foes and slowing the passage of time itself."
		"enchdes": return "A strange school known only to itinerant Arcanists. Enchantment imbues objects and allies with power, bending will and substance alike."
		"expdes": return "Taught in Military Universities and via Black Market means. Experimental Mechanics pushes the limits of invention and armament — often dangerously."
		"fulmdes": return "An elemental school taught by the Druids of the Elf Havens. Fulmancy is the mastery of storm and thunder, weaponizing lightning and raw energy."
		"glamdes": return "A flashy, foppish school practiced mostly by city mages. Glamour magic manipulates light and perception to deceive, beguile, or inspire awe."
		"gunsdes": return "Taught in the Gunsmithing Guild by its instructors. Gunsmithing refines the art of crafting and maintaining firearms of all calibers."
		"necrdes": return "The forbidden practice of grave desecration and raising the dead. Necromancy harnesses life’s residue for power, often at terrible cost."
		"pyrodes": return "An elemental school taught by the Druids of the Elf Havens. Pyromancy wields fire as creation and destruction both, bringing light and ruin."
		"robodes": return "Taught in City Universities and by mad academics. Robotics melds logic, machinery, and spark — giving life where none existed."
		"tinkdes": return "Taught by local repairmen and itinerant academics. Tinkering is the humble but essential craft of maintaining, improving, and repurposing devices."
		"venodes": return "A foul school taught by slum mages in the Capital City. Venomancy uses toxins, plagues, and decay as both weapon and message."
		"vitodes": return "An elemental school taught by the Druids of the Elf Havens. Vitomancy channels vitality and spirit, restoring life and strength to the weary."
		_: return sskilldes
