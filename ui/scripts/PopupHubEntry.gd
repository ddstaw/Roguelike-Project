extends Window

@onready var hub_name_label = $hubnamelabel
@onready var yes_button = $VBoxContainer/YesEnterButton
@onready var no_button = $VBoxContainer/NoDontButton

func _ready():
	var player_position = LoadHandlerSingleton.get_player_position()
	var biome_name = LoadHandlerSingleton.get_biome_name(player_position)
	
	# ✅ Generate a clean display name
	var hub_display = biome_name.capitalize()
	hub_name_label.text = hub_display.to_upper()

	# ✅ Contextual button text
	match biome_name:
		"tradepost":
			yes_button.text = "VISIT TRADEPOST"
		"fort":
			yes_button.text = "ENTER FORT"
		"guildhall":
			yes_button.text = "ENTER GUILDHALL"
		_:
			yes_button.text = "ENTER HUB"

	# ✅ Wire up signals
	yes_button.connect("pressed", Callable(self, "_on_yes_pressed").bind(biome_name))
	no_button.connect("pressed", Callable(self, "_on_no_pressed"))
	connect("close_requested", Callable(self, "_on_no_pressed"))

func _on_yes_pressed(hub_biome: String):
	print("🏪 Entering static hub biome:", hub_biome)

	# ✅ Entry context for static hubs
	var entry_context := {
		"entry_type": hub_biome,
		"realm": "worldmap",
		"realm_position": LoadHandlerSingleton.get_player_position(),
		"target_biome": hub_biome,
		"hub_name": hub_biome.capitalize() + " Hub"
	}

	LoadHandlerSingleton.save_entry_context(entry_context)
	print("✅ Entry context saved for hub:", entry_context)

	# ✅ Move directly to LocalMap via refresh handler
	get_tree().change_scene_to_file("res://scenes/play/WorldtoLocalRefresh.tscn")
	queue_free()

func _on_no_pressed():
	queue_free()
