extends AnimatableBody2D
## Cairn — a moving platform for the parkour sections. Oscillates between its
## start and start+travel on a smooth ease, carrying the player (AnimatableBody2D
## with sync_to_physics pushes bodies that stand on it). Drawn as a lit rune-slab
## so it reads as deliberately magical, not just a floating rock.

@export var size := Vector2(72, 16)
@export var travel := Vector2(0, -90)   ## offset it slides to and back
@export var period := 3.2               ## seconds for a full there-and-back
@export var phase := 0.0                ## 0..1 stagger so platforms aren't in sync

var _start := Vector2.ZERO
var _t := 0.0

@onready var _col: CollisionShape2D = $Col


func _ready() -> void:
	sync_to_physics = true
	_start = position
	_t = phase * period
	var shape := RectangleShape2D.new()
	shape.size = size
	_col.shape = shape


func _physics_process(delta: float) -> void:
	_t += delta
	var f := 0.5 - 0.5 * cos(_t / period * TAU)   # smooth 0..1..0
	position = _start + travel * f
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-size.x * 0.5, -size.y * 0.5, size.x, size.y)
	draw_rect(r, Color(0.15, 0.15, 0.21))
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3.0), Color(0.3, 0.34, 0.46))  # lit top
	draw_rect(Rect2(r.position.x, r.end.y - 3.0, r.size.x, 3.0), Color(0.07, 0.07, 0.1))
	# Glowing rune line along the top.
	var glow := 0.5 + 0.5 * sin(_t * 2.5)
	draw_line(Vector2(r.position.x + 6, r.position.y + 1.5), Vector2(r.end.x - 6, r.position.y + 1.5),
		Color(0.5, 0.72, 1.0, 0.4 + 0.4 * glow), 1.5)
	# Side bolts.
	draw_circle(Vector2(r.position.x + 5, 0), 1.6, Color(0.55, 0.7, 0.95, 0.8))
	draw_circle(Vector2(r.end.x - 5, 0), 1.6, Color(0.55, 0.7, 0.95, 0.8))
