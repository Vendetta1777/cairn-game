extends Node
class_name PlayerCombat
## Cairn — Player combat (GDD Section 5).
##
## STUB for Milestone 1. The full system lands in M3:
##   - 4-hit dagger combo with tightening timing windows
##   - upward slash / downward pogo
##   - parry (4-frame window -> slow-mo + shadow refill + stagger)
##   - dash-cancel, throwable daggers, shadow bolt
##
## Kept as its own node now so Player.tscn's composition is final and M3 only
## fills in behaviour — no scene restructuring later.

signal attacked(combo_index: int)
signal parried

@export var combo_length: int = 4      ## GDD: 4-hit dagger combo (5th via skill tree)
@export var parry_window_frames: int = 4

# M3 will read the sibling PlayerController for facing + dash-cancel hooks.

func _ready() -> void:
	pass
