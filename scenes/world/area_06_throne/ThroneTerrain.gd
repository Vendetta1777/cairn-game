extends "res://scenes/world/CaveTerrain.gd"
## Cairn — Area 6 "THE SOVEREIGN'S THRONE": the final descent. A colossal
## ruined throne hall, settled and split under centuries of stone, torches
## still burning on no one's orders, the crown still on the seat. No new
## horrors here — only the hardest of everything that came before, walking
## the same processional the court once walked. Four rooms:
##   R1 THE PROCESSIONAL — the long colonnade, memory echoes mid-procession.
##   R2 THE ANTECHAMBER  — the Last Knight's post.
##   R3 THE THRONE ROOM  — the seat of Cairn. Something pale waits (M12).
##   R4 THE PASSAGE BELOW— under the throne, where kings were carried out.

const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 3100, 14),        # ceiling
	Rect2(0, 0, 14, 288),         # left wall
	Rect2(3086, 0, 14, 288),      # right wall

	# R1 — THE PROCESSIONAL x14..900
	Rect2(14, 252, 886, 36),
	Rect2(300, 190, 90, 12),
	Rect2(600, 190, 90, 12),

	# R2 — THE ANTECHAMBER x960..1700 (collapse gap 900..960)
	Rect2(960, 252, 740, 36),
	Rect2(1200, 190, 90, 12),
	Rect2(1450, 170, 90, 12),

	# R3 — THE THRONE ROOM x1760..2700 (collapse gap 1700..1760)
	Rect2(1760, 252, 940, 36),
	Rect2(2150, 238, 220, 14),    # dais steps
	Rect2(2190, 226, 140, 12),

	# R4 — THE PASSAGE BELOW x2700..3086
	Rect2(2700, 252, 386, 36),
]

const OBJECTS: Array[Rect2] = []

const HAZARDS: Array[Rect2] = [
	Rect2(900, 262, 60, 26),
	Rect2(1700, 262, 60, 26),
]

const MOSS_SPOTS := [Vector2(400, 244), Vector2(1300, 244), Vector2(2800, 244)]

## Broken colonnade columns (drawn, with rubble at their feet).
const COLUMNS := [180.0, 460.0, 740.0, 1050.0, 1340.0, 1620.0, 1860.0, 2560.0, 2860.0]


func _init() -> void:
	ROCK_A = Color(0.115, 0.09, 0.135)
	ROCK_B = Color(0.16, 0.125, 0.18)
	STONE_DEEP = Color(0.045, 0.035, 0.055)
	SPECK_LIGHT = Color(0.28, 0.22, 0.32)
	SPECK_DARK = Color(0.05, 0.04, 0.06)
	RIM = Color(0.36, 0.28, 0.42)
	RIM_HI = Color(0.5, 0.4, 0.56)
	MOSS_D = Color(0.55, 0.42, 0.16)     # gold leaf, flaking
	MOSS_L = Color(0.9, 0.74, 0.38)
	ROOT = Color(0.08, 0.06, 0.09)
	STAL = Color(0.1, 0.08, 0.12)
	STAL_HI = Color(0.2, 0.16, 0.24)


func solids() -> Array[Rect2]:
	return TERRAIN

func objects() -> Array[Rect2]:
	return OBJECTS

func hazards() -> Array[Rect2]:
	return HAZARDS

func moss_spots() -> Array:
	return MOSS_SPOTS


## The grandest roof in the deep — high vaults, settled and cracked.
func ceiling_y(x: float) -> float:
	return 28.0 + sin(x * 0.006 + 0.4) * 7.0 + sin(x * 0.02 + 1.5) * 4.0


var _redraw_gate := false


func _process(_delta: float) -> void:
	# 30 Hz is plenty for flame flicker — halves the root redraw cost.
	_redraw_gate = not _redraw_gate
	if _redraw_gate:
		queue_redraw()   # brazier flames on the root item


func _draw_extra() -> void:
	for cx in COLUMNS:
		_draw_column(cx)
	_draw_throne(Vector2(2260, 226))


func _draw_column(cx: float) -> void:
	var cy := ceiling_y(cx)
	var col := Color(0.15, 0.12, 0.17)
	var col_hi := Color(0.22, 0.18, 0.25)
	var broken := fmod(cx, 3.0) < 1.5
	var h := (252.0 - cy) * (0.55 if broken else 1.0)
	draw_rect(Rect2(cx - 10, cy, 20, h), col)
	draw_rect(Rect2(cx - 10, cy, 4, h), col_hi)
	draw_rect(Rect2(cx - 13, cy, 26, 6), col_hi)
	if broken:
		# The fallen top lies in rubble at the base.
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 10, cy + h), Vector2(cx + 10, cy + h - 8), Vector2(cx + 6, cy + h)]), col_hi)
		draw_colored_polygon(PackedVector2Array([
			Vector2(cx - 18, 252), Vector2(cx - 6, 240), Vector2(cx + 8, 246), Vector2(cx + 16, 252)]), col)
	else:
		draw_rect(Rect2(cx - 13, 246, 26, 6), col_hi)


func _draw_throne(at: Vector2) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var stone := Color(0.18, 0.15, 0.2)
	var stone_hi := Color(0.26, 0.22, 0.28)
	var gold := Color(0.72, 0.6, 0.3)
	# High back, split by a great settling crack.
	draw_rect(Rect2(at.x - 26, at.y - 92, 52, 92), stone)
	draw_rect(Rect2(at.x - 26, at.y - 92, 8, 92), stone_hi)
	draw_colored_polygon(PackedVector2Array([
		at + Vector2(-26, -92), at + Vector2(0, -108), at + Vector2(26, -92)]), stone)
	var crack := Color(0.05, 0.04, 0.06)
	draw_line(at + Vector2(4, -104), at + Vector2(-2, -70), crack, 2.0)
	draw_line(at + Vector2(-2, -70), at + Vector2(6, -40), crack, 2.0)
	# Armrests + seat.
	for s in [-1.0, 1.0]:
		draw_rect(Rect2(at.x + s * 30 - 6, at.y - 34, 12, 34), stone_hi)
	draw_rect(Rect2(at.x - 24, at.y - 22, 48, 8), stone_hi)
	# The crown, still on the seat, glinting.
	var glint := 0.4 + 0.4 * maxf(0.0, sin(t * 0.7))
	draw_rect(Rect2(at.x - 9, at.y - 32, 18, 6), gold)
	for k in 3:
		draw_colored_polygon(PackedVector2Array([
			Vector2(at.x - 8 + k * 7, at.y - 32), Vector2(at.x - 5 + k * 7, at.y - 38), Vector2(at.x - 2 + k * 7, at.y - 32)]), gold)
	draw_circle(at + Vector2(-4, -35), 1.2, Color(1.0, 0.95, 0.8, glint))
	# Braziers flanking the dais, still burning.
	for s in [-1.0, 1.0]:
		var bx: float = at.x + s * 120.0
		draw_rect(Rect2(bx - 8, 236, 16, 16), stone)
		draw_rect(Rect2(bx - 10, 232, 20, 5), stone_hi)
		var fl := 0.7 + 0.3 * sin(t * 7.0 + bx)
		draw_circle(Vector2(bx, 228 - fl * 3.0), 3.5 * fl, Color(1.0, 0.65, 0.3, 0.9))
		draw_circle(Vector2(bx, 226 - fl * 4.0), 1.8, Color(1.0, 0.9, 0.6))
