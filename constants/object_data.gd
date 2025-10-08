# object_data.gd
extends Node

const OBJECT_PROPERTIES := {
	"bed": {
		"name": "Simple Bed",
		"desc": "Rustic bed made from primitive materials.",
		"tags": ["badsleep"],
		"blocks_vision": false,
		"long_sleeping": true,
		"burnable": true,
		"wood_destroy": true,
		"blocks_movement": true
	},
	"candelabra": {
		"name": "Candelabra",
		"desc": "Rustic candelabra made from primitive metal.",
		"tags": ["lightprovide"],
		"blocks_vision": false,
		"lightable": true,
		"light_radius": 4,
		"light_color": Color(1.0, 0.8, 0.6),
		"metal_destroy": true,
		"blocks_movement": true
	},
	"campfire": {
		"name": "Campfire",
		"desc": "Simple firepit for cooking or warmth.",
		"tags": ["warmth", "basiccooking", "lightprovide"],
		"blocks_vision": false,
		"lightable": true,
		"light_radius": 4,
		"light_color": Color(1.0, 0.8, 0.6),
		"wood_destroy": true,
		"cooking_craft": true,
		"bench_type": "campfire",
		"blocks_movement": true
	},
	"workbench": {
		"name": "Simple Workbench",
		"desc": "Basic crafting bench for assembling gear.",
		"tags": ["craftingstation", "basiccraft"],
		"blocks_vision": false,
		"bench_craft": true,
		"bench_type": "workbench",
		"burnable": true,
		"wood_destroy": true,
		"blocks_movement": true
	},
	"slum_streetlamp": {
		"name": "Old Streetlight",
		"desc": "Barely functional electric outdoor light.",
		"tags": ["lightprovide"],
		"blocks_vision": false,
		"lightable": true,
		"light_radius": 6,
		"light_color": Color(1.0, 0.8, 0.6),
		"metal_destroy": true,
		"blocks_movement": true
	},
	"woodchest": {
		"name": "Wood Chest",
		"desc": "Rustic wooden chest for storage.",
		"tags": ["chest", "lockable"],
		"blocks_vision": false,
		"burnable": true,
		"lootable": true,
		"storage": true,
		"storage_type": "woodchest",
		"wood_destroy": true,
		"blocks_movement": true
	},
	"slum_trash": {
		"name": "Garbage Can",
		"desc": "Metal garbage can, maybe someone threw something valuable away?",
		"tags": ["stinks"],
		"blocks_vision": false,
		"burnable": true,
		"lootable": true,
		"storage": true,
		"storage_type": "slum_trash",
		"metal_destroy": true,
		"blocks_movement": true
	},
	"sewer_door": {
		"name": "Sewer Manhole",
		"desc": "A manhole leading to the sewers below the street.",
		"tags": ["stinks"],
		"blocks_vision": false,
		"sewers_enter_down": true,
		"blocks_movement": false
	},
	"mount": {
		"name": "My Transport",
		"desc": "My trusty companion, carrying my burdens and myself.",
		"tags": ["mount"],
		"blocks_vision": false,
		"mount_to_exit": true,
		"storage": true,
		"storage_type": "mount",
		"blocks_movement": true
	}
}
