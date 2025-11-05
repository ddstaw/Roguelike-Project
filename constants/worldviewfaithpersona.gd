extends Node

const WORLDVIEW_FAITH_PERSONA := {
	"Orthodox": {
		"Devout": {"title": "The Penitent Knight", "type": "Synergy", "desc": "Steadfast, reverent, unshakable."},
		"Humanist": {"title": "The Compassionate Priest", "type": "Synergy", "desc": "Warm, forgiving, charitable."},
		"Rationalist": {"title": "The Doubting Theologian", "type": "Clash", "desc": "Questioning, sardonic about rituals."},
		"Nihilist": {"title": "The Hollow Inquisitor", "type": "Clash", "desc": "Bitter, condemns faith as empty."},
		"Occultist": {"title": "The Mystic Confessor", "type": "Twist", "desc": "Cryptic saint-seer, speaks in riddles."},
		"Profiteer": {"title": "The Political Pontiff", "type": "Twist", "desc": "Worldly, transactional, calculating."}
	},

	"Reformation": {
		"Devout": {"title": "The Stern Puritan", "type": "Synergy", "desc": "Strict, severe, devoutly pure."},
		"Humanist": {"title": "The Gentle Shepherd", "type": "Synergy", "desc": "Kind, community-minded."},
		"Rationalist": {"title": "The Scriptural Critic", "type": "Twist", "desc": "Sharp, reformist scholar."},
		"Nihilist": {"title": "The Preacher of Ashes", "type": "Clash", "desc": "Despairing, damns all."},
		"Occultist": {"title": "The Visionary Dissenter", "type": "Clash", "desc": "Mystical rebel, distrusted."},
		"Profiteer": {"title": "The Pragmatic Deacon", "type": "Twist", "desc": "Moral veneer, profit-driven."}
	},

	"Fundamentalist": {
		"Devout": {"title": "The Zealfire Prophet", "type": "Synergy", "desc": "Blazing faith, unquestioning."},
		"Humanist": {"title": "The Street Preacher", "type": "Clash", "desc": "Compassionate, clashes with zeal."},
		"Rationalist": {"title": "The Unwilling Vessel", "type": "Clash", "desc": "Skeptical of 'God’s voice.'"},
		"Nihilist": {"title": "The Fanatic of Nothing", "type": "Clash", "desc": "Wild zeal but hollow inside."},
		"Occultist": {"title": "The Ecstatic Madman", "type": "Twist", "desc": "Tongues, visions, chaos."},
		"Profiteer": {"title": "The Charlatan Prophet", "type": "Twist", "desc": "Exploits zeal for coin."}
	},

	"Sinister Cultist": {
		"Devout": {"title": "The Bloody Zealot", "type": "Synergy", "desc": "Revels in sacrifice, unwavering."},
		"Humanist": {"title": "The Reluctant Heretic", "type": "Clash", "desc": "Guilty, torn, compassionate streak."},
		"Rationalist": {"title": "The Dark Logician", "type": "Clash", "desc": "Cold, tries to systematize horror."},
		"Nihilist": {"title": "The Devourer of Hope", "type": "Synergy", "desc": "Cruel, nihilistic predator."},
		"Occultist": {"title": "The Occult Theurgist", "type": "Synergy", "desc": "Ritualistic, visionary sorcerer."},
		"Profiteer": {"title": "The Power-Broker of Hell", "type": "Twist", "desc": "Cynical, bargains with demons."}
	},

	"Void": {
		"Devout": {"title": "The True Vessel", "type": "Synergy", "desc": "Obedient, voices the abyss."},
		"Humanist": {"title": "The Compassionate Medium", "type": "Clash", "desc": "Tries to soften alien cruelty."},
		"Rationalist": {"title": "The Cosmic Skeptic", "type": "Clash", "desc": "Skeptical, laughs at the nonsense."},
		"Nihilist": {"title": "The Laughing Abyss", "type": "Synergy", "desc": "Serene in absurdity."},
		"Occultist": {"title": "The Whispered Seer", "type": "Synergy", "desc": "Cryptic prophet of nothingness."},
		"Profiteer": {"title": "The Pact-Maker", "type": "Clash", "desc": "Tries to profit from emptiness."}
	},

	"Old Ways": {
		"Devout": {"title": "The Druid of Oaks", "type": "Synergy", "desc": "Reverent, ritualistic, ancient."},
		"Humanist": {"title": "The Kind Greenhand", "type": "Synergy", "desc": "Healer, nurturer, protector."},
		"Rationalist": {"title": "The Skeptical Druid", "type": "Clash", "desc": "Pragmatic, doubts old gods."},
		"Nihilist": {"title": "The Cursed Wildling", "type": "Synergy", "desc": "Embraces nature’s cruelty."},
		"Occultist": {"title": "The Forest Oracle", "type": "Synergy", "desc": "Mysterious, cryptic, fae-touched."},
		"Profiteer": {"title": "The Pagan Merchant", "type": "Clash", "desc": "Mercenary, betrays the spirit."}
	},

	"Rex Mundi": {
		"Devout": {"title": "The Anointed Smith", "type": "Synergy", "desc": "Faithful craftsman, sanctifies work."},
		"Humanist": {"title": "The Guild Father", "type": "Synergy", "desc": "Builder of communities, fair dealer."},
		"Rationalist": {"title": "The Engineer of Faith", "type": "Synergy", "desc": "Scientific, orderly, constructive."},
		"Nihilist": {"title": "The Black Forge Nihilist", "type": "Clash", "desc": "Sees all work as dust."},
		"Occultist": {"title": "The Runecrafter", "type": "Clash", "desc": "Mystical in a pragmatic creed."},
		"Profiteer": {"title": "The Coin-Cleric", "type": "Synergy", "desc": "Honest merchant of faith."}
	},

	"Godless": {
		"Devout": {"title": "The Faithful Atheist", "type": "Clash", "desc": "Paradoxical zeal, fervent denial."},
		"Humanist": {"title": "The Ethical Skeptic", "type": "Synergy", "desc": "Moral compass without gods."},
		"Rationalist": {"title": "The Cold Realist", "type": "Synergy", "desc": "Grounded, logical, unshaken."},
		"Nihilist": {"title": "The Emptied Vessel", "type": "Synergy", "desc": "Embraces emptiness, detached."},
		"Occultist": {"title": "The Mystic Without Gods", "type": "Twist", "desc": "Spiritual but creedless."},
		"Profiteer": {"title": "The Pure Pragmatist", "type": "Synergy", "desc": "Survivalist, practical, self-reliant."}
	}
}
