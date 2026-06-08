extends Node
class_name EchoManager
## Cairn — Echoes, the soft roguelite currency (STUB, full impl in M6).
##
## Echoes drop from enemies, are LOST on death (dropped at the death spot as a
## recoverable cache, Souls-style), and are spent on run boons + Remnant Stone
## reactivation. Hard currency (Shards) is handled by ShardManager.

signal echoes_changed(total: int)

var total: int = 0


func add(amount: int) -> void:
	total += amount
	echoes_changed.emit(total)


func spend(amount: int) -> bool:
	if total < amount:
		return false
	total -= amount
	echoes_changed.emit(total)
	return true
