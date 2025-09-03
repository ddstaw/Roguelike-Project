# npc_data.gd
extends Node

const ITEM_PROPERTIES := {
	"CRE0001": {
		"base_display_name": "Orange Cat",
		"max_hp": 50,
		"type": "animal",
		"faction": "feline",
		"img_path": "res://assets/localmap-graphics/npcs/orange_cat.png",
		"des": "A lazy looking orange cat"
	},
	"CRE0002": {
		"base_display_name": "Green Snake",
		"max_hp": 50,
		"type": "animal",
		"faction": "snake",
		"img_path": "res://assets/localmap-graphics/npcs/green_snake.png",
		"des": "A creepy green snake."
	},
	"NPC0001": {
		"base_display_name": "Blue Wizard",
		"max_hp": 100,
		"type": "humanoid",
		"faction": "regularfolk",
		"img_path": "res://assets/localmap-graphics/npcs/blue_wizard.png",
		"des": "A foolish looking old man in wizard robes and hat."
	}
}
