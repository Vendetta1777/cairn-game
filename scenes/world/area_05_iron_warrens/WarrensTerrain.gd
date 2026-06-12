extends "res://scenes/world/CaveTerrain.gd"
## Cairn — Area 5 "THE IRON WARRENS": the kingdom's collapsed mines. Rust,
## chains, low ceilings, and ore veins that still glow cyan in the dark.
## Five rooms, left to right:
##   R1 SHAFT ENTRANCE   — timbered tunnel; learn to WALK (the blind diggers
##                         hear running).
##   R2 ORE FLOOR        — diggers among the glowing veins.
##   R3 THE DEEP RAILS   — a minecart gauntlet over a long spiked pit (or a
##                         brutal on-foot pillar crossing).
##   R4 COLLAPSED VEIN   — tight, broken; a heart-shrine buried in the rubble.
##   R5 BOSS CHAMBER     — the tomb they dug too deep: THE BURIED KING.

const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 3700, 14),        # ceiling
	Rect2(0, 0, 14, 288),         # left wall
	Rect2(3686, 0, 14, 288),      # right wall

	# R1 — SHAFT ENTRANCE x14..650
	Rect2(14, 252, 636, 36),

	# R2 — ORE FLOOR x710..1500 (spike gap 650..710)
	Rect2(710, 252, 790, 36),
	Rect2(900, 200, 80, 12),
	Rect2(1150, 196, 80, 12),

	# R3 — THE DEEP RAILS x1560..2500 (spike gap 1500..1560; rail pit 1680..2360)
	Rect2(1560, 252, 120, 36),    # boarding ledge
	Rect2(1800, 252, 40, 36),     # on-foot pillars (the hard way)
	Rect2(2000, 252, 40, 36),
	Rect2(2200, 252, 40, 36),
	Rect2(2360, 252, 140, 36),    # arrival ledge

	# R4 — COLLAPSED VEIN x2560..3100 (spike gap 2500..2560)
	Rect2(2560, 252, 540, 36),
	Rect2(2680, 184, 140, 40),    # a fallen slab — the ceiling came down here
	Rect2(2950, 196, 90, 12),

	# R5 — BOSS CHAMBER x3160..3686 (spike gap 3100..3160)
	Rect2(3160, 252, 526, 36),
]

const OBJECTS: Array[Rect2] = [
	Rect2(180, 222, 28, 30),
	Rect2(820, 222, 28, 30),
	Rect2(2600, 222, 28, 30),
]

const HAZARDS: Array[Rect2] = [
	Rect2(650, 262, 60, 26),
	Rect2(1500, 262, 60, 26),
	Rect2(1680, 262, 680, 26),    # the rail gauntlet pit
	Rect2(2500, 262, 60, 26),
	Rect2(3100, 262, 60, 26),
]

const MOSS_SPOTS := [Vector2(300, 244), Vector2(1000, 244), Vector2(2620, 244)]

## Ore vein streaks (cyan light nodes pair with these in the scene).
const VEINS := [Vector2(420, 250), Vector2(960, 250), Vector2(1290, 250),
	Vector2(2640, 250), Vector2(2900, 250), Vector2(3300, 250)]
## Timber supports.
const BEAMS := [120.0, 360.0, 600.0, 880.0, 1180.0, 1440.0, 2620.0, 2890.0, 3060.0]


func _init() -> void:
	ROCK_A = Color(0.15, 0.105, 0.08)
	ROCK_B = Color(0.21, 0.145, 0.105)
	STONE_DEEP = Color(0.06, 0.04, 0.032)
	SPECK_LIGHT = Color(0.35, 0.24, 0.16)
	SPECK_DARK = Color(0.07, 0.045, 0.035)
	RIM = Color(0.42, 0.28, 0.18)
	RIM_HI = Color(0.56, 0.38, 0.24)
	MOSS_D = Color(0.1, 0.42, 0.45)      # ore glow lichen
	MOSS_L = Color(0.35, 0.95, 0.9)
	ROOT = Color(0.09, 0.06, 0.045)
	STAL = Color(0.12, 0.085, 0.065)
	STAL_HI = Color(0.24, 0.165, 0.12)
	CRATE = Color(0.24, 0.17, 0.11)
	CRATE_DK = Color(0.14, 0.1, 0.065)
	CRATE_LIP = Color(0.36, 0.26, 0.16)


func solids() -> Array[Rect2]:
	return TERRAIN

func objects() -> Array[Rect2]:
	return OBJECTS

func hazards() -> Array[Rect2]:
	return HAZARDS

func moss_spots() -> Array:
	return MOSS_SPOTS


## Oppressively low mine roof, sagging between the timber sets.
func ceiling_y(x: float) -> float:
	return 62.0 + sin(x * 0.014 + 0.8) * 12.0 + sin(x * 0.05 + 2.0) * 5.0


func _process(_delta: float) -> void:
	queue_redraw()   # vein shimmer on the root item only


func _draw_extra() -> void:
	# Timber supports: posts + lintel, the bones of the old workings.
	for bx in BEAMS:
		var cy := ceiling_y(bx)
		var timber := Color(0.2, 0.14, 0.09)
		var timber_hi := Color(0.3, 0.21, 0.13)
		draw_rect(Rect2(bx - 26, cy - 4, 6, 252 - cy + 4), timber)
		draw_rect(Rect2(bx + 20, cy - 4, 6, 252 - cy + 4), timber)
		draw_rect(Rect2(bx - 30, cy - 8, 60, 7), timber_hi)
		draw_rect(Rect2(bx - 30, cy - 8, 60, 2), Color(0.38, 0.27, 0.17))
	# Ore veins: jagged cyan seams in the floor rock, shimmering.
	var t := Time.get_ticks_msec() / 1000.0
	for v in VEINS:
		var rng := RandomNumberGenerator.new()
		rng.seed = int(v.x)
		var p: Vector2 = v + Vector2(-14, 6)
		for i in 5:
			var q: Vector2 = p + Vector2(rng.randf_range(4.0, 9.0), rng.randf_range(-3.0, 3.0))
			var shimmer := 0.55 + 0.35 * sin(t * 2.0 + v.x * 0.1 + i)
			draw_line(p, q, Color(0.3, 0.9, 0.85, shimmer), 1.6)
			draw_line(p + Vector2(0, 1), q + Vector2(0, 1), Color(0.1, 0.4, 0.4, 0.5), 1.0)
			p = q
