extends Control

@onready var travel_label = $TravelLabel  # ✅ Make sure this matches the actual node

func _ready():
	# Ensure the label exists
	if travel_label == null:
		print("❌ ERROR: TravelLabel is missing!")
		return

	# ✅ Set the text and make it invisible at start
	travel_label.text = "...you move on"  # Static message
	travel_label.modulate.a = 0.0  # Start hidden

	LoadHandlerSingleton.set_realm_char_state("worldmap")
	# ✅ Start transition
	fade_in()

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

	LoadHandlerSingleton.reset_chunk_state()

	# ✅ Switch back to world map
	get_tree().change_scene_to_file("res://scenes/play/WorldMapTravel.tscn")  # Adjust if needed
