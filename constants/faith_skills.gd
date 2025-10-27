extends Node
class_name FaithSkills

const FAITH_SKILLS := {

	# 🔥 Infernal Powers
	"infernal_powers": [
		{
			"id": "inf_sacrificial_knife",
			"name": "Sacrificial Knife",
			"desc": "Deliver the killing blow to fuel your Sinister Power.",
			"conviction_req": 1,
			"icon": "res://assets/ui/faith/inf_skills/infskill_1.png"
		},
		{
			"id": "inf_summon_imp",
			"name": "Summon Imp",
			"desc": "Summon a weak servant of Hell for minor support.",
			"conviction_req": 3,
			"icon": "res://assets/ui/faith/inf_skills/infskill_2.png"
		},
		{
			"id": "inf_hex_madness",
			"name": "Hex of Madness",
			"desc": "Twist the minds of the weak into blind frenzy.",
			"conviction_req": 5,
			"icon": "res://assets/ui/faith/inf_skills/infskill_3.png"
		}
	],

	# 📜 Catechisms
	"catechisms": [
		{
			"id": "cat_catechism",
			"name": "Catechism",
			"desc": "You recite the devotions of your faith.",
			"conviction_req": 1,
			"icon": "res://assets/ui/faith/cat_skills/catskill_1.png"
		},
		{
			"id": "cat_craft_prayer_beads",
			"name": "Craft Prayer Beads",
			"desc": "Used to count the repetitive prayers of your faith. One should recite the Catechism with these in hand.",
			"conviction_req": 3,
			"icon": "res://assets/ui/faith/cat_skills/catskill_2.png"
		},
		{
			"id": "cat_sign_cross",
			"name": "Sign of the Cross",
			"desc": "A physical declaration of your faith. Used to sanctify oneself and defend against evil forces.",
			"conviction_req": 5,
			"icon": "res://assets/ui/faith/cat_skills/catskill_3.png"
		}
	],

	# 🙏 Devotionals
	"devotionals": [
		{
			"id": "dev_scripture_meditation",
			"name": "Scripture Meditation",
			"desc": "You reflect on the sacred texts to gain understanding and connection to your God; you require the Holy Teachings to perform this.",
			"conviction_req": 1,
			"icon": "res://assets/ui/faith/dev_skills/devskill_1.png"
		},
		{
			"id": "dev_craft_wooden_cross",
			"name": "Craft Wooden Cross",
			"desc": "You make and carry the crucifix to wield your faith against evil forces, praying with this sacred symbol in hand.",
			"conviction_req": 3,
			"icon": "res://assets/ui/faith/dev_skills/devskill_2.png"
		},
		{
			"id": "dev_dour",
			"name": "Dour",
			"desc": "Your growing faith is becoming noticeable. Your manner grows distant and haughty; your charisma is negatively affected.",
			"conviction_req": 5,
			"icon": "res://assets/ui/faith/dev_skills/devskill_3.png"
		}
	],

	# 🔥 Holy Ghost Power
	"holy_ghost_power": [
		{
			"id": "hgp_joyful_shouting",
			"name": "Joyful Shouting",
			"desc": "You call openly to God, praising His love and charity.",
			"conviction_req": 1,
			"icon": "res://assets/ui/faith/hgp_skills/hgpskill_1.png"
		},
		{
			"id": "hgp_rebuke",
			"name": "Rebuke",
			"desc": "You curse the wicked to their faces, making them shrivel and shrink away, their soul shaken.",
			"conviction_req": 3,
			"icon": "res://assets/ui/faith/hgp_skills/hgpskill_2.png"
		},
		{
			"id": "hgp_speak_tongues",
			"name": "Speak in Tongues",
			"desc": "Your growing faith is becoming noticeable. Your manner grows warm and vibrant; your charisma is positively affected.",
			"conviction_req": 5,
			"icon": "res://assets/ui/faith/hgp_skills/hgpskill_3.png"
		}
	],

	# 🌿 Druidic Rituals
	"druidic_rituals": [
		{
			"id": "dru_commune",
			"name": "Commune",
			"desc": "You call to the spirits and ancestors as it has always been done.",
			"conviction_req": 1,
			"icon": "res://assets/ui/faith/dru_skills/druskill_1.png"
		},
		{
			"id": "dru_animal_magnetism",
			"name": "Animal Magnetism",
			"desc": "There is something animal about you; you inspire affection easily.",
			"conviction_req": 3,
			"icon": "res://assets/ui/faith/dru_skills/druskill_2.png"
		},
		{
			"id": "dru_summon_animal",
			"name": "Summon Animal",
			"desc": "The spirits send beasts to aid their loyal.",
			"conviction_req": 5,
			"icon": "res://assets/ui/faith/dru_skills/druskill_3.png"
		}
	],

	# 👑 The Rites of Rex
	"the_rites_of_rex": [
		{
			"id": "rex_oath",
			"name": "Swear Oath",
			"desc": "You swear an Oath to the King of the World for his wisdom, tenacity, and creative spirit.",
			"conviction_req": 1,
			"icon": "res://assets/ui/faith/rex_skills/rexskill_1.png"
		},
		{
			"id": "rex_craft_coin",
			"name": "Craft Rex's Coin",
			"desc": "Rex teaches that all is his, all has value. We honor the King of the World by holding his image when we make our daily trades—sometimes he notices.",
			"conviction_req": 3,
			"icon": "res://assets/ui/faith/rex_skills/rexskill_2.png"
		},
		{
			"id": "rex_craft_hammer",
			"name": "Craft Rex's Hammer",
			"desc": "Rex teaches that all is his, all has value. We honor the King of the World by holding his image when we work—sometimes he notices.",
			"conviction_req": 5,
			"icon": "res://assets/ui/faith/rex_skills/rexskill_3.png"
		}
	],

	# 🌌 Eldritch Invocations
	"eldritch_invocations": [
		{
			"id": "eld_channel",
			"name": "Channel",
			"desc": "You focus on the jet black sky widening above you. You feel something is watching back.",
			"conviction_req": 1,
			"icon": "res://assets/ui/faith/eld_skills/eldskill_1.png"
		},
		{
			"id": "eld_craft_statue",
			"name": "Craft Strange Statue",
			"desc": "Your visions made manifest; you feel like you've made these before, and you feel weirdly quickened holding it in your hand.",
			"conviction_req": 3,
			"icon": "res://assets/ui/faith/eld_skills/eldskill_2.png"
		},
		{
			"id": "eld_glimpse_beyond",
			"name": "Glimpse of Beyond",
			"desc": "You can cast your strange visions onto another with the slightest gesture, but only for a moment—some go mad, some are blinded, some seem not to notice...",
			"conviction_req": 5,
			"icon": "res://assets/ui/faith/eld_skills/eldskill_3.png"
		}
	],

	# ⚫ Negation
	"negation": [
		{
			"id": "neg_meditate",
			"name": "Meditate",
			"desc": "You focus on what is, what could be, what should be—and regain some sanity.",
			"conviction_req": 1,
			"icon": "res://assets/ui/faith/neg_skills/negskill_1.png"
		},
		{
			"id": "neg_killjoy",
			"name": "Killjoy",
			"desc": "Your inner emptiness is becoming noticeable. Your charisma is negatively affected.",
			"conviction_req": 3,
			"icon": "res://assets/ui/faith/neg_skills/negskill_2.png"
		},
		{
			"id": "neg_null_personality",
			"name": "Nullifying Personality",
			"desc": "Your hollow presence is becoming stronger—you seem to drain magic and divine strength from others.",
			"conviction_req": 5,
			"icon": "res://assets/ui/faith/neg_skills/negskill_3.png"
		}
	],
}
