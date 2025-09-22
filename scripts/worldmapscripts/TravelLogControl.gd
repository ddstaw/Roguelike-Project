extends Control

# Access the RichTextLabel directly with the updated path
@onready var log_label = get_node_or_null("TravelLogPanel/TravelLogScrollContainer/TravelLogRichTextLabel")

func add_message_to_log(message_text: String):
	# Access the RichTextLabel directly using the full node path
	var log_label = get_node_or_null("TravelLogPanel/TravelLogScrollContainer/TravelLogRichTextLabel")
	
	if log_label:
		# Add the new message to the RichTextLabel
		log_label.append_text("\n.......\n\n" + message_text)
		
		# Access the ScrollContainer
		var scroll_container = get_node("TravelLogPanel/TravelLogScrollContainer")
		
		# Wait for a frame to ensure the content size is updated
		await get_tree().process_frame

		# Get the vertical scrollbar and adjust the position to the maximum
		var v_scrollbar = scroll_container.get_v_scroll_bar()
		if v_scrollbar:
			v_scrollbar.value = v_scrollbar.max_value
			#print("Scrolled to the bottom.")
		
		#print("Added message to log:", message_text)
	else:
		print("Error: TravelLogRichTextLabel not found at the specified path.")
