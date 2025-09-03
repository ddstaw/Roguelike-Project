# item_data.gd
extends Node

const ITEM_PROPERTIES := {
	"MAT0001": {
		"base_display_name": "Wood Log",
		"fire_fuel": true,
		"stackable": true,
		"max_stack": 999,
		"weight_per": 10,
		"avg_value_per": 2,
		"type": "Mat",
		"img_path": "res://assets/inv/wood-logs.png",
		"des": "A log chopped from a tree, can be fashioned into many things"
	},
	"MAT0002": {
		"base_display_name": "Bones",
		"stackable": true,
		"max_stack": 999,
		"weight_per": 1,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/bones.png",
		"des": "Bones from a dead creature."
	},
	"MAT0003": {
		"base_display_name": "Leaf",
		"stackable": true,
		"fire_fuel": true,
		"max_stack": 999,
		"weight_per": 1,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/leaf.png",
		"des": "Simple plant cuttings."
	},
	"MAT0004": {
		"base_display_name": "Metal Scrap",
		"stackable": true,
		"max_stack": 999,
		"weight_per": 3,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/metal_scrap.png",
		"des": "Various metal bits and ends."
	},
	"MAT0005": {
		"base_display_name": "Old Glasses",
		"stackable": true,
		"max_stack": 999,
		"weight_per": 1,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/old_glasses.png",
		"des": "Discarded pair of spectacles."
	},
	"MAT0006": {
		"base_display_name": "Plant Fiber",
		"stackable": true,
		"fire_fuel": true,
		"max_stack": 999,
		"weight_per": 1,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/plant_fiber.png",
		"des": "Planet fiber pulled from a bush."
	},
	"MAT0007": {
		"base_display_name": "Rock",
		"stackable": true,
		"max_stack": 999,
		"weight_per": 3,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/rock.png",
		"des": "A rock from the ground."
	},
	"CON0001": {
		"base_display_name": "Red Berries",
		"stackable": true,
		"can_eat": true,
		"food_qty": 2,
		"max_stack": 999,
		"weight_per": 0.1,
		"avg_value_per": 0,
		"type": "Con",
		"img_path": "res://assets/inv/berries.png",
		"des": "Red Berries from a bush."
	},
	"CON0002": {
		"base_display_name": "Worms",
		"stackable": true,
		"fishing_bait": true,
		"can_eat": true,
		"food_qty": 1,
		"max_stack": 999,
		"weight_per": 0.1,
		"avg_value_per": 0,
		"type": "Con",
		"img_path": "res://assets/inv/worm.png",
		"des": "Squirming insect. Can be used for fishing bait."
	},
	"CON0003": {
		"base_display_name": "Simple Bandage",
		"stackable": true,
		"med_bleeding": true,
		"med_general": true,
		"med_general_qty": 5,
		"max_stack": 999,
		"weight_per": 0.2,
		"avg_value_per": 1,
		"type": "Con",
		"img_path": "res://assets/inv/simple_bandage.png",
		"des": "Cloth rag cleaned and treated with healing herbs. Treats bleeding and minor wounds."
	},
	"CON0004": {
		"base_display_name": "Small Jug",
		"fillable": true,
		"drinkable": true,
		"pourable": true,
		"max_fill": 5,
		"weight_per": 2,
		"avg_value_per": 5,
		"type": "Con",
		"img_path": "res://assets/inv/water_jug.png",
		"des": "A small ceramic container for liquids."
	},
	"ARM0001": {
		"base_display_name": "Iron Knight Helm",
		"weight_per": 5,
		"avg_value_per": 35,
		"type": "Arm",
		"img_path": "res://assets/inv/iron_knight_helm.png",
		"des": "A knightly helment crafted from iron."
	},
	"WEAP0001": {
		"base_display_name": "Iron Knife",
		"weight_per": 2,
		"avg_value_per": 15,
		"type": "Weap",
		"img_path": "res://assets/inv/iron_knife.png",
		"des": "A small knife with an iron blade."
	},
	"LOOT0001": {
		"base_display_name": "Blueprint",
		"readable": true,
		"weight_per": 0.1,
		"avg_value_per": 105,
		"type": "Loot",
		"img_path": "res://assets/inv/blueprint.png",
		"des": "A photographic reproduction of a technical drawing for an enginnering design."
	},
	"LOOT00002": {
		"base_display_name": "Coins",
		"readable": true,
		"weight_per": 0.1,
		"avg_value_per": 1,
		"max_stack": 999,
		"type": "Loot",
		"img_path": "res://assets/inv/gold_coins.png",
		"des": "A pile of currency."
	}
}
