extends Button

func _ready():
	# Connect the button's pressed signal using Callable
	connect("pressed", Callable(self, "_on_pressed"))
	print("Button ready and connected.")  # Debugging line

func _on_pressed():
	print("Button pressed!")  # Confirm the button reacts to clicks

	# Navigate to the correct node where backgrounddata.gd is attached
	var background_data = get_parent().get_node("backgroundPanel/backgrounddata")  # Adjusted to reflect the correct path
	if background_data != null:
		print("backgrounddata node found:", background_data.name)
		
		# Check if the script instance has the cycle_background method
		if background_data.has_method("cycle_background"):
			print("Calling cycle_background method from the script attached to:", background_data.name)
			background_data.cycle_background()
		else:
			print("Error: cycle_background method not found in the script attached to", background_data.name)
	else:
		print("Error: backgrounddata node not found. Check the node path.")
