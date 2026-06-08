extends Node
class_name PlayerStats
## Cairn — Player stats (GDD Section 3).
##
## Health (masks), shadow energy, and the two currencies (Echoes / Shards).
## M1 scope: data + signals so the HUD (M5) and managers (M6) can bind to it.
## Combat damage application is wired in M3.

signal health_changed(current: int, maximum: int)
signal shadow_changed(current: float, maximum: float)
signal died

@export var max_health: int = 6        ## GDD: starts at 6, upgradeable to 12
@export var max_shadow: float = 50.0   ## GDD: starts at 50, upgradeable to 100

var health: int
var shadow: float
var echoes: int = 0                    ## soft currency — dropped on death
var shards: int = 0                    ## hard currency — kept on death


func _ready() -> void:
	health = max_health
	shadow = max_shadow


func take_damage(amount: int) -> void:
	if health <= 0:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()


func heal(amount: int) -> void:
	health = min(max_health, health + amount)
	health_changed.emit(health, max_health)


## Try to spend shadow energy; returns false (and spends nothing) if too low.
func spend_shadow(amount: float) -> bool:
	if shadow < amount:
		return false
	shadow -= amount
	shadow_changed.emit(shadow, max_shadow)
	return true


func refill_shadow(amount: float = -1.0) -> void:
	shadow = max_shadow if amount < 0.0 else min(max_shadow, shadow + amount)
	shadow_changed.emit(shadow, max_shadow)
