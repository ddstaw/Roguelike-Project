extends Node

class_name ItemFactory

const ITEM_DATA := preload("res://constants/item_data.gd").ITEM_PROPERTIES

# --- Attachment image definitions
const ATTACHMENT_IMAGE_PATHS := {
	"scope": "res://assets/inv/weap/nobleman_pistol_mod_scope.png",
	"silencer": "res://assets/inv/weap/nobleman_pistol_mod_sil.png",
	"extension_mag": "res://assets/inv/weap/nobleman_pistol_mod_extmag.png"
}

# --- Tech image (goes above base, below mods)
const TECH_IMAGE_PATH := "res://assets/inv/weap/nobleman_pistol_tech.png"

func generate_weapon_instance(arch_id: String, options := {}) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var arch: Dictionary = ITEM_DATA.get(arch_id)
	if arch.is_empty():
		push_warning("Invalid archetype ID: %s" % arch_id)
		return {}

	var tier: int = options.get("tier", 1)

	# === Tier settings
	var attach_pool = arch.get("attachment_slots", [])
	var attach_max = 1
	var attach_chance = 0.2
	var allow_divine = false
	var allow_tech = false

	match tier:
		1:
			attach_max = 1
			attach_chance = 0.2
		2:
			attach_max = 2
			attach_chance = 0.5
			allow_divine = randf() < 0.2
			allow_tech = randf() < 0.2
		3:
			attach_max = 3
			attach_chance = 0.9
			allow_divine = randf() < 0.5
			allow_tech = randf() < 0.5

	var item := {
		"item_ID": arch_id,
		"type": arch.get("type", ""),
		"subtype": arch.get("subtype", ""),
		"qty": 1,
		"stackable": arch.get("stackable", false),
		"base_display_name": arch.get("base_display_name", "Unnamed"),
		"des": arch.get("des", ""),
		"value": arch.get("avg_value_per", 0),
		"weight": arch.get("weight_per", 0),
		"tags": arch.get("tags", []),
		"crafting_tags": arch.get("crafting_tags", []),
		"magic_tags": arch.get("magic_tags", []),
		"rg_dmg_floor": arch.get("rg_dmg_floor", Vector2i.ZERO),
		"unique_ID": LoadHandlerSingleton._make_unique_id(rng),
		"materials": options.get("materials", []),
		"attachments": [],
		"enhancement": null,
		"img_layers": []
	}

	# === Material-derived stats
	var resolved_mats: Array = item["materials"]
	var material_map := {
		"wood": "common wood",
		"ingot": "copper",
		"parts": "copper"
	}

	for m in resolved_mats:
		var m_l = m.to_lower()
		if m_l.find("wood") != -1:
			material_map["wood"] = m_l
		elif m_l.find("parts") != -1:
			material_map["parts"] = m_l.split()[0]
		elif m_l in ["copper", "iron", "steel"]:
			material_map["ingot"] = m_l

	var rng_acc := 30
	match material_map["wood"]:
		"common wood": rng_acc = 30
		"hardwood": rng_acc = 50
		"fine wood": rng_acc = 70

	var max_dura := 50
	match material_map["ingot"]:
		"copper": max_dura = 50
		"iron": max_dura = 75
		"steel": max_dura = 125

	var rng_dmg := Vector2i(30, 80)
	match material_map["parts"]:
		"copper": rng_dmg = Vector2i(30, 80)
		"iron": rng_dmg = Vector2i(40, 100)
		"steel": rng_dmg = Vector2i(50, 170)

	item["rng_acc"] = rng_acc
	item["max_dura"] = max_dura
	item["rng_dmg"] = rng_dmg

	# === Enhancement logic
	var allowed_enh: Array = arch.get("allowed_enhancements", [])
	var enh_choices := []

	if allow_divine and "divine" in allowed_enh:
		enh_choices.append("divine")
	if allow_tech and "technological" in allowed_enh:
		enh_choices.append("technological")

	if options.has("enhancement") and options["enhancement"] in enh_choices:
		item["enhancement"] = options["enhancement"]
	elif enh_choices.size() > 0:
		item["enhancement"] = enh_choices[rng.randi_range(0, enh_choices.size() - 1)]

	# === Attachments
	var attach_count = 0
	for slot in attach_pool:
		if attach_count >= attach_max:
			break
		if options.has("attachments") and slot in options["attachments"]:
			item["attachments"].append(slot)
			attach_count += 1
		elif randf() < attach_chance:
			item["attachments"].append(slot)
			attach_count += 1

	# === Display name
	var name_bits := []
	if "silencer" in item["attachments"]:
		name_bits.append("Silenced")
	if "scope" in item["attachments"]:
		name_bits.append("Hunting")
	if item["enhancement"] == "divine":
		name_bits.append("Blessed")
	elif item["enhancement"] == "technological":
		name_bits.append("Augmented")
	name_bits.append(item["base_display_name"])
	item["display_name"] = " ".join(name_bits)

	# === Image layering
	item["img_layers"].append(arch.get("img_base"))

	if item["enhancement"] == "divine":
		var variant_key = ["evil", "holy", "weird"].pick_random()
		item["enhancement_variant"] = variant_key
		var img_variants = arch.get("img_variants", {})
		if img_variants.has(variant_key):
			item["img_layers"][0] = img_variants[variant_key]
	elif item["enhancement"] == "technological":
		item["img_layers"].append(TECH_IMAGE_PATH)

	for mod in item["attachments"]:
		if ATTACHMENT_IMAGE_PATHS.has(mod):
			item["img_layers"].append(ATTACHMENT_IMAGE_PATHS[mod])
	
	# Random current durability (usually between 10% and 30% of max)
	var dura_percent := rng.randf_range(0.1, 0.3)
	var current_dura := int(round(max_dura * dura_percent))

	
	return item
