extends Node

# Carry weight logic — reusable everywhere
static func get_carry_status(cur: float, max: int) -> Dictionary:
	var status := "Unencumbered"
	var color := Color.WHITE

	if cur > max:
		status = "Overburdened"
		color = Color.RED
	elif cur >= max - 10:
		status = "Heavy Load"
		color = Color.YELLOW
	else:
		status = "Unencumbered"
		color = Color.WHITE

	return {
		"status": status,
		"color": color,
		"text": "%s\n%.1f / %d" % [status, cur, max]
	}

# (Later you can expand this with buffs, curses, blessings, etc.)
# static func get_curse_status(...)
# static func get_blessing_status(...)
