extends Button

func _ready():
	# Connect the button's pressed signal to the function
	connect("pressed", Callable(self, "_on_ProceedButton_pressed"))

func _on_ProceedButton_pressed():
	# Get the SettlementPlacementNode
	var settlement_placement_node = get_node("/root/CultureMap/SettlementPlacementNode")

	if settlement_placement_node:
		# Call the place_settlements function
		settlement_placement_node.place_settlements()

