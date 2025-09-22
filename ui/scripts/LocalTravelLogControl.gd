extends Control

@onready var log_label: RichTextLabel = get_node_or_null("TravelLogPanel/TravelLogScrollContainer/TravelLogRichTextLabel") as RichTextLabel
@onready var scroll_container: ScrollContainer = get_node_or_null("TravelLogPanel/TravelLogScrollContainer") as ScrollContainer

func add_message_to_log(message_text: String) -> void:
	var label: RichTextLabel = log_label
	if not is_instance_valid(label):
		label = get_node_or_null("TravelLogPanel/TravelLogScrollContainer/TravelLogRichTextLabel") as RichTextLabel

	var scroll: ScrollContainer = scroll_container
	if not is_instance_valid(scroll):
		scroll = get_node_or_null("TravelLogPanel/TravelLogScrollContainer") as ScrollContainer

	if label == null or scroll == null:
		print("Error: TravelLogRichTextLabel or ScrollContainer not found at the specified path.")
		return

	# capture old scroll range BEFORE append
	var vbar: VScrollBar = scroll.get_v_scroll_bar()
	var old_max: float = vbar.max_value

	# append
	label.append_text("\n.......\n\n" + message_text)
	#print("Added message to log:", message_text)

	# defer until the range actually grows
	call_deferred("_scroll_to_bottom_when_ready", old_max)


func _scroll_to_bottom_when_ready(old_max: float) -> void:
	if scroll_container == null:
		return

	var vbar: VScrollBar = scroll_container.get_v_scroll_bar()

	# wait up to a few frames for the content/scrollbar to expand
	var tries: int = 4
	while tries > 0:
		await get_tree().process_frame
		if vbar.max_value > old_max:
			break
		tries -= 1

	# force to bottom (use both APIs to be extra safe)
	scroll_container.scroll_vertical = vbar.max_value
	vbar.value = vbar.max_value

	# pin horizontal to 0 (prevents left-edge clipping if wrapping)
	var hbar: HScrollBar = scroll_container.get_h_scroll_bar()
	hbar.value = hbar.min_value
