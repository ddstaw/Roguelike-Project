extends Button

var tile_forest = preload("res://assets/graphics/36x36-forest.png")
var tile_mountains = preload("res://assets/graphics/36x36-mountains.png")
var tile_grass = preload("res://assets/graphics/36x36-grass.png")
var tile_ocean = preload("res://assets/graphics/36x36-ocean.png")

# Reference to the main NewGame node
var newgame: Node = null
var randomizer: Node = null

func _ready():
	# Assuming the NewGame node is a sibling of the button or higher up in the tree
	newgame = get_node("/root/NewGame")
	randomizer = newgame.get_node("RandomizerNode")
	
	# Connect the button's pressed signal in Godot 4.x
	self.pressed.connect(_on_pressed)

	# Override mouse enter event to handle hover effect responsiveness - had lagging issues - needs help
	self.mouse_entered.connect(_on_hover_entered)

func _on_hover_entered():
	# Prioritize hover effect by handling it immediately
	self.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8)) # Example hover effect

	# Optionally, handle other UI changes or effects here

func _on_pressed():
	if not newgame or not randomizer:
		print("NewGame or Randomizer nodes not found.")
		return
	
	if not newgame.loaded_tiles.has("res://assets/graphics/36x36-forest.png"):
		newgame.loaded_tiles["res://assets/graphics/36x36-forest.png"] = load("res://assets/graphics/36x36-forest.png")
	
	# Use call_deferred to delay the execution and reduce stuttering
	call_deferred("_randomize_and_update")

func _randomize_and_update():
	# Randomize the grid and update the map
	newgame.grid_data = randomizer.randomize_grid()
	randomizer.save_grid_data(newgame.grid_data)
	newgame.create_grid()
