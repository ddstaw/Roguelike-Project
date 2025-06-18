extends Control

#Race Popup stuff
func RacePopup(slot : Rect2i, race : Race):
	if race != null:
		set_value_race(race)
		%RacePopup.size = Vector2i.ZERO

	var mouse_pos = get_viewport().get_mouse_position()
	var correction
	var padding = 10
	var vertical_offset = 40
	
	if mouse_pos.x <= get_viewport_rect().size.x/2:
		correction = Vector2i(slot.size.x + padding,vertical_offset)
	else:
		correction = -Vector2i(%RacePopup.size.x + padding,-vertical_offset)
	
	%RacePopup.popup(Rect2i( slot.position + correction, %RacePopup.size ))
	
func HideRacePopup(slot, race):
	%RacePopup.hide()
	
func set_value_race(race : Race):
	%Racename.text = race.racename
	%Raceflavor.text = set_flavortext_effect(race.raceflavor)
	%Racebonus.text = set_bonustext_effect(race.racebonus)
	
func set_flavortext_effect(raceflavor : String):
	var text : String = raceflavor
	match raceflavor:
		"Humaninfo":
			text = "Beggers and Kings, Saints and Devils.\nThe most common race on the planet, but hardly respectable.\n\nSkilled in both [color=89cff0]Tech[/color] and [color=#ff20fe]Magick[/color]"
		"Dwarfinfo":
			text = "The mountain folk, the technological forebearers.\nA hardy and innovative people but often\ntoo smart for their own good.\n\nInclined towards [color=89cff0]Technological Disciplines[/color]"
		"Elfinfo":
			text = "The forest dwellers, nymphs of the woods.\nThe oldest race and most mystic,\nmaking them somewhat flightly and shrill. \n\nInclined towards [color=#ff20fe]Arcane Traditions[/color]"
		"Orcinfo":
			text = "The children of the earth, possessing a frightening vitality.\nTreated by the other races as low-bred brutes,\ntheir lives are typically no bed of roses.\n\nSkilled in both [color=89cff0]Tech[/color] and [color=#ff20fe]Magick[/color]"
	
	return text
	
func set_bonustext_effect(racebonus : String):
	var text : String = racebonus
	match racebonus:
		"Human":
			text = "Racial Bonus: [color=yellow]+1[/color] to [color=yellow]All Attributes[/color]"
		"Dwarf":
			text = "Racial Bonus: [color=yellow]+2[/color] to [color=red]Strength[/color] and [color=89cff0]Endurance[/color]"
		"Elf":
			text = "Racial Bonus: [color=yellow]+2[/color] to [color=purple]Perception[/color] and [color=green]Charisma[/color]"
		"Orc":
			text = "Racial Bonus: [color=yellow]+2[/color] to [color=red]Strength[/color] and [color=orange]Agility[/color]"
	
	return text

#Faith Popup stuff
func FaithPopup(slot: Rect2, faith: Faith):
	# Reference the FaithPopup node correctly
	var faith_popup = $UI/FaithPopup
	if !is_instance_valid(faith_popup):
		print("Error: FaithPopup node is not valid or not found.")
		return  # Exit if FaithPopup node is not valid

	# Check if faith object is valid before proceeding
	if faith != null:
		set_value(faith)
		faith_popup.set_size(Vector2.ZERO)  # Reset the popup size safely using set_size()

	# Define a fixed position for the popup; adjust coordinates as needed
	var fixed_position = Vector2(45, 440)  # Example fixed position; change to desired location
	var padding = 0
	var correction = Vector2(padding, 2)  # Optional correction for fine-tuning position

	# Set the popup at the fixed position with the specified size
	faith_popup.popup(Rect2(fixed_position + correction, faith_popup.get_size()))


	
func HideFaithPopup():
	%FaithPopup.hide()

func set_value(faith : Faith):
	%Faithname.text = faith.faithname
	%Faithflavor.text = set_flavortext_effect_faith(faith.faithflavor)
	%Faithdes.text = set_descriptext_effect(faith.faithdes)
	%Faithbonus.text = set_bonustext_effect_faith(faith.faithbonus)
	
func set_flavortext_effect_faith(faithflavor : String):
	var text : String = faithflavor
	match faithflavor:
		"Orthoflav":
			text = "[i]I Suffer for Your Glory[/i]"
		"Refoflav":
			text = "[i]I am your Servant O' Mighty Lord[/i]"
		"Fundflav":
			text = "[i]He Manifests through my Body![/i]"
		"Sataflav":
			text = "[i]Do What Thou Will[/i]"
		"Esotflav":
			text = "[i]I hear, I obey[/i]"
		"Oldwflav":
			text = "[i]I Walk the Anicent Ways[/i]"
		"Rexmflav":
			text = "[i]By Rex's Beard![/i]"
		"Godlflav":
			text = "[i]Get that God Nonsense out of my face[/i]"
	
	return text
	
func set_descriptext_effect(faithdes : String):
	var text : String = faithdes
	match faithdes:
		"Orthodes":
			text = "The oldest organized sect are known as the [color=CC3333]Orthodox[/color].\nThey gather in Great old Catherdals under a [color=CC3333]Pontiff[/color].\nA religion based in [color=CC3333]catechism and ritual[/color],\npenitents carry [color=CC3333]rosaries[/color] while doing prayer, \nstudy the [color=CC3333]lives of the saints[/color], give charity,\nand be kind and forgiving for the blessings of God.\nA popular religion in cities and towns and \namong the feared [color=CC3333]Witchhunters[/color] of the Inquisition."
		"Refodes":
			text = "The most common sect in villages is the [color=99ccff]Reformationist[/color] Church they gather in halls known as Churches under a [color=99ccff]Archminister[/color]. Puritanical and stern, it is based mostly on acts of [color=99ccff]prayer[/color] and giving charity, as well as doing kind and noble acts in God's name. They must regularly attend church on sunday, study their [color=99ccff]Bibles[/color] to continue \nto receive God's [color=99ccff]Divine Blessings[/color]."
		"Funddes":
			text = "The zealots of the city slums and villages are known as [color=ff9966]Fundamentalists[/color], they gather in large halls called [color=ff9966]Tabernacles[/color]. The God of this sect although in theory is the same as the God of the [color=CC3333]Orthodox[/color] and [color=99ccff]Reformationist[/color], This God [color=ff9966]speaks[/color] to his followers, asking them sometimes to do [color=ff9966]strange acts[/color] but otherwise similar, asking only for prayer, charity, good works and mercy."
		"Satades":
			text = "The foul cult of [color=ED2939]devil worship[/color] and [color=ED2939]demon summoning[/color], they gather in cabals hidden in weathly homes in cities and villages. Their leader is known as a [color=ED2939]High Cultist[/color], they ask their followers to do [color=ED2939]blood sacrifice[/color] of humans, animals and monsters alike with [color=ED2939]cursed daggers[/color]. Their Satantic god loves [color=ED2939]horrible acts, lies, crime and all forms of evil[/color], rewarding his cultists with [color=ED2939]Infernal Servants[/color]."
		"Esotdes":
			text = "Followers of the void are known as [color=34e8eb]Esoteric Orders[/color]\nthey gather in abandoned places under a [color=34e8eb]Great One.\n[/color]The void speaks directly to you and asks you\nsometimes horrible, sometime [color=34e8eb]strange[/color] acts.\nServe the void by obeying it's requests,\nacts of prayer, studying [color=34e8eb]Esoteric Tomes[/color], \nbut be ready for the void is capricious - [color=34e8eb]\nit gives it's blessings and curses with no reason.[/color]"
		"Oldwdes":
			text = "The [color=25D366]nature religion[/color] of the old world, followed by the Elves. Their temples still exist in the Elf Havens, maintained by [color=25D366]Druids[/color]. The way of the great mages and warriors of history. They pray, do rituals, do [color=25D366]acts of power[/color] to venerate the Old Gods.The pagan gods are [color=25D366]capricious[/color] and give their curses and blessings wildly, but they always [color=25D366]hate technology[/color] and love the old magicks."
		"Rexmdes":
			text = "The Dwarven God [color=3333ff]Rex Mundi[/color], known as the King of The World. Worshipped in Dwarven Temples headed by [color=3333ff]Clerics[/color]. He is the god of crafting, metallurgy, technology and trade. His disciples use [color=3333ff]lucky coins[/color] and other trinkets to call [color=3333ff]Rex's Favor[/color]. Worship is done by prayer, building, crafting and trading. The patron God of all merchants, craftsmen, and the generally [color=3333ff]pragmatic[/color]."
		"Godldes":
			text = "You follow [color=ffa500]no god[/color], you have no creed of divine devotion. This is a choice itself and has it's own [color=ffa500]unique power[/color]. The Godless are less effected by magicks and divine powers, their [color=ffa500]lack of faith[/color] seems to negate the supernatural. The Godless are unable to be [color=ffa500]healed or helped by divine prayer[/color] but as trade-off, they also have [color=ffa500]little to fear[/color] from divine attack."
	
	return text
	
func set_bonustext_effect_faith(faithbonus : String):
	var text : String = faithbonus
	match faithbonus:
		"Orthobonus":
			text = "Discordant to [color=#ff20fe]Magick Practitioners[/color]\nAffinitive to [color=89cff0]Technologists[/color]"
		"Refobonus":
			text = "Indifferent to [color=#ff20fe]Magick Practitioners[/color]\nIndifferent to [color=89cff0]Technologists[/color]"
		"Fundbonus":
			text = "Affinitive to [color=#ff20fe]Magick Practitioners[/color]\nIndifferent to [color=89cff0]Technologists[/color]"
		"Satabonus":
			text = "Affinitive to [color=#ff20fe]Magick Practitioners[/color]\nIndifferent to [color=89cff0]Technologists[/color]"
		"Esotbonus":
			text = "Affinitive to [color=#ff20fe]Magick Practitioners[/color]\nIndifferent to [color=89cff0]Technologists[/color]"
		"Oldwbonus":
			text = "Affinitive to [color=#ff20fe]Magick Practitioners[/color]\nDiscordant to [color=89cff0]Technologists[/color]"
		"Rexmbonus":
			text = "Discordant to [color=#ff20fe]Magick Practitioners[/color]\nAffinitive to [color=89cff0]Technologists[/color]"
		"Godlbonus":
			text = "Indifferent to [color=#ff20fe]Magick Practitioners[/color]\nAffinitive to [color=89cff0]Technologists[/color]"
	
	return text

#General Skill Popup stuff
func GskillPopup(slot: Rect2, gskill: GSkill):
	# Reference the FaithPopup node correctly
	var gskill_popup = $UI/GskillPopup
	if !is_instance_valid(gskill_popup):
		print("Error: GskillPopup node is not valid or not found.")
		return  # Exit if FaithPopup node is not valid

	# Check if faith object is valid before proceeding
	if gskill != null:
		set_value_gskill(gskill)
		gskill_popup.set_size(Vector2.ZERO)  # Reset the popup size safely using set_size()

	# Define a fixed position for the popup; adjust coordinates as needed
	var fixed_position = Vector2(23, 486)  # Example fixed position; change to desired location
	var padding = 0
	var correction = Vector2(padding, 2)  # Optional correction for fine-tuning position

	# Set the popup at the fixed position with the specified size
	gskill_popup.popup(Rect2(fixed_position + correction, gskill_popup.get_size()))


	
func HideGskillPopup():
	%GskillPopup.hide()

func set_value_gskill(gskill : GSkill):
	%Gskillname.text = gskill.gskillname
	%Gskillflavor.text = set_flavortext_effect_gskill(gskill.gskillflavor)
	%Gskilldes.text = set_gskilldescriptext_effect(gskill.gskilldes)
	
func set_flavortext_effect_gskill(gskillflavor : String):
	var text : String = gskillflavor
	match gskillflavor:
		"pugflav":
			text = "[i]The Gentle Art of Fisticuffs[/i]"
		"acumenflav":
			text = "[i]The Art of Tradecraft[/i]"
		"alchemyflav":
			text = "[i]The Simple Sciences[/i]"
		"athleticsflav":
			text = "[i]The Vigorous Pursuit of Endurance[/i]"
		"blacksflav":
			text = "[i]The Ancient Art of Hammer and Anvil[/i]"
		"boweryflav":
			text = "[i]The Noble Craft of Arrow and String[/i]"
		"bruteflav":
			text = "[i]The Savage Power of Sheer Might[/i]"
		"deftflav":
			text = "[i]The Dance of the Blade[/i]"
		"pugflav":
			text = "[i]The Gentle Art of Fisticuffs[/i]"
		"conflav":
			text = "[i]Denbuilding and Furnishings[/i]"
		"eruflav":
			text = "[i]The Aristocratic Obligation[/i]"
		"fireflav":
			text = "[i]The Gunner's Art[/i]"
		"metflav":
			text = "[i]The Knowledge of Fire and Ore[/i]"
		"frontflav":
			text = "[i]The Skill of Rugged Individualism[/i]"
		"skuflav":
			text = "[i]The Criminal Professions[/i]"
		"talflav":
			text = "[i]The Skill of Needle and Thread[/i]"
		"bowmanflav":
			text = "[i]Distance with Deadly Intent[/i]"
			
	return text
	
func set_gskilldescriptext_effect(gskilldes : String):
	var text : String = gskilldes
	match gskilldes:
		"pugdes":
			text = "Sometimes guns misfire, sometimes spells miscast, you must take things into your own hands. Landing a punch is just the beginning, masters of pugilism employ a variety of dirty tricks to insure their victory, including pocket sand, leg sweeps, groin kicks and Eye-gouging."
		"acumendes":
			text = "Buy for better prices, sell for better prices, see more inventory, get more out of your deals and make your money work for you."
		"alchemydes":
			text = "The skill of the cunning folk, brew simple potions and poisons from local flora."
		"athleticsdes":
			text = "The body is a temple, treat it well. Improve your body and learn to sprint, lounge, crawl, climb, swim and traverse the perils of life with ease."
		"blacksdes":
			text = "The production of metal armors, weapons, shields. The dwarven art still has it's useage in this modern era for the adventurer."
		"bowerydes":
			text = "The production of stringed ranged weapons, including war bows, crossbows and their respective bolts and arrows. A practical skill for any nomad."
		"brutedes":
			text = "The advanced techniques for greatswords, great axes, mauls and all heavy weaponry. For smashing, cleaving, wild swinging and tearing your foes into pieces."
		"deftdes":
			text = "The assassin's art - the advanced techniques for daggers, rapiers, polearms and whips. For precision and critical armor penetration."
		"condes":
			text = "The handiwork knowhow for construction of beds, chests, walls, doors and much more. Every adventurer needs a hideout to lick their wounds, make it suitable."
		"erudes":
			text = "The ability to read, the knowledge of the greater world and it's rich history. You won't be invited back to any dinner parties without some refinement."
		"firedes":
			text = "You don't need a doctorate to pull a trigger but some pratice will help. The skill of handling firearms insures you get your money's worth from your sidearm."
		"metdes":
			text = "The old art of turning mineral into metal. Knowledge of the earth's riches gives the ability to smelt, identify minerals and extract them in greater amounts, a must for any blacksmith or rare gem tradesman."
		"frontdes":
			text = "Living off the land, making campfires, waterskins, skinning beasts - the art of the pioneer, the peasant and the greatest heroes."
		"skudes":
			text = "It is a sad state of affairs but many an adventurer is driven to criminal talents - sometimes you need an edge: lockpicking, sneaking, pickpocketing and intimidation may unlock opportunities that charm and wit cannot."
		"taldes":
			text = "The fashionable craft of cloth and leather. All sorts of finery: shirts, boots, capes, hats, belts will be yours to wear and sell with mastery of this profitable skill."
		"bowmandes":
			text = "Strike your foes from a distance with ease with your refined skill in archery. Masters of archery can fire multiple arrows at once, target heads, legs and cut through the armor of the most well padded foes."
			
	return text
	
	#Special Skill Popup stuff
func SskillPopup(slot: Rect2, sskill: SSkill):
	# Reference the SskillPopup node correctly
	var sskill_popup = $UI/SskillPopup
	if !is_instance_valid(sskill_popup):
		print("Error: SskillPopup node is not valid or not found.")
		return  # Exit if FaithPopup node is not valid

	# Check if faith object is valid before proceeding
	if sskill != null:
		set_value_sskill(sskill)
		sskill_popup.set_size(Vector2.ZERO)  # Reset the popup size safely using set_size()

	# Define a fixed position for the popup; adjust coordinates as needed
	var fixed_position = Vector2(23, 486)  # Example fixed position; change to desired location
	var padding = 0
	var correction = Vector2(padding, 2)  # Optional correction for fine-tuning position

	# Set the popup at the fixed position with the specified size
	sskill_popup.popup(Rect2(fixed_position + correction, sskill_popup.get_size()))


	
func HideSskillPopup():
	%SskillPopup.hide()

func set_value_sskill(sskill : SSkill):
	%Sskillname.text = sskill.sskillname
	%Sskillflavor.text = set_flavortext_effect_sskill(sskill.sskillflavor)
	%Sskilldes.text = set_sskilldescriptext_effect(sskill.sskilldes)
	
func set_flavortext_effect_sskill(sskillflavor : String):
	var text : String = sskillflavor
	match sskillflavor:
		"chemflav":
			text = "[color=7f9aa3]The Discipline of Reactive Formulations[/color]"
		"cyroflav":
			text = "[color=2b8dbf]The Tradition of Gelid Mysteries[/color]"
		"enchflav":
			text = "[color=6B4AD4]The Tradition of Mystic Imbuing[/color]"
		"expflav":
			text = "[color=7f9aa3]The Discipline of Radical Armament Design[/color]"
		"fulmflav":
			text = "[color=e4d70d]The Tradition of Tempestology[/color]"
		"glamflav":
			text = "[color=fa14d7]The Tradition of Phantasmagoria[/color]"
		"gunsflav":
			text = "[color=7f9aa3]The Discipline of Mechanized Ballistics[/color]"
		"necrflav":
			text = "[color=5b5b5b]The Loathesome Tradition of Revenants[/color]"
		"pyroflav":
			text = "[color=b21515]The Tradition of Conflagration[/color]"
		"roboflav":
			text = "[color=7f9aa3]The Discipline of Automaton Engineering[/color]"
		"thauflav":
			text = "[color=a38ba3]The Tradition of Miracle Making[/color]"
		"tinkflav":
			text = "[color=7f9aa3]The Discipline of Mechanical Craftwork[/color]"
		"venoflav":
			text = "[color=32ba35]The Tradition of Venefic Arts[/color]"
		"vitoflav":
			text = "[color=0adfbe]The Tradition of Restorative Arts[/color]"
		"wandflav":
			text = "[color=a3624b]The Tradition of Arcane Conduits[/color]"
			
	return text
	
func set_sskilldescriptext_effect(sskilldes : String):
	var text : String = sskilldes
	match sskilldes:
		"chemdes":
			text = "Taught in City Universities and by village academics. The Formulation and Manipulation of Reactive Chemical Compounds"
		"cyrodes":
			text = "An elemental school taught by the Druids of the Elf Havens, The Mages Guild in Cities, and itinerant Arcanists. The cold dominion. For freezing enemies in their tracks, summoning blizzards, erecting barriers of ice, and chilling the very marrow"
		"enchdes":
			text = "A strange school known only to itinerant Arcanists. The art of imbuing and enchanting. For infusing objects with arcane power, binding spells to trinkets, and bestowing charms upon allies"
		"expdes":
			text = "Taught in Military Universities and via Black Market means. The Innovation and Testing of Novel Combative Apparatuses"
		"fulmdes":
			text = "An elemental school taught by the Druids of the Elf Havens, The Mages Guild in Cities, and itinerant Arcanists. The volatile command of thunder and lightning. For striking with bolts from the heavens, harnessing storms, and electrifying the battlefield"
		"glamdes":
			text = "A flashy foppish school practiced by mostly city mages. Magick fraud and deception. For weaving veils of invisibility, beguiling foes, creating diversions, misdirection, and sowing discord, it is the favored craft of the charlatan and conjurer alike."
		"gunsdes":
			text = "Taught in The Gunsmithing Guild by it's instructors. The Refinement and Iterative Production of Precision Kinetic Ballistic Devices"
		"necrdes":
			text = "The forbidden practice of grave desecration and bringing forth the curse of undeath by using entropic magickal energy is banned in the Elf Haven and by the City Mage's Guild. It can only be learned by hermit necromancers who live near places of decay and death, you may find them in sewers, graveyards, and abandoned buildings"
		"pyrodes":
			text = "An elemental school taught by the Druids of the Elf Havens, The Mages Guild in Cities, and itinerant Arcanists. The fiery command of flame and inferno. For conjuring fireballs, scorching foes, igniting surroundings, and unleashing raging infernos"
		"robodes":
			text = "Taught in City Universities and by mad academics. The Assembly and Advancement of Autonomous Mechanical Constructs"
		"thaudes":
			text = "A strange school known only to itinerant Arcanists. The practice of miracles and arcane wonders. For manipulating reality, bending the laws of nature, and summoning the extraordinary"
		"tinkdes":
			text = "Taught by local repairmen and itinerant academics. The Design and Modification of Mechanical Apparatuses"
		"venodes":
			text = "A foul school taught by slum mages in the Capital City. The noxious art of poisons and toxins. For crafting venoms, corrupting the blood, envenoming blades, and unleashing deadly mists"
		"vitodes":
			text = "An elemental school taught by the Druids of the Elf Havens, The Mages Guild in Cities, and itinerant Arcanists. The healing and vital arts. For mending wounds, restoring vigor, curing ailments, and rejuvenating the spirit"
		"wanddes":
			text = "A strange arcane practice learned only in the Elf Haven by Wandsmiths. The meticulous crafting of magical foci. For channeling spells, amplifying power, and guiding arcane energies"
					
	return text
