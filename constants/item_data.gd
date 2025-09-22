# item_data.gd
extends Node

const ITEM_PROPERTIES := {
	"MAT0001": {
		"base_display_name": "Wood Log",
		"fire_fuel": true,
		"stackable": true,
		"weight_per": 10,
		"avg_value_per": 2,
		"type": "Mat",
		"img_path": "res://assets/inv/wood-logs.png",
		"des": "A log chopped from a tree, can be fashioned into many things"
	},
	"MAT0002": {
		"base_display_name": "Bones",
		"stackable": true,
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
		"weight_per": 1,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/leaf.png",
		"des": "Simple plant cuttings."
	},
	"MAT0004": {
		"base_display_name": "Metal Scrap",
		"stackable": true,
		"weight_per": 3,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/metal_scrap.png",
		"des": "Various metal bits and ends."
	},
	"MAT0005": {
		"base_display_name": "Old Glasses",
		"stackable": true,
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
		"weight_per": 1,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/plant_fiber.png",
		"des": "Plant fiber pulled from a bush."
	},
	"MAT0007": {
		"base_display_name": "Rock",
		"stackable": true,
		"weight_per": 3,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/rock.png",
		"des": "A rock from the ground."
	},
	"MAT0008": {
		"base_display_name": "White Flower",
		"stackable": true,
		"weight_per": 0.1,
		"avg_value_per": 1,
		"type": "Mat",
		"img_path": "res://assets/inv/white_flower.png",
		"des": "A delicate white blossom used in simple remedies and dyes."
	},
	"MAT0009": {
		"base_display_name": "Twine",
		"stackable": true,
		"weight_per": 0.1,
		"avg_value_per": 1,
		"type": "Mat",
		"img_path": "res://assets/inv/twine.png",
		"des": "Plant fiber cord, useful for crafting."
	},
	"MAT0010": {
		"base_display_name": "Sulphur",
		"stackable": true,
		"weight_per": 1,
		"avg_value_per": 2,
		"type": "Mat",
		"img_path": "res://assets/inv/sulphur.png",
		"des": "A yellow mineral with many alchemical uses."
	},
	"MAT0011": {
		"base_display_name": "Steel Ingot",
		"stackable": true,
		"weight_per": 5,
		"avg_value_per": 20,
		"type": "Mat",
		"img_path": "res://assets/inv/steel_ingot.png",
		"des": "A refined bar of steel, ready for smithing."
	},
	"MAT0012": {
		"base_display_name": "Resin",
		"stackable": true,
		"weight_per": 0.5,
		"avg_value_per": 1,
		"type": "Mat",
		"img_path": "res://assets/inv/resin.png",
		"des": "Sticky tree resin used in crafting and sealing."
	},
	"MAT0013": {
		"base_display_name": "Red Flower",
		"stackable": true,
		"weight_per": 0.1,
		"avg_value_per": 1,
		"type": "Mat",
		"img_path": "res://assets/inv/red_flower.png",
		"des": "A bright blossom often used as a dye."
	},
	"MAT0014": {
		"base_display_name": "Raw Cotton",
		"stackable": true,
		"weight_per": 0.5,
		"avg_value_per": 2,
		"type": "Mat",
		"img_path": "res://assets/inv/raw_cotton.png",
		"des": "Fluffy cotton bolls, can be spun into cloth."
	},
	"MAT0015": {
		"base_display_name": "Raw Corn",
		"stackable": true,
		"weight_per": 1,
		"avg_value_per": 1,
		"type": "Mat",
		"img_path": "res://assets/inv/raw_corn.png",
		"des": "A cob of uncooked corn."
	},
	"MAT0016": {
		"base_display_name": "Rare Flower",
		"stackable": true,
		"weight_per": 0.1,
		"avg_value_per": 8,
		"type": "Mat",
		"img_path": "res://assets/inv/rare_flower.png",
		"des": "A scarce bloom prized by alchemists and collectors."
	},
	"MAT0017": {
		"base_display_name": "Purple Flower",
		"stackable": true,
		"weight_per": 0.1,
		"avg_value_per": 1,
		"type": "Mat",
		"img_path": "res://assets/inv/purple_flower.png",
		"des": "A fragrant blossom used in tonics."
	},
	"MAT0018": {
		"base_display_name": "Placeholder Item",
		"stackable": true,
		"weight_per": 1,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/placeholder_item.png",
		"des": "A test item with no current use."
	},
	"MAT0019": {
		"base_display_name": "Metal Components",
		"stackable": true,
		"weight_per": 2,
		"avg_value_per": 4,
		"type": "Mat",
		"img_path": "res://assets/inv/metal_comp.png",
		"des": "Assorted standardized fittings and fasteners."
	},
	"MAT0020": {
		"base_display_name": "Iron Ore",
		"stackable": true,
		"weight_per": 4,
		"avg_value_per": 3,
		"type": "Mat",
		"img_path": "res://assets/inv/iron_ore.png",
		"des": "Unrefined iron-bearing rock."
	},
	"MAT0021": {
		"base_display_name": "Iron Ingot",
		"stackable": true,
		"weight_per": 5,
		"avg_value_per": 10,
		"type": "Mat",
		"img_path": "res://assets/inv/iron_ingot.png",
		"des": "A forged bar of iron."
	},
	"MAT0022": {
		"base_display_name": "Hide",
		"stackable": true,
		"weight_per": 2,
		"avg_value_per": 3,
		"type": "Mat",
		"img_path": "res://assets/inv/hide.png",
		"des": "Tanned animal hide for crafting."
	},
	"MAT0023": {
		"base_display_name": "Feather",
		"stackable": true,
		"weight_per": 0.05,
		"avg_value_per": 0,
		"type": "Mat",
		"img_path": "res://assets/inv/feather.png",
		"des": "Light plume often used in fletching or quills."
	},
	"MAT0024": {
		"base_display_name": "Copper Ore",
		"stackable": true,
		"weight_per": 4,
		"avg_value_per": 3,
		"type": "Mat",
		"img_path": "res://assets/inv/copper_ore.png",
		"des": "Ore bearing traces of copper."
	},
	"MAT0025": {
		"base_display_name": "Copper Ingot",
		"stackable": true,
		"weight_per": 5,
		"avg_value_per": 8,
		"type": "Mat",
		"img_path": "res://assets/inv/copper_ingot.png",
		"des": "A forged bar of copper."
	},

	"CON0001": {
		"base_display_name": "Red Berries",
		"stackable": true,
		"can_eat": true,
		"food_qty": 2,
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
		"weight_per": 0.2,
		"avg_value_per": 1,
		"type": "Con",
		"img_path": "res://assets/inv/simple_bandage.png",
		"des": "Cloth rag cleaned and treated with healing herbs. Treats bleeding and minor wounds."
	},
	"CON0004": {
		"base_display_name": "Small Jug",
		"stackable": false,
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
	"CON0005": {
		"base_display_name": "Apple",
		"stackable": true,
		"can_eat": true,
		"food_qty": 3,
		"weight_per": 1,
		"avg_value_per": 2,
		"type": "Con",
		"img_path": "res://assets/inv/apple.png",
		"des": "A ripe red fruit."
	},
	"CON0006": {
		"base_display_name": "Large Portion of Cooked Fish",
		"stackable": true,
		"can_eat": true,
		"food_qty": 6,
		"pourable": true,
		"weight_per": 1,
		"avg_value_per": 2,
		"type": "Con",
		"img_path": "res://assets/inv/big_fish_cooked.png",
		"des": "A large cooked fish."
	},
	"CON0007": {
		"base_display_name": "Large Fresh Fish",
		"stackable": true,
		"can_eat": true,
		"raw_food": true,
		"food_qty": 3,
		"pourable": true,
		"weight_per": 1,
		"avg_value_per": 2,
		"type": "Con",
		"img_path": "res://assets/inv/big_fish_raw.png",
		"des": "A large cooked fish."
	},
	"CON0008": {
		"base_display_name": "Small Fresh Fish",
		"stackable": true,
		"can_eat": true,
		"raw_food": true,
		"food_qty": 2,
		"weight_per": 0.5,
		"avg_value_per": 1,
		"type": "Con",
		"img_path": "res://assets/inv/small_fish_raw.png",
		"des": "A small raw fish."
	},
	"CON0009": {
		"base_display_name": "Small Portion of Cooked Fish",
		"stackable": true,
		"can_eat": true,
		"food_qty": 4,
		"weight_per": 0.5,
		"avg_value_per": 2,
		"type": "Con",
		"img_path": "res://assets/inv/small_fish_cooked.png",
		"des": "A small cooked fish."
	},
	"CON0010": {
		"base_display_name": "Raw Meat",
		"stackable": true,
		"can_eat": true,
		"raw_food": true,
		"food_qty": 2,
		"weight_per": 1,
		"avg_value_per": 1,
		"type": "Con",
		"img_path": "res://assets/inv/raw_meat.png",
		"des": "Fresh uncooked meat."
	},
	"CON0011": {
		"base_display_name": "Cooked Meat",
		"stackable": true,
		"can_eat": true,
		"food_qty": 5,
		"weight_per": 1,
		"avg_value_per": 3,
		"type": "Con",
		"img_path": "res://assets/inv/cooked_meat.png",
		"des": "A hearty cooked meal."
	},
	"CON0012": {
		"base_display_name": "Egg",
		"stackable": true,
		"can_eat": true,
		"food_qty": 1,
		"weight_per": 0.2,
		"avg_value_per": 1,
		"type": "Con",
		"img_path": "res://assets/inv/egg.png",
		"des": "A simple egg."
	},
	"CON0013": {
		"base_display_name": "Cooked Egg",
		"stackable": true,
		"can_eat": true,
		"food_qty": 2,
		"weight_per": 0.2,
		"avg_value_per": 1,
		"type": "Con",
		"img_path": "res://assets/inv/cooked_egg.png",
		"des": "A cooked egg."
	},
	"CON0014": {
		"base_display_name": "Cooked Corn",
		"stackable": true,
		"can_eat": true,
		"food_qty": 3,
		"weight_per": 1,
		"avg_value_per": 2,
		"type": "Con",
		"img_path": "res://assets/inv/cooked_corn.png",
		"des": "A hot roasted cob."
	},
	"CON0015": {
		"base_display_name": "Large Bottle",
		"stackable": false,
		"fillable": true,
		"drinkable": true,
		"pourable": true,
		"max_fill": 10,
		"weight_per": 3,
		"avg_value_per": 8,
		"type": "Con",
		"img_path": "res://assets/inv/large_bottle.png",
		"des": "A sizable container for liquids."
	},
	"CON0016": {
		"base_display_name": "Draft Bottle",
		"stackable": false,
		"fillable": true,
		"drinkable": true,
		"pourable": true,
		"max_fill": 3,
		"weight_per": 1,
		"avg_value_per": 3,
		"type": "Con",
		"img_path": "res://assets/inv/draft_bottle.png",
		"des": "A small bottle suited for tonics."
	},
	"ARM0001": {
		"base_display_name": "Pigface Knight Helm",
		"stackable": false,
		"weight_per": 5,
		"avg_value_per": 35,
		"type": "Arm",
		"img_path": "res://assets/inv/iron_knight_helm.png",
		"def_bonus": 5,
		"dex_bonus": -2,
		"max_durability": 100,
		"dismantle_yield": ["Metal Scraps"],
		"des": "A knightly helm crafted with great skill. Provides ample protection with a price to nimbleness."
	},
	"ARM0002": {
		"base_display_name": "Cloth Boots",
		"stackable": false,
		"weight_per": 1,
		"avg_value_per": 6,
		"type": "Arm",
		"img_path": "res://assets/inv/cloth_boots.png",
		"des": "Simple soft boots offering minimal protection."
	},
	"ARM0003": {
		"base_display_name": "Top Hat",
		"stackable": false,
		"weight_per": 1,
		"avg_value_per": 10,
		"type": "Arm",
		"img_path": "res://assets/inv/tophat.png",
		"des": "A stylish hat that adds height and presence."
	},
	"ARM0004": {
		"base_display_name": "Cloth Backpack",
		"stackable": false,
		"weight_per": 2,
		"avg_value_per": 15,
		"type": "Arm",
		"img_path": "res://assets/inv/cloth_backpack.png",
		"des": "A simple pack for carrying goods."
	},
	"WEAP0001": {
		"base_display_name": "Iron Knife",
		"stackable": false,
		"weight_per": 2,
		"avg_value_per": 15,
		"type": "Weap",
		"img_path": "res://assets/inv/iron_knife.png",
		"des": "A small knife with an iron blade."
	},
	"WEAP0002": {
		"base_display_name": "Bone Club",
		"stackable": false,
		"weight_per": 3,
		"avg_value_per": 6,
		"type": "Weap",
		"img_path": "res://assets/inv/bone_club.png",
		"des": "A heavy club fashioned from bone."
	},
	"WEAP0003": {
		"base_display_name": "Bone Knife",
		"stackable": false,
		"weight_per": 2,
		"avg_value_per": 8,
		"type": "Weap",
		"img_path": "res://assets/inv/bone_knife.png",
		"des": "A crude blade carved from bone."
	},
	"WEAP0004": {
		"base_display_name": "Stone Spear",
		"stackable": false,
		"weight_per": 4,
		"avg_value_per": 8,
		"type": "Weap",
		"img_path": "res://assets/inv/stone_spear.png",
		"des": "A spear tipped with knapped stone."
	},
	"WEAP0005": {
		"base_display_name": "Stone Sickle",
		"stackable": false,
		"weight_per": 3,
		"avg_value_per": 6,
		"type": "Weap",
		"img_path": "res://assets/inv/stone_sickle.png",
		"des": "A primitive sickle used for harvesting."
	},
	"WEAP0006": {
		"base_display_name": "Stone Shovel",
		"stackable": false,
		"weight_per": 5,
		"avg_value_per": 6,
		"type": "Weap",
		"img_path": "res://assets/inv/stone_shovel.png",
		"des": "A sturdy shovel made from stone."
	},
	"WEAP0007": {
		"base_display_name": "Stone Pickaxe",
		"stackable": false,
		"weight_per": 5,
		"avg_value_per": 7,
		"type": "Weap",
		"img_path": "res://assets/inv/stone_pickaxe.png",
		"des": "A basic pick for mining."
	},
	"WEAP0008": {
		"base_display_name": "Stone Knife",
		"stackable": false,
		"weight_per": 2,
		"avg_value_per": 5,
		"type": "Weap",
		"img_path": "res://assets/inv/stone_knife.png",
		"des": "A chipped stone blade."
	},
	"WEAP0009": {
		"base_display_name": "Stone Hoe",
		"stackable": false,
		"weight_per": 4,
		"avg_value_per": 6,
		"type": "Weap",
		"img_path": "res://assets/inv/stone_hoe.png",
		"des": "A primitive hoe for tilling soil."
	},
	"WEAP0010": {
		"base_display_name": "Stone Hammer",
		"stackable": false,
		"weight_per": 4,
		"avg_value_per": 6,
		"type": "Weap",
		"img_path": "res://assets/inv/stone_hammer.png",
		"des": "A hefty hammer with a stone head."
	},
	"WEAP0011": {
		"base_display_name": "Stone Axe",
		"stackable": false,
		"weight_per": 5,
		"avg_value_per": 8,
		"type": "Weap",
		"img_path": "res://assets/inv/stone_axe.png",
		"des": "An axe head of knapped stone."
	},
	"WEAP0012": {
		"base_display_name": "Nobleman Pistol",
		"stackable": false,
		"weight_per": 3,
		"avg_value_per": 120,
		"type": "Weap",
		"img_path": "res://assets/inv/nobleman_pistol.png",
		"des": "A finely crafted sidearm favored by the wealthy."
	},
	"WEAP0013": {
		"base_display_name": "Evil Knife",
		"stackable": false,
		"weight_per": 2,
		"avg_value_per": 25,
		"type": "Weap",
		"img_path": "res://assets/inv/evilknife.png",
		"des": "A strange blade that seems to glow with malevolent intent."
	},
	"UTIL0001": {
		"base_display_name": "Bedroll",
		"stackable": false,
		"weight_per": 5,
		"avg_value_per": 15,
		"type": "Loot",
		"img_path": "res://assets/inv/bedroll.png",
		"des": "A rolled up sleeping bag for rough sleeping."
	},
	"UTIL0002": {
		"base_display_name": "Candle",
		"stackable": true,
		"weight_per": 0.2,
		"avg_value_per": 2,
		"type": "Loot", # If you prefer UTIL, change to "Util" (no special flags in schema)
		"img_path": "res://assets/inv/candle.png",
		"des": "A small wax light source."
	},
	"UTIL0003": {
		"base_display_name": "Lockpicks",
		"stackable": true,
		"weight_per": 0.2,
		"avg_value_per": 8,
		"type": "Loot",
		"img_path": "res://assets/inv/lockpicks.png",
		"des": "A bundle of picks and tension tools."
	},
	"UTIL0004": {
		"base_display_name": "Lock",
		"stackable": true,
		"weight_per": 1,
		"avg_value_per": 6,
		"type": "Loot",
		"img_path": "res://assets/inv/lock.png",
		"des": "A sturdy mechanism to keep things closed."
	},
	"UTIL0005": {
		"base_display_name": "Key",
		"stackable": false,
		"weight_per": 0.1,
		"avg_value_per": 3,
		"type": "Loot",
		"img_path": "res://assets/inv/key.png",
		"des": "Opens something, somewhere."
	},
	"LOOT0001": {
		"base_display_name": "Blueprint",
		"stackable": false,
		"readable": true,
		"weight_per": 0.1,
		"avg_value_per": 105,
		"type": "Loot",
		"img_path": "res://assets/inv/blueprint.png",
		"des": "A photographic reproduction of a technical drawing for an enginnering design."
	},
	"LOOT0002": {
		"base_display_name": "Coins",
		"stackable": true,
		"weight_per": 0.1,
		"avg_value_per": 1,
		"type": "Loot",
		"img_path": "res://assets/inv/gold_coins.png",
		"des": "A pile of currency."
	},
	"LOOT0003": {
		"base_display_name": "Cut Ruby",
		"stackable": true,
		"weight_per": 0.1,
		"avg_value_per": 405,
		"type": "Loot",
		"img_path": "res://assets/inv/cut_ruby.png",
		"des": "A precious red gemstone."
	},
	"LOOT00004": {
		"base_display_name": "Weird Book",
		"stackable": false,
		"readable": true,
		"weight_per": 1,
		"avg_value_per": 25,
		"type": "Loot",
		"img_path": "res://assets/inv/weirdbook.png",
		"des": "The margins crawl with strange diagrams."
	},
	"LOOT00005": {
		"base_display_name": "Skill Book: Training",
		"stackable": false,
		"readable": true,
		"weight_per": 1,
		"avg_value_per": 40,
		"type": "Loot",
		"img_path": "res://assets/inv/skill_book_training.png",
		"des": "A worn manual filled with practical exercises."
	},
	"LOOT00006": {
		"base_display_name": "Holy Book",
		"stackable": false,
		"readable": true,
		"weight_per": 1,
		"avg_value_per": 35,
		"type": "Loot",
		"img_path": "res://assets/inv/holybook.png",
		"des": "Scripture revered by the faithful."
	},
	"LOOT00007": {
		"base_display_name": "Grimoire",
		"stackable": false,
		"readable": true,
		"weight_per": 1,
		"avg_value_per": 60,
		"type": "Loot",
		"img_path": "res://assets/inv/grimoire.png",
		"des": "An ominous tome of spells and rituals."
	},
	"LOOT00008": {
		"base_display_name": "Gold Ring",
		"stackable": false,
		"weight_per": 0.1,
		"avg_value_per": 150,
		"type": "Loot",
		"img_path": "res://assets/inv/gold_ring.png",
		"des": "A simple band of precious metal."
	},
	"LOOT00009": {
		"base_display_name": "Evil Book",
		"stackable": false,
		"readable": true,
		"weight_per": 1,
		"avg_value_per": 45,
		"type": "Loot",
		"img_path": "res://assets/inv/evilbook.png",
		"des": "A malevolent tome bound in questionable leather."
	}
}
