extends CanvasLayer

@onready var category_containers = {
	"craft": $Panel/ScrollContainer/VBoxContainer/VBoxContainerHBoxCraft/HBoxCraft,
	"structures": $Panel/ScrollContainer/VBoxContainer/VBoxContainerHBoxStructures/HBoxStructures,
	"furni": $Panel/ScrollContainer/VBoxContainer/VBoxContainerHBoxFurniture/HBoxFurniture,
	"storage": $Panel/ScrollContainer/VBoxContainer/VBoxContainerHBoxStorage/HBoxStorage,
	"deco": $Panel/ScrollContainer/VBoxContainer/VBoxContainerHBoxDeco/HBoxDeco,
	"farm": $Panel/ScrollContainer/VBoxContainer/VBoxContainerHBoxFarm/HBoxFarm,
	"special": $Panel/ScrollContainer/VBoxContainer/VBoxContainerHBoxSpecial/HBoxSpecial
}


@onready var appraisal_panel = $BuildAppraisalPanel

var buildables = LoadHandlerSingleton.load_player_buildreg()
var buildables_data := {}
var current_selection := ""
var object_data := {}
var terrain_data := {}
var tag_info = preload("res://constants/tag_info.gd")


func _ready():
	buildables_data = preload("res://constants/build_data.gd").BUILD_PROPERTIES
	object_data = preload("res://constants/object_data.gd").OBJECT_PROPERTIES
	terrain_data = preload("res://constants/terrain_data.gd").TERRAIN_PROPERTIES

	populate_categories()


func populate_categories():
	# Clear old icons if overlay reopened
	for cat in category_containers.values():
		for child in cat.get_children():
			child.queue_free()

	var buildables = LoadHandlerSingleton.load_player_buildreg()
	for build_id in buildables.keys():
		if build_id == "current_build":
			continue

		if buildables_data.has(build_id):
			var build_info = buildables_data[build_id]
			var cat = build_info.get("cat", "misc")

			if category_containers.has(cat):
				var icon = TextureButton.new()

				# Use the world texture as the build icon
				var tex_id := ""

				if build_info.get("type") == "tile":
					tex_id = build_info.get("terrain_name", build_id)
				elif build_info.get("type") == "object":
					tex_id = build_info.get("object_name", build_id)
				else:
					tex_id = build_id  # fallback, for safety

				if Constants.TILE_TEXTURES.has(tex_id):
					icon.texture_normal = Constants.TILE_TEXTURES[tex_id]
					
				icon.tooltip_text = build_id.capitalize()
				icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				icon.size_flags_vertical = Control.SIZE_EXPAND_FILL
				icon.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
				icon.custom_minimum_size = Vector2(88, 88)


				icon.connect("pressed", Callable(self, "select_buildable").bind(build_id))

				category_containers[cat].add_child(icon)

				# Highlight if it's the current buildable
				if build_id == buildables.get("current_build", ""):
					icon.modulate = Color(1, 1, 0)  # yellow highlight
					
				var initial_build: String = buildables.get("current_build", "")
				if initial_build != "":
					select_buildable(initial_build)

func select_buildable(id: String):
	current_selection = id
	LoadHandlerSingleton.set_current_build(id)
	update_appraisal_panel(id)

	# Reset all buttons to default color
	for cat in category_containers.values():
		for child in cat.get_children():
			if child is TextureButton:
				child.modulate = Color(1, 1, 1)

	# Re-highlight the selected one
	var tex_id = ""
	var build_info = buildables_data.get(id, {})
	if build_info.get("type") == "tile":
		tex_id = build_info.get("terrain_name", id)
	elif build_info.get("type") == "object":
		tex_id = build_info.get("object_name", id)
	else:
		tex_id = id

	for cat in category_containers.values():
		for child in cat.get_children():
			if child is TextureButton and child.texture_normal == Constants.TILE_TEXTURES.get(tex_id, null):
				child.modulate = Color(1, 1, 0)


func update_appraisal_panel(id: String):
	var build_info = buildables_data.get(id, {})
	var name = get_name_from_data(id)
	var desc = get_desc_from_data(id)
	var tags = get_tags_from_data(id)

	appraisal_panel.get_node("Name").text = name
	appraisal_panel.get_node("Desc").text = desc

	# Build tag_text via tag_info lookup
	var display_tags := []
	for t in tags:
		if tag_info.SPECIAL_TAG_INFO.has(t):
			display_tags.append(tag_info.SPECIAL_TAG_INFO[t]["text"])
		else:
			display_tags.append(t.capitalize())
	var tag_text = ", ".join(display_tags)
	appraisal_panel.get_node("Tags").text = tag_text

	# Format requirements (pretty version)
	var requirements = build_info.get("requires", {})
	var req_lines = []

	for mat in requirements.keys():
		var words: Array

		# ✅ Special rename rule for metaljunk
		if mat == "metaljunk":
			words = ["Junk", "Metal"]
		else:
			words = Array(mat.split("_"))
			for i in range(words.size()):
				words[i] = words[i].capitalize()

		var pretty_mat = " ".join(words)
		var line = "%d× %s" % [requirements[mat], pretty_mat]
		req_lines.append(line)

	appraisal_panel.get_node("Requirements").text = "Requires:\n" + "\n".join(req_lines)
	
	# Set texture preview in appraisal panel
	var tex_id = ""
	if build_info.get("type") == "tile":
		tex_id = build_info.get("terrain_name", id)
	elif build_info.get("type") == "object":
		tex_id = build_info.get("object_name", id)
	else:
		tex_id = id  # fallback

	if Constants.TILE_TEXTURES.has(tex_id):
		appraisal_panel.get_node("TextureRect").texture = Constants.TILE_TEXTURES[tex_id]
	else:
		appraisal_panel.get_node("TextureRect").texture = null


# --- Helpers --- #

func get_name_from_data(id: String) -> String:
	if object_data.has(id):
		return object_data[id].get("name", id.capitalize())
	elif terrain_data.has(id):
		return terrain_data[id].get("name", id.capitalize())
	return id.capitalize()


func get_desc_from_data(id: String) -> String:
	if object_data.has(id):
		return object_data[id].get("desc", "")
	elif terrain_data.has(id):
		return terrain_data[id].get("desc", "")
	return ""


func get_tags_from_data(id: String) -> Array:
	if object_data.has(id):
		return object_data[id].get("tags", [])
	elif terrain_data.has(id):
		return terrain_data[id].get("tags", [])
	return []
