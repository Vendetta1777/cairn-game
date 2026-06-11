extends "res://scenes/world/CaveTerrain.gd"
## Cairn — Area 2 "The Sunken Way" layout. Deeper than the Hollowed Gate and
## traversal-focused (enemies come later): you descend in, then the cave throws
## a moving-stone crossing, a precise gap run, a second moving stretch, and a
## wall-jump chimney before a quiet hall with the Sanctum portal. Different
## platform heights/spacing and a tighter, more vertical feel than Area 1.

const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 3140, 14),        # ceiling
	Rect2(0, 0, 14, 288),         # left wall
	Rect2(3126, 0, 14, 288),      # right wall

	# S1 — LANDING (you descended here): safe, a couple of high perches
	Rect2(14, 252, 666, 36),      # x14..680
	Rect2(240, 200, 100, 16),
	Rect2(470, 172, 90, 16),

	# (intro moving stone bridges pit 680..800)
	# S2 — ledge after the first stone
	Rect2(800, 252, 360, 36),     # x800..1160
	Rect2(980, 204, 90, 16),

	# S3 — THE GAPS (precise jumps over spikes): pit 1160..1600, tighter than A1
	Rect2(1230, 226, 66, 14),
	Rect2(1360, 198, 60, 14),
	Rect2(1490, 224, 66, 14),
	Rect2(1600, 252, 160, 36),    # landing x1600..1760

	# S4 — MOVING STONES: pit 1760..2200, two stones + a mid rest (movers in tscn)
	Rect2(1990, 198, 80, 14),     # mid rest (between the two stones)
	Rect2(2200, 252, 160, 36),    # landing x2200..2360

	# S5 — THE CLIMB (wall jump): pit 2360..2760, chimney
	Rect2(2420, 232, 56, 14),     # stepping stone
	Rect2(2500, 238, 96, 14),     # chimney base
	Rect2(2506, 120, 14, 70),     # left wall
	Rect2(2582, 120, 14, 70),     # right wall
	Rect2(2596, 124, 110, 16),    # exit ledge -> drop to the final hall

	# S6 — THE QUIET HALL (Sanctum portal lives here)
	Rect2(2760, 252, 366, 36),    # x2760..3126
]

const OBJECTS: Array[Rect2] = [
	Rect2(180, 220, 28, 32),
	Rect2(880, 220, 28, 32),
]

const HAZARDS: Array[Rect2] = [
	Rect2(680, 262, 120, 26),     # intro stone pit
	Rect2(1160, 262, 440, 26),    # S3
	Rect2(1760, 262, 440, 26),    # S4
	Rect2(2360, 262, 400, 26),    # S5
]

const MOSS_SPOTS := [Vector2(300, 198), Vector2(900, 200), Vector2(1620, 240)]


func solids() -> Array[Rect2]:
	return TERRAIN

func objects() -> Array[Rect2]:
	return OBJECTS

func hazards() -> Array[Rect2]:
	return HAZARDS

func moss_spots() -> Array:
	return MOSS_SPOTS


## A deeper, lower roof than Area 1, for a more enclosed feel.
func ceiling_y(x: float) -> float:
	return 52.0 + sin(x * 0.017 + 0.5) * 13.0 + sin(x * 0.037 + 2.0) * 7.0 + sin(x * 0.07) * 3.0
