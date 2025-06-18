# object_data.gd
extends Node

const OBJECT_PROPERTIES := {
	"bed": {
		"blocks_vision": false,
		"long_sleeping": true,
		"burnable": true,
		"wood_destroy": true,
		"blocks_movement": true
	},
	"candelabra": {
		"blocks_vision": false,
		"lightable": true,
		"light_radius": 4,
		"light_color": Color(1.0, 0.8, 0.6),
		"metal_destroy": true,
		"blocks_movement": true
	},
	"slum_streetlamp": {
		"blocks_vision": false,
		"lightable": true,
		"light_radius": 6,
		"light_color": Color(1.0, 0.8, 0.6),
		"metal_destroy": true,
		"blocks_movement": true
	},
	"woodchest": {
		"blocks_vision": false,
		"burnable": true,
		"lootable": true,
		"storage": true,
		"storage_type": "woodchest",
		"wood_destroy": true,
		"blocks_movement": true
	},
	"slum_trash": {
		"blocks_vision": false,
		"burnable": true,
		"lootable": true,
		"storage": true,
		"storage_type": "slum_trash",
		"metal_destroy": true,
		"blocks_movement": true
	},
	"sewer_door": {
		"blocks_vision": false,
		"sewers_enter_down": true,
		"blocks_movement": false
	},
	"mount": {
		"blocks_vision": false,
		"mount_to_exit": true,
		"storage": true,
		"storage_type": "mount",
		"blocks_movement": true
	}
}
