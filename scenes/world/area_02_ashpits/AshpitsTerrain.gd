extends "res://scenes/world/CaveTerrain.gd"
## Cairn — Area 2 "THE ASHPITS" layout: a collapsed industrial zone of dead
## furnaces and ember vents. Four chambers, left to right:
##   C1 ENTRY CHAMBER  — arrival from the Hollowed Gate's chasm; a vent teaches
##                       lift-riding (cache on the high ledge).
##   C2 FORGE FLOOR    — wide combat hall, cinder wraiths between dead forges;
##                       the WALL JUMP relic waits at its far end.
##   C3 THE CLIMB      — a wall-jump chimney up through the machine strata
##                       (gated by a wall-jump ward: no relic, no entry).
##   C4 ANTECHAMBER + ARENA — a last rest, then the Ashen Warden's furnace hall
##                       with a vent platform at either side.
## Sooty, heat-cracked palette set in _init (the CaveTerrain vars).

const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 3460, 14),        # ceiling
	Rect2(0, 0, 14, 288),         # left wall
	Rect2(3446, 0, 14, 288),      # right wall

	# C1 — ENTRY CHAMBER x14..820
	Rect2(14, 252, 806, 36),
	Rect2(260, 205, 90, 16),
	Rect2(520, 178, 90, 16),
	Rect2(620, 118, 110, 14),     # high ledge — ride the vent up (cache)

	# C2 — THE FORGE FLOOR x880..1900 (spike gap 820..880)
	Rect2(880, 252, 1020, 36),
	Rect2(1050, 198, 100, 14),    # dead-forge walkways
	Rect2(1250, 168, 100, 14),
	Rect2(1480, 198, 100, 14),
	Rect2(1700, 162, 90, 14),     # high walkway — dash-gated cache

	# C3 — THE CLIMB x1960..2440 (spike gap 1900..1960)
	Rect2(1960, 252, 200, 36),    # chimney approach floor
	Rect2(2064, 238, 96, 14),     # chimney base
	Rect2(2070, 96, 14, 94),      # left chimney wall
	Rect2(2146, 96, 14, 94),      # right chimney wall
	Rect2(2160, 100, 90, 14),     # top exit ledge
	Rect2(2300, 158, 80, 14),     # descend...
	Rect2(2400, 210, 80, 14),     # ...to the antechamber

	# C4 — ANTECHAMBER + ARENA x2480..3446
	Rect2(2480, 252, 966, 36),    # one long furnace-hall floor
	Rect2(2780, 148, 70, 14),     # left vent platform (arena)
	Rect2(3290, 148, 70, 14),     # right vent platform (arena)
]

const OBJECTS: Array[Rect2] = [
	Rect2(180, 220, 28, 32),      # scattered forge crates
	Rect2(980, 220, 28, 32),
	Rect2(1600, 220, 28, 32),
	Rect2(2540, 220, 28, 32),
]

const HAZARDS: Array[Rect2] = [
	Rect2(820, 262, 60, 26),      # C1 -> C2 spike gap
	Rect2(1900, 262, 60, 26),     # C2 -> C3 spike gap
]

const MOSS_SPOTS := [Vector2(300, 198), Vector2(1100, 192), Vector2(2520, 244)]


func _init() -> void:
	# Soot, rust and heat-cracked stone instead of the cool cave blues.
	ROCK_A = Color(0.17, 0.12, 0.1)
	ROCK_B = Color(0.23, 0.16, 0.125)
	STONE_DEEP = Color(0.07, 0.045, 0.04)
	SPECK_LIGHT = Color(0.38, 0.26, 0.18)
	SPECK_DARK = Color(0.08, 0.05, 0.04)
	RIM = Color(0.45, 0.3, 0.2)
	RIM_HI = Color(0.62, 0.42, 0.26)
	MOSS_D = Color(0.5, 0.22, 0.08)      # ember lichen, not moss
	MOSS_L = Color(0.95, 0.5, 0.2)
	ROOT = Color(0.1, 0.06, 0.05)
	STAL = Color(0.14, 0.1, 0.09)
	STAL_HI = Color(0.28, 0.19, 0.14)


func solids() -> Array[Rect2]:
	return TERRAIN

func objects() -> Array[Rect2]:
	return OBJECTS

func hazards() -> Array[Rect2]:
	return HAZARDS

func moss_spots() -> Array:
	return MOSS_SPOTS


## A lower, heavier industrial roof, sagging between old supports.
func ceiling_y(x: float) -> float:
	return 46.0 + sin(x * 0.011 + 1.0) * 10.0 + sin(x * 0.033 + 0.4) * 6.0 + sin(x * 0.07 + 2.0) * 2.5
