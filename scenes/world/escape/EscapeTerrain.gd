extends "res://scenes/world/CaveTerrain.gd"
## Cairn — THE ESCAPE (Ending A): the deep is coming down. One long broken
## corridor up and out — hops, ledges, a final sprint — with the collapse
## chasing you the whole way. Touch the dust-wall and it takes you.

const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 4000, 14),
	Rect2(0, 0, 14, 288),
	Rect2(3986, 0, 14, 288),

	Rect2(14, 252, 586, 36),      # the start run
	Rect2(660, 230, 80, 14),      # hops over the first break
	Rect2(800, 252, 300, 36),
	Rect2(1160, 222, 70, 14),
	Rect2(1290, 196, 70, 14),
	Rect2(1420, 252, 280, 36),
	Rect2(1760, 226, 70, 14),     # stair of broken slabs
	Rect2(1890, 198, 70, 14),
	Rect2(2020, 226, 70, 14),
	Rect2(2150, 252, 350, 36),
	Rect2(2560, 230, 80, 14),
	Rect2(2700, 252, 300, 36),
	Rect2(3060, 222, 70, 14),
	Rect2(3190, 196, 70, 14),
	Rect2(3320, 252, 666, 36),    # the final sprint to the light
]

const HAZARDS: Array[Rect2] = [
	Rect2(600, 262, 60, 26),
	Rect2(1100, 262, 60, 26),
	Rect2(1700, 262, 60, 26),
	Rect2(2500, 262, 60, 26),
	Rect2(3000, 262, 60, 26),
]


func _init() -> void:
	ROCK_A = Color(0.13, 0.1, 0.09)
	ROCK_B = Color(0.18, 0.14, 0.12)
	STONE_DEEP = Color(0.05, 0.04, 0.035)
	RIM = Color(0.4, 0.32, 0.26)
	RIM_HI = Color(0.55, 0.45, 0.36)
	MOSS_D = Color(0.4, 0.3, 0.18)
	MOSS_L = Color(0.7, 0.55, 0.3)


func solids() -> Array[Rect2]:
	return TERRAIN

func hazards() -> Array[Rect2]:
	return HAZARDS


func ceiling_y(x: float) -> float:
	return 50.0 + sin(x * 0.02) * 14.0 + sin(x * 0.05 + 1.0) * 6.0
