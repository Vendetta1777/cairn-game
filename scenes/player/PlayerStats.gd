extends Node
class_name PlayerStats
## Cairn — Player stats (GDD Section 3, tuned).
##
## Health is tracked in HALF-HEART units so damage can be a half-heart:
##   4 hearts = 8 halves; a bat hit = 1 half. Hearts are upgradeable later
##   (an NPC calls add_heart()). The HUD renders halves as full/half/empty masks.

signal health_changed(current_halves: int, max_halves: int)
signal shadow_changed(current: float, maximum: float)
signal shards_changed(total: int)
signal died

const HALVES_PER_HEART := 2

@export var max_hearts: int = 4
@export var max_shadow: float = 50.0   ## GDD: starts at 50, upgradeable to 100

var max_health: int                    ## in half-heart units
var health: int                        ## in half-heart units
var shadow: float
var echoes: int = 0
var shards: int = 0
var _shadow_regen: float = 0.0         ## per-second, from the Shadow skill branch


func _ready() -> void:
	# Pull everything persistent (hearts, currency) from PlayerProgress and fold
	# in the unlocked skill-tree bonuses, so a fresh player in any scene starts
	# with the player's permanent progression already applied.
	max_hearts = PlayerProgress.max_hearts()
	max_shadow += PlayerProgress.bonus("max_shadow")
	_shadow_regen = PlayerProgress.bonus("shadow_regen")
	max_health = max_hearts * HALVES_PER_HEART
	health = max_health
	shadow = max_shadow
	shards = PlayerProgress.shards
	echoes = PlayerProgress.echoes
	# Defer so the HUD (which connects in its own _ready) gets the initial values.
	call_deferred("_broadcast")


func _process(delta: float) -> void:
	if _shadow_regen > 0.0 and shadow < max_shadow:
		shadow = minf(max_shadow, shadow + _shadow_regen * delta)
		shadow_changed.emit(shadow, max_shadow)


func _broadcast() -> void:
	health_changed.emit(health, max_health)
	shadow_changed.emit(shadow, max_shadow)
	shards_changed.emit(shards)


## amount is in half-hearts (1 = half a heart).
func take_damage(amount: int = 1) -> void:
	if health <= 0:
		return
	health = max(0, health - amount)
	health_changed.emit(health, max_health)
	if health == 0:
		# Roguelite penalty: Echoes are dropped on death (Shards are kept).
		PlayerProgress.drop_echoes()
		echoes = 0
		died.emit()


func heal(halves: int) -> void:
	health = min(max_health, health + halves)
	health_changed.emit(health, max_health)


## Permanent heart upgrade (boss reward / skill tree). Persists via PlayerProgress
## and respects the hard MAX_HEARTS cap, so granting past the cap does nothing.
func add_heart(count: int = 1) -> void:
	PlayerProgress.bonus_hearts += count
	var new_max := PlayerProgress.max_hearts()
	var gained := new_max - max_hearts
	max_hearts = new_max
	max_health = max_hearts * HALVES_PER_HEART
	if gained > 0:
		health = min(max_health, health + gained * HALVES_PER_HEART)
	health_changed.emit(health, max_health)


func add_shards(count: int) -> void:
	shards += count
	PlayerProgress.add_shards(count)
	shards_changed.emit(shards)


func spend_shards(count: int) -> bool:
	if shards < count:
		return false
	shards -= count
	PlayerProgress.spend_shards(count)
	shards_changed.emit(shards)
	return true


func add_echoes(count: int) -> void:
	echoes += count
	PlayerProgress.add_echoes(count)


func spend_shadow(amount: float) -> bool:
	if shadow < amount:
		return false
	shadow -= amount
	shadow_changed.emit(shadow, max_shadow)
	return true


func refill_shadow(amount: float = -1.0) -> void:
	shadow = max_shadow if amount < 0.0 else min(max_shadow, shadow + amount)
	shadow_changed.emit(shadow, max_shadow)
