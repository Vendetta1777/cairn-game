extends "res://scenes/world/CaveTerrain.gd"
## Cairn — Area 1 "The Hollowed Gate" layout. A learning cave: each section
## teaches ONE mechanic, left to right. Pits between sections are bottomless
## (a miss = a fall) and spike-lined. Moving platforms (in Area1.tscn) live in
## open pits so they never clip a fixed ledge. All drawing/physics is in the
## CaveTerrain base — this file is just the layout data.

const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 3700, 14),        # ceiling
	Rect2(0, 0, 14, 288),         # left wall
	Rect2(3686, 0, 14, 288),      # right wall

	# S1 — THE WAKING (move + jump): safe ground, gentle hops
	Rect2(14, 252, 686, 36),      # x14..700
	Rect2(300, 210, 110, 16),
	Rect2(470, 180, 100, 16),
	Rect2(560, 132, 100, 14),     # the loft — a dash-gated cache sits up here

	# S2 — THE ROOST (combat: bats)
	Rect2(760, 252, 560, 36),     # x760..1320
	Rect2(930, 205, 90, 16),
	Rect2(1130, 198, 90, 16),

	# S3 — THE GAPS (precise jumps over spikes): pit 1380..1900
	Rect2(1320, 252, 60, 36),     # entry ledge (checkpoint)
	Rect2(1410, 222, 72, 14),
	Rect2(1540, 206, 66, 14),
	Rect2(1670, 222, 66, 14),
	Rect2(1800, 210, 72, 14),
	Rect2(1900, 252, 90, 36),     # landing

	# S4 — THE TIDES (moving platforms): pit 1990..2480
	Rect2(2240, 205, 80, 14),     # mid-pit rest (between the two movers)
	Rect2(2200, 128, 90, 14),     # high loft above the rest — double-jump only
	Rect2(2480, 252, 110, 36),    # landing

	# S5 — THE CROSSING: pit 2590..2900, a rhythm of hops at staggered heights.
	# (No wall-jump anything here — that power is found in The Ashpits.)
	Rect2(2624, 230, 56, 14),     # stepping stone
	Rect2(2716, 242, 72, 14),     # low mid stone
	Rect2(2826, 218, 64, 14),     # last hop to the arena side

	# S6 — THE BROOD (boss arena + chasm + threshold)
	Rect2(2900, 252, 786, 36),    # x2900..3686
]

const OBJECTS: Array[Rect2] = [
	Rect2(230, 220, 28, 32),
	Rect2(1020, 220, 28, 32),
]

const HAZARDS: Array[Rect2] = [
	Rect2(1380, 262, 520, 26),    # S3
	Rect2(1990, 262, 490, 26),    # S4
	Rect2(2590, 262, 310, 26),    # S5
]

const MOSS_SPOTS := [Vector2(355, 198), Vector2(975, 193), Vector2(1575, 194), Vector2(2745, 236)]


func solids() -> Array[Rect2]:
	return TERRAIN

func objects() -> Array[Rect2]:
	return OBJECTS

func hazards() -> Array[Rect2]:
	return HAZARDS

func moss_spots() -> Array:
	return MOSS_SPOTS
