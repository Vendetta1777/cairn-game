extends Node2D
## Cairn — black water (The Sunken Nave). Two kinds, one scene:
##   SHALLOW — wade sections: the water drags your run to a crawl while you're
##             in it (sets the player's speed_zone_mult).
##   DEEP    — the drowned dark: touching it is instant death (the full death
##             sequence; the Nave does not give bodies back).
## Drawn procedurally: a translucent body of water with a living sine surface
## and slow bubbles. Size is data (exported), so levels just place rects.

@export var size := Vector2(200, 26)
@export var deep: bool = false
@export var slow_mult: float = 0.42

var _t := 0.0
var _player: Node2D

@onready var _zone: Area2D = $Zone
@onready var _shape: CollisionShape2D = $Zone/Shape


func _ready() -> void:
	var rect := RectangleShape2D.new()
	rect.size = size
	_shape.shape = rect
	_shape.position = Vector2(size.x * 0.5, size.y * 0.5)
	_zone.area_entered.connect(_on_enter)
	_zone.area_exited.connect(_on_exit)


func _on_enter(area: Area2D) -> void:
	var b := area.get_parent()
	if not (b and b.is_in_group("player")):
		return
	if deep:
		# The black water takes you whole.
		var stats = b.get_node_or_null("Stats")
		if stats:
			stats.take_damage(999)
		return
	_player = b
	if "speed_zone_mult" in b:
		b.speed_zone_mult = slow_mult
	_splash(b.global_position)


func _on_exit(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b == _player:
		if "speed_zone_mult" in b:
			b.speed_zone_mult = 1.0
		_player = null


func _splash(at: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 10
	p.lifetime = 0.4
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 55.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0, 500)
	p.color = Color(0.4, 0.65, 0.7, 0.7)
	add_child(p)
	p.global_position = Vector2(at.x, global_position.y + 2.0)
	get_tree().create_timer(0.7).timeout.connect(p.queue_free)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var body := Color(0.02, 0.07, 0.09, 0.78) if deep else Color(0.05, 0.13, 0.15, 0.6)
	var glow := Color(0.3, 0.7, 0.7, 0.5) if not deep else Color(0.18, 0.4, 0.45, 0.45)
	draw_rect(Rect2(0, 3, size.x, size.y - 3), body)
	# Living surface: two overlapped sine lines.
	var pts := PackedVector2Array()
	var x := 0.0
	while x <= size.x:
		pts.append(Vector2(x, 2.0 + sin(_t * 1.8 + x * 0.06) * 1.6 + sin(_t * 3.1 + x * 0.11) * 0.8))
		x += 7.0
	draw_polyline(pts, glow, 1.2)
	# Slow bubbles in the body.
	for i in range(int(size.x / 70.0) + 1):
		var bx := fmod(i * 67.0 + sin(_t * 0.6 + i) * 8.0, size.x)
		var by := size.y - fmod(_t * (5.0 + (i % 3) * 3.0) + i * 13.0, size.y - 8.0)
		draw_circle(Vector2(bx, by + 2.0), 1.2, Color(0.5, 0.8, 0.8, 0.25))
