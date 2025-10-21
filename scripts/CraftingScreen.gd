extends Control

const BlueprintSlot = preload("res://ui/scenes/blueprint_slot.tscn")
const CraftingBlueprints = preload("res://constants/crafting_blueprints.gd")

@onready var blueprint_list: VBoxContainer = $LeftPanel/Panel_LeftBackground/LeftContent/ListPanel/ScrollContainer/BluePrintList

var _did_populate: bool = false

func _ready() -> void:
	populate_blueprints()

func populate_blueprints() -> void:
	if _did_populate:
		return
	_did_populate = true

	if blueprint_list == null:
		push_error("❌ BlueprintList node not found. Check node path.")
		return

	# Clear old entries
	for c in blueprint_list.get_children():
		c.queue_free()

	var bp_data: Dictionary = LoadHandlerSingleton.load_blueprint_register()
	if bp_data.is_empty():
		push_warning("⚠️ No blueprint register data found.")
		return

	var blueprints: Dictionary = bp_data.get("blueprints", {})
	var count := 0

	for bp_id in blueprints.keys():
		if CraftingBlueprints.BLUEPRINTS.has(bp_id):
			var slot: Button = BlueprintSlot.instantiate()
			slot.init(bp_id)
			blueprint_list.add_child(slot)
			count += 1

	print("✅ Added", count, "blueprint slots")
