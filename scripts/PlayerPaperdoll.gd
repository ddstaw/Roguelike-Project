extends Node2D

func _ready():
	var looks = LoadHandlerSingleton.load_player_looks()
	if looks:
		apply_appearance(looks)

func apply_appearance(data: Dictionary) -> void:
	set_sprite_texture($BaseSprite, data.get("base", ""))
	set_sprite_texture($ArmorSprite, data.get("armor", ""))
	set_sprite_texture($CapeSprite, data.get("cape", ""))
	set_sprite_texture($HatSprite, data.get("hat", ""))
	set_sprite_texture($MainWeaponSprite, data.get("main_weapon", ""))
	set_sprite_texture($OffhandSprite, data.get("offhand", ""))

func set_sprite_texture(sprite: Sprite2D, path: String) -> void:
	if path != "":
		sprite.texture = load(path)
	else:
		sprite.texture = null
