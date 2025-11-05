#res://scenes/play/WorldtoLocalRefresh.tscn parent node - res://ui/scripts/WorldtoLocalRefresh.gd
extends Control

@onready var travel_label = $TravelLabel  # ✅ Make sure this matches the actual node

func _ready():
	if travel_label == null:
		print("❌ ERROR: TravelLabel is missing!")
		return

	travel_label.text = "...disembarking"
	travel_label.modulate.a = 0.0

	var entry_context = LoadHandlerSingleton.load_entry_context()
	var entry_type = entry_context.get("entry_type", "explore")

	match entry_type:
		"explore":
			print("🧭 Chunked exploration detected. Generating JSONs before loading localmap...")
			await GeneratorDispatcher.generate_chunked_local_map_to_jsons()

		"tradepost":
			print("🏪 Static Tradepost entry detected. Preparing static biome data...")
			await GeneratorDispatcher.load_static_hub("tradepost")

		_:
			print("🎯 Standard local map detected. Generating single-map JSONs...")
			await GeneratorDispatcher.generate_local_map_to_jsons()

	LoadHandlerSingleton.set_realm_char_state("localmap")
	await fade_in()


func fade_in():
	var tween = create_tween()
	tween.tween_property(travel_label, "modulate:a", 1.0, 0.5)  # Fade in text
	await tween.finished
	await get_tree().create_timer(1.5).timeout  # Hold for 1.5s before fade out
	fade_out()

func fade_out():
	var tween = create_tween()
	tween.tween_property(travel_label, "modulate:a", 0.0, 0.5)  # Fade out text
	await tween.finished

	# ✅ Switch back to world map
	get_tree().change_scene_to_file("res://scenes/play/LocalMap.tscn")  # Adjust if needed

