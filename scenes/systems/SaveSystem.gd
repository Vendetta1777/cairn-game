extends Node
class_name SaveSystem
## Cairn — Save system (STUB, full impl in M6 / GDD Section 13).
##
## 3 save slots. Auto-save on: checkpoint activation, area transition,
## boss death, ability unlock. Save data: area progress, abilities,
## skill tree, Shards, lore fragments, NPC dialogue states, ending flags.
##
## Stubbed now so call sites can reference it during M2–M5.

const SAVE_DIR := "user://saves/"
const SLOT_COUNT := 3


func save_slot(_slot: int, _data: Dictionary) -> void:
	pass  # M6: write JSON to user://saves/slot_<n>.save


func load_slot(_slot: int) -> Dictionary:
	return {}  # M6: read + parse


func slot_exists(_slot: int) -> bool:
	return false
