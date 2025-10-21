#res://constants/crafting_blueprints.gd
# Acts as data bridge between constants and blueprint_register.json

extends Resource
class_name CraftingBlueprints

static var BLUEPRINTS := {
	# --- Basic Material Refinement ---
	"MAT0009": { # Twine
		"requires_station": "cutting",
		"materials": {"MAT0006": 3},   # 3x Plant Fiber → 1x Twine
		"produces": {"MAT0009": 1}
	},

	# --- Primitive Tools & Weapons ---
	"WEAP0002": { # Bone Club
		"requires_station": "workbench",
		"materials": {"MAT0001": 10, "MAT0009": 10, "MAT0002": 10}, # Wood + Twine + Bones
		"produces": {"WEAP0002": 1}
	},

	"WEAP0003": { # Bone Knife
		"requires_station": null,
		"materials": {"MAT0002": 6, "MAT0009": 4}, # Bone + Twine
		"produces": {"WEAP0003": 1}
	},

	"WEAP0004": { # Stone Spear
		"requires_station": "workbench",
		"materials": {"MAT0001": 12, "MAT0007": 6, "MAT0009": 6}, # Wood + Rock + Twine
		"produces": {"WEAP0004": 1}
	},

	"WEAP0005": { # Stone Sickle
		"requires_station": "workbench",
		"materials": {"MAT0007": 8, "MAT0001": 4, "MAT0009": 4}, # Rock + Wood + Twine
		"produces": {"WEAP0005": 1}
	},

	"WEAP0006": { # Stone Shovel
		"requires_station": "workbench",
		"materials": {"MAT0007": 10, "MAT0001": 6, "MAT0009": 6}, # Rock + Wood + Twine
		"produces": {"WEAP0006": 1}
	},

	"WEAP0007": { # Stone Pickaxe
		"requires_station": "workbench",
		"materials": {"MAT0007": 12, "MAT0001": 8, "MAT0009": 6}, # Rock + Wood + Twine
		"produces": {"WEAP0007": 1}
	},

	"WEAP0008": { # Stone Knife
		"requires_station": null,
		"materials": {"MAT0007": 4, "MAT0009": 2}, # Rock + Twine
		"produces": {"WEAP0008": 1}
	},

	"WEAP0009": { # Stone Hoe
		"requires_station": "workbench",
		"materials": {"MAT0007": 10, "MAT0001": 8, "MAT0009": 5}, # Rock + Wood + Twine
		"produces": {"WEAP0009": 1}
	},

	"WEAP0010": { # Stone Hammer
		"requires_station": "workbench",
		"materials": {"MAT0007": 8, "MAT0001": 8, "MAT0009": 4}, # Rock + Wood + Twine
		"produces": {"WEAP0010": 1}
	},

	"WEAP0011": { # Stone Axe
		"requires_station": "workbench",
		"materials": {"MAT0007": 10, "MAT0001": 10, "MAT0009": 5}, # Rock + Wood + Twine
		"produces": {"WEAP0011": 1}
	},

	# --- Utility ---
	"UTIL0007": { # Torch
		"requires_station": "workbench",
		"materials": {"MAT0001": 4, "MAT0009": 2}, # Wood + Twine
		"produces": {"UTIL0007": 1}
	}
}

# --- Register Interaction ---
static func sync_with_register() -> Dictionary:
	var reg := LoadHandlerSingleton.load_blueprint_register()
	if not reg.has("blueprints"):
		reg["blueprints"] = {}
	for bp_id in BLUEPRINTS.keys():
		if not reg["blueprints"].has(bp_id):
			reg["blueprints"][bp_id] = {}
	LoadHandlerSingleton.save_blueprint_register(reg)
	return reg

# --- Accessors ---
static func get_all_blueprints() -> Dictionary:
	return BLUEPRINTS

static func get_blueprint(bp_id: String) -> Dictionary:
	return BLUEPRINTS.get(bp_id, {})

static func get_player_known_blueprints() -> Array:
	var reg := LoadHandlerSingleton.load_blueprint_register()
	if not reg.has("blueprints"):
		return []
	return reg["blueprints"].keys()

static func unlock_blueprint(bp_id: String) -> void:
	var reg := LoadHandlerSingleton.load_blueprint_register()
	if not reg.has("blueprints"):
		reg["blueprints"] = {}
	reg["blueprints"][bp_id] = {}
	LoadHandlerSingleton.save_blueprint_register(reg)

static func clear_player_blueprints() -> void:
	LoadHandlerSingleton.clear_blueprint_register()
