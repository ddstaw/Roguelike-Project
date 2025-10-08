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

# Optional convenience alias (not required but nice for clarity)
func update_position(grid_pos: Vector2i, tile_size: int) -> void:
	set_grid_position(grid_pos, tile_size)
