# terrain_data.gd
extends Node

const TERRAIN_PROPERTIES := {
	"tree": {
		"blocks_vision": false,
		"tree_chop": true,
		"burnable": true,
		"buildable": true,
		"blocks_movement": true,
		"chop_to": "dirt"
	},
	"tree2": {
		"blocks_vision": false,
		"tree_chop": true,
		"burnable": true,
		"buildable": true,
		"blocks_movement": true,
		"chop_to": "dirt"
	},
	"tree3": {
		"blocks_vision": false,
		"tree_chop": true,
		"burnable": true,
		"buildable": true,
		"blocks_movement": true,
		"chop_to": "dirt"
	},
	"grass": {
		"blocks_vision": false,
		"grass_cut": true,
		"grass_search": true,
		"diggable": true,
		"burnable": true,
		"blocks_movement": false,
		"dig_to": "dirt"
	},
	"dirt": {
		"blocks_vision": false,
		"diggable": true,
		"hoeable": true,
		"blocks_movement": false,
		"dig_to": "hole"
	},
	"water": {
		"blocks_vision": false,
		"fishable": true,
		"drinkable": true,
		"pottable": true,
		"pottable_liquid": "dirty_water",
		"wet": true,
		"blocks_movement": false
	},
	"path": {
		"blocks_vision": false,
		"blocks_movement": false
	},
	"bush": {
		"blocks_vision": false,
		"bush_cut": true,
		"bush_search": true,
		"burnable": true,
		"blocks_movement": false,
		"destroy_to": "dirt"
	},
	"flowers": {
		"blocks_vision": false,
		"flowers_cut": true,
		"flowers_search": true,
		"burnable": true,
		"blocks_movement": false,
		"destroy_to": "dirt"
	},
	"bridge": {
		"blocks_vision": false,
		"wood_destroy": true,
		"burnable": true,
		"blocks_movement": false,
		"destroy_to": "water"
	},
	"hole": {
		"blocks_vision": false,
		"hole_enter": true,
		"hole_spawn": true,
		"blocks_movement": false
	},
	"stonefloor": {
		"blocks_vision": false,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_floor": true,
		"buildable": true,
		"blocks_movement": false
	},
	"stairs": {
		"blocks_vision": false,
		"stairs_enter_down": true,
		"buildable": true,
		"blocks_movement": false
	},
	"stonewallside": {
		"blocks_vision": true,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"buildable": true,
		"blocks_movement": true
	},
	"stonewallbottom": {
		"blocks_vision": true,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"buildable": true,
		"blocks_movement": true
	},
	"stonewallbottomwindow": {
		"blocks_vision": false,
		"window": true,
		"openable_window": true,
		"has_curtains": true,
		"starts_closed": true,
		"breakable": true,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"buildable": true,
		"blocks_movement": true
	},
	"stonewallsidewindow": {
		"blocks_vision": false,
		"window": true,
		"openable_window": true,
		"has_curtains": true,
		"starts_closed": true,
		"breakable": true,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"buildable": true,
		"blocks_movement": true
	},
	"ladder": {
		"blocks_vision": false,
		"stairs_enter_up": true,
		"buildable": true,
		"blocks_movement": false
	},
	"stonedoor": {
		"blocks_vision": true,
		"door": true,
		"openable_door": true,
		"starts_closed": true,
		"stone_destroy": true,
		"buildable": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"blocks_movement": true
	},
	"slum_road_floor": {
		"blocks_vision": false,
		"blocks_movement": false
	},
	"slum_sidewalk_floor": {
		"blocks_vision": false,
		"blocks_movement": false
	},
	"slum_brick_floor": {
		"blocks_vision": false,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_floor": true,
		"buildable": true,
		"blocks_movement": false
	},
	"slum_stone_floor": {
		"blocks_vision": false,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_floor": true,
		"buildable": true,
		"blocks_movement": false
	},
	"slum_brick_wallside": {
		"blocks_vision": true,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"buildable": true,
		"blocks_movement": true
	},
	"slum_brick_wallbottom": {
		"blocks_vision": true,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"buildable": true,
		"blocks_movement": true
	},
	"slum_brick_wallbottom_window": {
		"blocks_vision": false,
		"window": true,
		"openable_window": true,
		"has_curtains": true,
		"starts_closed": true,
		"breakable": true,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"buildable": true,
		"blocks_movement": true
	},
	"slum_brick_wallside_window": {
		"blocks_vision": false,
		"window": true,
		"openable_window": true,
		"has_curtains": true,
		"starts_closed": true,
		"breakable": true,
		"stone_destroy": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"buildable": true,
		"blocks_movement": true
	},
	"slum_brick_door": {
		"blocks_vision": true,
		"door": true,
		"openable_door": true,
		"starts_closed": true,
		"stone_destroy": true,
		"buildable": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"blocks_movement": true
	},
	"slum_brick_floor_stairs_down": {
		"blocks_vision": false,
		"stairs_enter_down": true,
		"buildable": true,
		"blocks_movement": false
	},
	"slum_brick_floor_stairs_up": {
		"blocks_vision": false,
		"stairs_enter_up": true,
		"buildable": true,
		"blocks_movement": false
	},	
	"slum_wood_fence": {
		"blocks_vision": true,
		"wood_destroy": true,
		"destroy_to": "dirt",
		"indoor_wall": true,
		"buildable": true,
		"blocks_movement": true
	}
	
}
