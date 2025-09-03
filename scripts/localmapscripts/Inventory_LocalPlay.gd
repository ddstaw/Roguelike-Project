extends Control

const WORLD_SCENE := "res://scenes/play/WorldMapTravel.tscn"
const LOCAL_SCENE := "res://scenes/play/LocalMap.tscn"

var _closing := false  # simple debounce so we don't double-trigger

func _ready() -> void:
	print("📦 Inventory scene loaded.")

func _unhandled_input(event: InputEvent) -> void:
	if _closing:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("toggle_inventory"):
		accept_event()
		_closing = true
		_return_to_current_realm_scene()

func _return_to_current_realm_scene() -> void:
	var data: Dictionary = LoadHandlerSingleton.load_char_state()
	var cs: Dictionary = (data.get("character_state", {}) as Dictionary)

	# Explicit types + cast values to String before comparison
	var in_city: bool = (cs.get("incity", "N") as String) == "Y"
	var in_local: bool = (cs.get("inlocalmap", "N") as String) == "Y"
	var in_world: bool = (cs.get("inworldmap", "N") as String) == "Y"

	var target: String = LOCAL_SCENE
	if in_local:
		target = LOCAL_SCENE
	else:
		# Both incity:Y and inworldmap:Y route to the world travel scene
		target = WORLD_SCENE

	print("⬅️ Returning to: ", target)
	get_tree().paused = false
	get_tree().change_scene_to_file(target)
