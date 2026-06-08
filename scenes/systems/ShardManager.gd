extends Node
class_name ShardManager
## Cairn — Shards, the hard currency (STUB, full impl in M6).
##
## Shards are KEPT on death and spent on the permanent skill tree (30 nodes,
## GDD Section 9). Respec costs 50 Shards. Some enemies + every mini-boss drop them.

signal shards_changed(total: int)

var total: int = 0


func add(amount: int) -> void:
	total += amount
	shards_changed.emit(total)


func spend(amount: int) -> bool:
	if total < amount:
		return false
	total -= amount
	shards_changed.emit(total)
	return true
