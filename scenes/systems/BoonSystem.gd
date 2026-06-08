extends Node
class_name BoonSystem
## Cairn — Shrine / run boons (STUB, full impl in M6).
##
## Shrines (one per area) offer 3 random boons that last the CURRENT RUN only
## (cleared on death). Examples: +2 max health this run, parries deal 2x,
## shadow bolt fires on dodge, daggers auto-return. (GDD Section 9.)

var active_boons: Array[StringName] = []


func grant(boon_id: StringName) -> void:
	if boon_id not in active_boons:
		active_boons.append(boon_id)


func has(boon_id: StringName) -> bool:
	return boon_id in active_boons


## Called on death — boons do not survive runs.
func clear_run() -> void:
	active_boons.clear()
