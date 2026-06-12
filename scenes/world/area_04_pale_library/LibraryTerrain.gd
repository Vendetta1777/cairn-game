extends "res://scenes/world/CaveTerrain.gd"
## Cairn — Area 4 "THE PALE LIBRARY": the kingdom's drowned archive. Ivory
## stone, candle-wax gold, shelves you can climb. Five rooms, left to right:
##   R1 ENTRY ATRIUM     — tall quiet shelves, the archivist's ghost.
##   R2 THE STACKS       — Archivist Shades + the urn-on-plate bridge puzzle.
##   R3 FLOODED INDEX    — shelf-top crossing over black archive water
##                         (grapple rings overhead for the return trip).
##   R4 FORBIDDEN WING   — a latch plate high on the shelves opens the door.
##   R5 BOSS CHAMBER     — the Pale Librarian's flooded reading hall.
## "Crates" here render as BOOKSHELVES (override below); their tops are paths.

const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 3600, 14),        # ceiling
	Rect2(0, 0, 14, 288),         # left wall
	Rect2(3586, 0, 14, 288),      # right wall

	# R1 — ENTRY ATRIUM x14..700
	Rect2(14, 252, 686, 36),
	Rect2(200, 200, 90, 14),
	Rect2(420, 170, 100, 14),

	# R2 — THE STACKS x760..1700 (spike gap 700..760; bridged pit 1160..1290)
	Rect2(760, 252, 400, 36),     # x760..1160
	Rect2(940, 170, 80, 12),      # board across the high shelves
	Rect2(1290, 252, 410, 36),    # x1290..1700

	# R3 — FLOODED INDEX x1760..2400 (spike gap 1700..1760)
	Rect2(1760, 252, 80, 36),     # entry lip
	Rect2(1880, 224, 60, 12),     # toppled shelf-tops over the deep
	Rect2(1990, 196, 60, 12),
	Rect2(2100, 222, 60, 12),
	Rect2(2180, 196, 50, 12),
	Rect2(2240, 252, 160, 36),    # landing x2240..2400

	# R4 — FORBIDDEN WING x2460..3000 (spike gap 2400..2460)
	Rect2(2460, 252, 540, 36),

	# R5 — BOSS CHAMBER x3060..3586 (spike gap 3000..3060)
	Rect2(3060, 252, 526, 36),    # flooded reading hall floor
	Rect2(3160, 170, 80, 12),     # the two mid platforms
	Rect2(3360, 170, 80, 12),
]

# Bookshelves (solid, climbable tops).
const OBJECTS: Array[Rect2] = [
	Rect2(120, 196, 30, 56),
	Rect2(550, 196, 30, 56),
	Rect2(820, 196, 30, 56),
	Rect2(1050, 196, 30, 56),
	Rect2(1380, 196, 30, 56),
	Rect2(2560, 196, 30, 56),     # the latch-plate shelf
	Rect2(2760, 196, 30, 56),
]

const HAZARDS: Array[Rect2] = [
	Rect2(700, 262, 60, 26),
	Rect2(1160, 262, 130, 26),    # the bridged pit
	Rect2(1700, 262, 60, 26),
	Rect2(2400, 262, 60, 26),
	Rect2(3000, 262, 60, 26),
]

const MOSS_SPOTS := [Vector2(240, 244), Vector2(1320, 244), Vector2(2500, 244)]

const CANDLES := [Vector2(160, 252), Vector2(640, 252), Vector2(1000, 252),
	Vector2(1620, 252), Vector2(2300, 252), Vector2(2920, 252), Vector2(3120, 252)]


func _init() -> void:
	ROCK_A = Color(0.3, 0.29, 0.26)
	ROCK_B = Color(0.38, 0.37, 0.33)
	STONE_DEEP = Color(0.12, 0.115, 0.1)
	SPECK_LIGHT = Color(0.5, 0.48, 0.42)
	SPECK_DARK = Color(0.14, 0.13, 0.11)
	RIM = Color(0.52, 0.5, 0.44)
	RIM_HI = Color(0.66, 0.63, 0.55)
	MOSS_D = Color(0.6, 0.45, 0.18)      # hardened wax runs
	MOSS_L = Color(0.95, 0.82, 0.45)
	ROOT = Color(0.18, 0.16, 0.13)
	STAL = Color(0.24, 0.23, 0.2)
	STAL_HI = Color(0.36, 0.35, 0.3)
	CRATE = Color(0.26, 0.2, 0.15)       # shelf wood
	CRATE_DK = Color(0.16, 0.12, 0.09)
	CRATE_LIP = Color(0.4, 0.32, 0.22)


func solids() -> Array[Rect2]:
	return TERRAIN

func objects() -> Array[Rect2]:
	return OBJECTS

func hazards() -> Array[Rect2]:
	return HAZARDS

func moss_spots() -> Array:
	return MOSS_SPOTS


## A vaulted reading-hall roof.
func ceiling_y(x: float) -> float:
	return 34.0 + sin(x * 0.008 + 0.6) * 8.0 + sin(x * 0.025 + 1.2) * 4.0


## Shelves instead of crates: frame, shelf boards, rows of book spines.
func _draw_crate_on(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, CRATE_DK)
	ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3), CRATE_LIP)
	ci.draw_rect(Rect2(r.position.x, r.position.y, 2.5, r.size.y), CRATE)
	ci.draw_rect(Rect2(r.end.x - 2.5, r.position.y, 2.5, r.size.y), CRATE)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(r.position.x)
	var rows := int((r.size.y - 6.0) / 14.0)
	for row in rows:
		var sy := r.position.y + 5.0 + row * 14.0
		ci.draw_rect(Rect2(r.position.x + 1, sy + 10.0, r.size.x - 2, 2), CRATE)
		var x := r.position.x + 4.0
		while x < r.end.x - 5.0:
			var w := rng.randf_range(2.0, 4.5)
			var h := rng.randf_range(7.0, 10.0)
			var spine: Color = [Color(0.5, 0.4, 0.3), Color(0.36, 0.42, 0.4), Color(0.55, 0.5, 0.4),
				Color(0.42, 0.32, 0.34), Color(0.3, 0.34, 0.42)][rng.randi() % 5]
			ci.draw_rect(Rect2(x, sy + 10.0 - h, w, h), spine)
			x += w + 1.0


func _process(_delta: float) -> void:
	queue_redraw()   # only the root item (candle flicker) — chunks are untouched


## Candle clusters along the halls (their lights live in the scene).
func _draw_extra() -> void:
	for c in CANDLES:
		_draw_candles(c)


func _draw_candles(at: Vector2) -> void:
	var wax := Color(0.88, 0.84, 0.72)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(at.x)
	draw_rect(Rect2(at.x - 12, at.y - 4, 24, 4), Color(0.2, 0.19, 0.17))
	for i in 3:
		var cx := at.x - 7.0 + i * 7.0
		var h := rng.randf_range(6.0, 14.0)
		draw_rect(Rect2(cx - 2, at.y - 4 - h, 4, h), wax)
		draw_rect(Rect2(cx - 2.6, at.y - 4 - h, 5.2, 2), wax.darkened(0.15))
		var flick := 0.7 + 0.3 * sin(Time.get_ticks_msec() / 90.0 + cx)
		draw_circle(Vector2(cx, at.y - 6 - h), 1.6 * flick, Color(1.0, 0.8, 0.4))
		draw_circle(Vector2(cx, at.y - 7 - h), 0.8, Color(1.0, 0.95, 0.8))
