extends Node

const NODE_TABLE := {
	"bush": {
		"possible_items": {
			"CON0001": { "max_qty": 6,  "weight": 10 }, # Red Berries
			"CON0002": { "max_qty": 8,  "weight": 7  }, # Worms
			"MAT0003": { "max_qty": 12, "weight": 12 }, # Leaf
			"MAT0006": { "max_qty": 10, "weight": 9  }, # Plant Fiber
			"MAT0007": { "max_qty": 4,  "weight": 3  }  # Rock
		}
	},

	"flowers": {
		"possible_items": {
			"MAT0008": { "max_qty": 3, "weight": 6 }, # White Flower
			"MAT0013": { "max_qty": 3, "weight": 6 }, # Red Flower
			"MAT0016": { "max_qty": 1, "weight": 1 }, # Rare Flower
			"MAT0017": { "max_qty": 3, "weight": 5 }, # Purple Flower
			"CON0002": { "max_qty": 4, "weight": 3 }  # Worms
		}
	},

	"tree": {
		"possible_items": {
			"MAT0001": { "max_qty": 6, "weight": 14 }, # Wood Log
			"MAT0012": { "max_qty": 2, "weight": 2  }, # Resin (rare)
			"CON0005": { "max_qty": 2, "weight": 2  }, # Apple (rare)
			"MAT0023": { "max_qty": 3, "weight": 4  }, # Feather
			"CON0012": { "max_qty": 2, "weight": 3  }  # Egg
		}
	},

	"woodchest": {
		"max_rare": 6, # cap rare entries per chest
		"possible_items": {
			# Common
			"MAT0004": { "max_qty": 6, "weight": 10, "rarity": "common" }, # Metal Scrap
			"MAT0009": { "max_qty": 5, "weight": 9,  "rarity": "common" }, # Twine
			"CON0003": { "max_qty": 4, "weight": 8,  "rarity": "common" }, # Simple Bandage
			"ARM0002": { "max_qty": 1, "weight": 5,  "rarity": "common" }, # Cloth Boots
			"UTIL0003": { "max_qty": 2, "weight": 6,  "rarity": "common" }, # Lockpicks
			"UTIL0002": { "max_qty": 2, "weight": 6,  "rarity": "common" }, # Candle

			# Rare
			"ARM0001": { "max_qty": 1, "weight": 1, "rarity": "rare" }, # Iron Knight Helm
			"ARM0004": { "max_qty": 1, "weight": 1, "rarity": "rare" }, # Cloth Backpack (verify ID)
			"WEAP0012": { "max_qty": 1, "weight": 1, "rarity": "rare" }, # Nobleman Pistol
			"WEAP0013": { "max_qty": 1, "weight": 1, "rarity": "rare" }, # Evil Knife
			"LOOT0001": { "max_qty": 1, "weight": 1, "rarity": "rare" }, # Blueprint
			"LOOT0002": { "max_qty": 50,"weight": 2, "rarity": "rare" }, # Coins (use LOOT00002 if that's your ID)
			"LOOT0003": { "max_qty": 1, "weight": 1, "rarity": "rare" }  # Cut Ruby
		}
	},

	"bluewizard": {
		# Vendor inventory roll: very random, any subset of the pool.
		# Use "weight" for likelihood and "max_qty" for how many of that item can appear.
		"possible_items": {
			"LOOT0001":  { "max_qty": 1,   "weight": 6  }, # Blueprint
			"LOOT0002":  { "max_qty": 300, "weight": 14 }, # Coins (swap to LOOT00002 if needed)
			"LOOT0003":  { "max_qty": 1,   "weight": 3  }, # Cut Ruby
			"LOOT00004": { "max_qty": 2,   "weight": 8  }, # Weird Book
			"LOOT00005": { "max_qty": 1,   "weight": 5  }, # Skill Book: Training
			"LOOT00006": { "max_qty": 1,   "weight": 6  }, # Holy Book
			"LOOT00007": { "max_qty": 1,   "weight": 4  }, # Grimoire
			"LOOT00008": { "max_qty": 2,   "weight": 5  }, # Gold Ring
			"LOOT00009": { "max_qty": 1,   "weight": 5  }  # Evil Book
		}
	}
}
