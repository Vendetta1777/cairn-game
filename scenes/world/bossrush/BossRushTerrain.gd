extends "res://scenes/world/CaveTerrain.gd"
## Cairn — the Boss Rush hall: one wide flat arena, two side perches, nothing
## to hide behind. Neutral dark stone.

const TERRAIN: Array[Rect2] = [
	Rect2(0, 0, 960, 14),
	Rect2(0, 0, 14, 288),
	Rect2(946, 0, 14, 288),
	Rect2(14, 252, 932, 36),
	Rect2(120, 170, 80, 12),
	Rect2(760, 170, 80, 12),
]


func solids() -> Array[Rect2]:
	return TERRAIN


func ceiling_y(x: float) -> float:
	return 40.0 + sin(x * 0.02) * 8.0
