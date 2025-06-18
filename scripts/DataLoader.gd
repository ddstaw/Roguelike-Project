extends Node

var items = {}
var prefixes = {}
var suffixes = {}
var world_gen_rules = {}

func _ready():
	items = load_json("res://data/items.json")
	prefixes = load_json("res://data/prefixes.json")
	suffixes = load_json("res://data/suffixes.json")
	world_gen_rules = load_json("res://data/world_gen_rules.json")

func load_json(file_path):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		var json = JSON.new()  # Create an instance of the JSON class
		var parsed_data = json.parse(json_data)
		if parsed_data.error == OK:
			return parsed_data.result
		else:
			print("Failed to parse JSON: ", file_path)
	return {}
