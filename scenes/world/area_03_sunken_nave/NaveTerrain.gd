extends "res://scenes/world/CaveTerrain.gd"
## Cairn — Area 3 "THE SUNKEN NAVE" layout: a drowned cathedral. Four rooms,
## left to right:
##   R1 FLOODED ENTRY    — wade pools teach the water's drag.
##   R2 SUBMERGED LIBRARY— toppled shelf-tops cross a hall of DEEP water
##                         (touch it and the Nave keeps you). The DOUBLE JUMP
##                         relic waits on the far landing.
##   R3 BELL TOWER       — a double-jump-gated chimney ascent past the great
##                         bell, then down the broken arches.
##   R4 ANTECHAMBER      — the choir door (sealed; something sings behind it),
##                         a shrine, and the passage back to the Sanctum.
## Drowned-stone palette set in _init; the bell and sunken pews in _draw_extra.

const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 3200, 14),        # ceiling
	Rect2(0, 0, 14, 288),         # left wall
	Rect2(3186, 0, 14, 288),      # right wall

	# R1 — FLOODED ENTRY x14..760: the nave floor has GIVEN WAY in two places,
	# and black water fills the sunken basins to the brim. Wade through (it
	# drags) or hop the fallen lintel over the second pool.
	Rect2(14, 252, 136, 36),      # x14..150
	Rect2(150, 276, 140, 12),     # basin A floor — water fills the recess
	Rect2(290, 252, 140, 36),     # x290..430
	Rect2(430, 276, 130, 12),     # basin B floor
	Rect2(560, 252, 200, 36),     # x560..760
	Rect2(455, 206, 80, 14),      # fallen lintel over basin B

	# R2 — SUBMERGED LIBRARY x760..1890: shelf-tops over deep water
	Rect2(870, 224, 70, 14),
	Rect2(1000, 196, 70, 14),
	Rect2(1130, 224, 70, 14),
	Rect2(1260, 190, 70, 14),
	Rect2(1400, 222, 70, 14),
	Rect2(1540, 196, 70, 14),
	Rect2(1655, 228, 70, 14),
	Rect2(1750, 252, 140, 36),    # far landing (the relic)

	# R3 — BELL TOWER x1950..2470 (spike gap 1890..1950)
	Rect2(1950, 238, 110, 14),    # tower base
	Rect2(1956, 60, 14, 130),     # left tower wall
	Rect2(2046, 60, 14, 130),     # right tower wall
	Rect2(2060, 64, 90, 14),      # top exit ledge (under the bell)
	Rect2(2200, 140, 80, 14),     # broken arch...
	Rect2(2330, 200, 80, 14),     # ...stepping down

	# R4 — ANTECHAMBER x2410..3186: one more collapsed stretch of floor before
	# the choir door, drowned like the entry.
	Rect2(2410, 252, 350, 36),    # x2410..2760
	Rect2(2760, 276, 140, 12),    # sunken basin floor
	Rect2(2900, 252, 286, 36),    # x2900..3186
]

const OBJECTS: Array[Rect2] = [
	Rect2(80, 222, 26, 30),       # waterlogged crates
	Rect2(2520, 222, 26, 30),
]

const HAZARDS: Array[Rect2] = [
	Rect2(1890, 262, 60, 26),     # R2 -> R3 spike gap
]

const MOSS_SPOTS := [Vector2(250, 244), Vector2(1180, 216), Vector2(2600, 244)]


func _init() -> void:
	# Drowned stone: cold blue-greens, bioluminescent fungus instead of moss.
	ROCK_A = Color(0.09, 0.13, 0.15)
	ROCK_B = Color(0.12, 0.18, 0.2)
	STONE_DEEP = Color(0.03, 0.055, 0.065)
	SPECK_LIGHT = Color(0.2, 0.32, 0.33)
	SPECK_DARK = Color(0.03, 0.06, 0.06)
	RIM = Color(0.24, 0.4, 0.42)
	RIM_HI = Color(0.34, 0.56, 0.56)
	MOSS_D = Color(0.1, 0.42, 0.4)       # glowing fungus shelf
	MOSS_L = Color(0.35, 0.9, 0.8)
	ROOT = Color(0.05, 0.1, 0.1)
	STAL = Color(0.08, 0.12, 0.14)
	STAL_HI = Color(0.16, 0.26, 0.28)
	CRATE = Color(0.18, 0.2, 0.16)       # rotten wood
	CRATE_DK = Color(0.1, 0.12, 0.09)
	CRATE_LIP = Color(0.28, 0.32, 0.24)
	CRATE_BOLT = Color(0.38, 0.45, 0.4)


func solids() -> Array[Rect2]:
	return TERRAIN

func objects() -> Array[Rect2]:
	return OBJECTS

func hazards() -> Array[Rect2]:
	return HAZARDS

func moss_spots() -> Array:
	return MOSS_SPOTS


## High vaulted roof — it was a cathedral once.
func ceiling_y(x: float) -> float:
	return 36.0 + sin(x * 0.009 + 0.3) * 9.0 + sin(x * 0.027 + 1.6) * 5.0 + sin(x * 0.055) * 2.0


## The great bell in the tower, and the drowned pews of the antechamber.
func _draw_extra() -> void:
	_draw_bell(Vector2(2031, 50))
	for px in [2560.0, 2680.0, 2960.0, 3060.0]:
		_draw_pew(Vector2(px, 252.0))


func _draw_bell(at: Vector2) -> void:
	var patina := Color(0.25, 0.42, 0.4)
	var patina_d := Color(0.14, 0.26, 0.26)
	var hi := Color(0.4, 0.6, 0.55)
	# Yoke beam between the tower walls.
	draw_rect(Rect2(at.x - 38, at.y - 12, 76, 5), Color(0.1, 0.09, 0.08))
	# The bell: shoulder, waist, flared mouth.
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-7, -8), at + Vector2(7, -8), at + Vector2(11, 14),
		at + Vector2(15, 20), at + Vector2(-15, 20), at + Vector2(-11, 14)]), patina)
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-7, -8), at + Vector2(-2, -8), at + Vector2(-5, 14), at + Vector2(-11, 14)]), hi)
	draw_rect(Rect2(at.x - 15, at.y + 18, 30, 3), patina_d)
	draw_circle(at + Vector2(0, 24), 2.5, patina_d)   # the silent clapper
	draw_rect(Rect2(at.x - 3, at.y - 12, 6, 5), patina_d)


func _draw_pew(at: Vector2) -> void:
	var wood := Color(0.12, 0.13, 0.11)
	var wood_hi := Color(0.2, 0.22, 0.18)
	draw_rect(Rect2(at.x - 22, at.y - 10, 44, 3), wood_hi)   # seat
	draw_rect(Rect2(at.x - 20, at.y - 7, 3, 7), wood)        # legs
	draw_rect(Rect2(at.x + 17, at.y - 7, 3, 7), wood)
	draw_rect(Rect2(at.x - 22, at.y - 22, 3, 12), wood)      # leaning backrest
	draw_rect(Rect2(at.x - 22, at.y - 22, 44, 2), wood)
