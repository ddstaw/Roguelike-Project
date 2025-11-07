# res://ui/scripts/IconBuilder.gd
class_name IconBuilder
extends Object

const ITEM_DATA := preload("res://constants/item_data.gd")

# 🔹 Combine multiple image layers into one composite texture
static func generate_layered_icon(layer_paths: Array[String]) -> Texture2D:
	if layer_paths.is_empty():
		return null

	# Sort overlays last so effects like "overlay" are drawn on top
	layer_paths.sort_custom(func(a, b):
		var a_overlay := String(a).to_lower().find("overlay") != -1
		var b_overlay := String(b).to_lower().find("overlay") != -1
		return a_overlay < b_overlay
	)

	var base_image: Image = null

	for path in layer_paths:
		if !ResourceLoader.exists(path):
			push_warning("⚠️ Missing layer path: %s" % path)
			continue

		var tex := ResourceLoader.load(path) as Texture2D
		if tex == null:
			continue

		var img := tex.get_image()
		if base_image == null:
			base_image = img.duplicate()
			continue

		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var base_col := base_image.get_pixel(x, y)
				var layer_col := img.get_pixel(x, y)
				base_image.set_pixel(x, y, layer_col.blend(base_col))

	return ImageTexture.create_from_image(base_image)


# 🔹 Retrieve the correct icon for any item dictionary
static func get_icon_for_item(item: Dictionary) -> Texture2D:
	# Priority 1: multi-layer custom icon on the item
	if item.has("img_layers") and item["img_layers"] is Array:
		var layers: Array[String] = []
		for p in item["img_layers"]:
			layers.append(str(p))
		layers.reverse()
		return generate_layered_icon(layers)

	# Priority 2: direct single image path on the item
	var path := str(item.get("img_path", ""))
	if path != "" and ResourceLoader.exists(path):
		return ResourceLoader.load(path) as Texture2D

	# Priority 3: fallback to ITEM_DATA default path
	var def: Dictionary = ITEM_DATA.ITEM_PROPERTIES.get(str(item.get("item_ID", "")), {})
	var fallback := str(def.get("img_path", ""))
	if fallback != "" and ResourceLoader.exists(fallback):
		return ResourceLoader.load(fallback) as Texture2D

	return null
