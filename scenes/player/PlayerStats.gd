extends Node
class_name PlayerStats
## Cairn — Player stats (GDD Section 3, tuned).
##
## Health is tracked in HALF-HEART units so damage can be a half-heart:
##   4 hearts = 8 halves; a bat hit = 1 half. Hearts are upgradeable later
##   (an NPC calls add_heart()). The HUD renders halves as full/half/empty masks.

signal health_changed(current_halves: int, max_halves: int)
signal shadow_changed(current: float, maximum: float)
signal died

const HALVES_PER_HEART := 2

@export var max_hearts: int = 4
@export var max_shadow: float = 50.0   ## GDD: starts at 50, upgradeable to 100

var max_health: int                    ## in half-heart units
var health: int                        ## in half-heart units
var shadow: float
var echoes: int = 0
var shards: int = 0


func _ready() -> void:
	max_health = max_hearts * HALVES_PER_HEART
	health = max_health
	shadow = max_shadow
	# Defer so the HUD (which connects in its own _ready) gets the initial values.
	call_deferred("_broadcast")


func _broadcast() -> void:
	health_changed.emit(health, max_health)
	shadow_changed.emit(shadow, max_shadow)


## amount is in half-hearts (1 = half a heart).
func take_damage(amount: int = 1) -> void:
	if health <= 0:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		died.emit()


func heal(halves: int) -> void:
	health = min(max_health, health + halves)
	health_changed.emit(health, max_health)


## Permanent heart upgrade (the future NPC). Also tops up the new heart.
func add_heart(count: int = 1) -> void:
	max_hearts += count
	max_health = max_hearts * HALVES_PER_HEART
	health = min(max_health, health + count * HALVES_PER_HEART)
	health_changed.emit(health, max_health)


func spend_shadow(amount: float) -> bool:
	if shadow < amount:
		return false
	shadow -= amount
	shadow_changed.emit(shadow, max_shadow)
	return true


func refill_shadow(amount: float = -1.0) -> void:
	shadow = max_shadow if amount < 0.0 else min(max_shadow, shadow + amount)
	shadow_changed.emit(shadow, max_shadow)
