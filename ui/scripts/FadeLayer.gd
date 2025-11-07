# res://ui/scripts/FadeLayer.gd
extends CanvasLayer
# Autoload as "FadeLayer" (no class_name)

@onready var rect := ColorRect.new()

func _ready() -> void:
	layer = 100
	add_child(rect)
	rect.color = Color.BLACK
	rect.modulate.a = 0.0
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.z_index = 4096
	rect.size = get_viewport().get_visible_rect().size
	get_viewport().connect("size_changed", Callable(self, "_on_resize"))

func _on_resize() -> void:
	rect.size = get_viewport().get_visible_rect().size


## --- Core fade helpers ---
func fade_out(duration := 0.6, color := Color.BLACK) -> void:
	rect.color = color
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	await tween.finished

func fade_in(duration := 0.6) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	await tween.finished


## --- Cinematic transition that survives scene reload ---
func fade_to_scene(scene_path: String) -> void:
	print("🎬 Fading to scene:", scene_path)
	await fade_out(0.8)

	# Now switch scenes while black
	var tree := Engine.get_main_loop()
	if tree and tree is SceneTree:
		tree.change_scene_to_file(scene_path)
	else:
		push_warning("⚠️ SceneTree missing during fade transition!")
		return

	# Give new scene one frame to load before fading back
	await Engine.get_main_loop().process_frame
	await fade_in(1.0)
