# res://constants/npc_states.gd
class_name NpcStates

# 🌀 Basic behavior states
const DAZZED     := "dazzed"      # Wanders randomly
const IDLE       := "idle"        # Does nothing
const PATROL     := "patrol"      # Moves between set points
const FOLLOW     := "follow"      # Follows target (e.g. pet)
const GUARD      := "guard"       # Stationary unless provoked
const VENDOR     := "vendor"      # Does not move, can interact
const FLEE       := "flee"        # Runs from threats
const CHASE      := "chase"       # Pursues targets
