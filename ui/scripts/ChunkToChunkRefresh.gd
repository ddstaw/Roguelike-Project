# res://ui/scripts/ChunkToChunkRefresh.gd
extends Control

func _ready() -> void:
	# Delegate the entire cinematic to the autoload
	await FadeLayer.fade_to_scene("res://scenes/play/LocalMap.tscn")

func _safe_begin_transition() -> void:
	var tree := Engine.get_main_loop()
	while tree == null or not (tree is SceneTree):
		await Engine.get_main_loop().process_frame
		tree = Engine.get_main_loop()
	await _do_chunk_transition(tree as SceneTree)

func _do_chunk_transition(tree: SceneTree) -> void:
	print("🎞️ Fading out before reload...")
	await FadeLayer.fade_out(0.8)

	await tree.create_timer(0.1).timeout
	tree.change_scene_to_file("res://scenes/play/LocalMap.tscn")

	await tree.create_timer(0.6).timeout
	print("🌅 Fading back in...")
	await FadeLayer.fade_in(1.0)
