extends Node

const BUILD_PROPERTIES := {
	"bed": {
		"type": "object",
		"object_name": "bed",
		"cat": "furni",
		"requires": {
			"wood": 20,
			"cloth": 10
		}
	},
	"campfire": {
		"type": "object",
		"object_name": "campfire",
		"cat": "craft",
		"requires": {
			"wood": 5,
			"stone": 5
		}
	},
	"workbench": {
		"type": "object",
		"object_name": "workbench",
		"cat": "craft",
		"requires": {
			"wood": 30,
			"metaljunk": 30,
			"stone": 10
		}
	},
	"stonefloor": {
		"type": "tile",
		"terrain_name": "stonefloor",
		"cat": "structures",
		"requires": {
			"wood": 10,
			"stone": 20
		}
	},
	"stonewallbottom": {
		"type": "tile",
		"terrain_name": "stonewallbottom",
		"cat": "structures",
		"requires": {
			"wood": 10,
			"stone": 20
		}
	},
	"stonewallside": {
		"type": "tile",
		"terrain_name": "stonewallside",
		"cat": "structures",
		"requires": {
			"wood": 10,
			"stone": 20
		}
	},
	"stonewallbottomwindow": {
		"type": "tile",
		"terrain_name": "stonewallbottomwindow",
		"cat": "structures",
		"requires": {
			"wood": 10,
			"stone": 20
		}
	},
	"stonewallsidewindow": {
		"type": "tile",
		"terrain_name": "stonewallsidewindow",
		"cat": "structures",
		"requires": {
			"wood": 10,
			"stone": 20
		}
	},
	"stonedoor": {
		"type": "tile",
		"terrain_name": "stonedoor",
		"cat": "structures",
		"requires": {
			"wood": 10,
			"metaljunk": 10,
			"stone": 20
		}
	},
	"woodchest": {
		"type": "object",
		"object_name": "woodchest",
		"cat": "storage",
		"requires": {
			"wood": 20,
			"metaljunk": 20
		}
	}
}
