extends Node2D

@onready var light_mask_sprite: Sprite2D = $LightMask
@onready var shader_material: ShaderMaterial = light_mask_sprite.material as ShaderMaterial

const TILE_SIZE := 88

var light_image: Image
var light_texture: ImageTexture
var _last_light_hash := 0
var dirty_tiles := {}
var local_map_node: Node = null
var map_width: int = 0
var map_height: int = 0

signal ready_signal
var is_ready := false

func initialize(walk_grid: Array, tile_size: int) -> void:
	map_height = walk_grid.size()
	map_width = walk_grid[0].size()
	
	light_image = Image.create(map_width + 2, map_height + 2, false, Image.FORMAT_RGBA8)
	light_image.fill(Color(0, 0, 0, 1.0))  # Fully dark initially

	light_texture = ImageTexture.create_from_image(light_image)
	light_mask_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	
	light_mask_sprite.texture = light_texture
	light_mask_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	light_mask_sprite.position = Vector2.ZERO  # offset 1px for padding
	light_mask_sprite.visible = false

	shader_material.set_shader_parameter("light_texture", light_texture)
	shader_material.set_shader_parameter("light_texture_size", Vector2(map_width + 2, map_height + 2))
	shader_material.set_shader_parameter("tile_size", Vector2(TILE_SIZE, TILE_SIZE))

	await get_tree().process_frame
	is_ready = true
	emit_signal("ready_signal")
	print("✅ LightOverlay.initialize() complete — light engine ready.")


func update_light_map(
	visible_tiles: Dictionary,
	light_map: Array,
	sunlight_level: float,
	has_nightvision: bool
) -> void:
	if light_texture == null or light_image == null:
		print("❌ LightOverlay: light_texture or light_image is null — skipping update.")
		return

	print("🌌 Updating light map in LightOverlay.gd")
	print("🧪 Total dirty_tiles:", dirty_tiles.size())

	var min_fade_radius: float = 6.0
	var max_distance_squared: float = pow(min_fade_radius, 2)

	# 🧼 Start clean
	light_image.fill(Color(0, 0, 0, 1.0))

	for pos in dirty_tiles.keys():
		if not pos.x in range(map_width) or not pos.y in range(map_height):
			continue
		if pos.y < 0 or pos.y >= light_map.size():
			continue
		if pos.x < 0 or pos.x >= light_map[pos.y].size():
			continue

		var light_strength: float = light_map[pos.y][pos.x]
		var final_light: float = 0.0

		if visible_tiles.has(pos):
			var dist_val: float = float(visible_tiles[pos])

			var total_light: float = light_strength
			if sunlight_level > 0.0:
				total_light += sunlight_level
			if has_nightvision:
				total_light = 1.0

			var edge_fade: float = 1.0
			if dist_val >= 0.0 and dist_val < 99999.0:
				# 📏 Distance fade for player-FOV tiles
				edge_fade = clamp(1.0 - (dist_val / max_distance_squared), 0.0, 1.0)

			var softness: float = pow(edge_fade, 2.2)
			var glow: float = total_light * 0.1
			final_light = clamp(total_light * softness + glow, 0.0, 1.0)

			if dist_val == -2.0:
				print("✨ Drawing static-visible tile:", pos, "| Light:", light_strength)

		else:
			# 🌌 Ambient fallback
			final_light = clamp(light_strength, 0.0, 1.0)

		var darkness: float = 1.0 - final_light
		light_image.set_pixel(pos.x + 1, pos.y + 1, Color(0, 0, 0, darkness))

	# 🚀 Push to GPU
	light_texture.update(light_image)
	shader_material.set_shader_parameter("light_texture", light_texture)
	dirty_tiles.clear()



func should_redraw_light(visible_tiles: Dictionary, sunlight: float, has_nv: bool) -> bool:
	var hash := visible_tiles.hash() ^ int(sunlight * 100) ^ int(has_nv)
	if hash != _last_light_hash:
		_last_light_hash = hash
		return true
	return false
