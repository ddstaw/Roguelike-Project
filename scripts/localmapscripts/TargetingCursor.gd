extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

enum Mode {
	NONE,
	BUILD,
	AIM,
	INSPECT
}

var mode: Mode = Mode.NONE

func set_mode(m: Mode) -> void:
	mode = m
	sprite.visible = (mode != Mode.NONE)

	match mode:
		Mode.BUILD:
			sprite.texture = preload("res://assets/ui/tile_highlight.png")
		Mode.AIM:
			sprite.texture = preload("res://assets/ui/tile_target.png")
		Mode.INSPECT:
			sprite.texture = preload("res://assets/ui/invest_highlight.png")
		_:
			sprite.texture = null
			sprite.visible = false

func set_grid_position(grid_pos: Vector2i, tile_size: int) -> void:
	position = Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)

	if mode == Mode.BUILD:
		# Guard before accessing LocalMap
		if not is_inside_tree() or get_tree() == null or get_tree().root == null:
			# Can't safely query LocalMap yet
			return

		var local_map = get_tree().root.get_node_or_null("LocalMap")
		if local_map and local_map.has_method("is_valid_build_position"):
			var is_valid: bool = local_map.is_valid_build_position(grid_pos)
			if is_valid:
				sprite.texture = preload("res://assets/ui/tile_highlight.png")
			else:
				sprite.texture = preload("res://assets/ui/tile_highlight_invalid.png")

# Optional convenience alias (not required but nice for clarity)
func update_position(grid_pos: Vector2i, tile_size: int) -> void:
	set_grid_position(grid_pos, tile_size)
