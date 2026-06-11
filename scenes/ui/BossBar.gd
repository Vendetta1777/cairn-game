extends Control
## Cairn — boss health bar. Hidden until a boss engages, then slides down at the
## top-centre with the boss name. Two layers: the live fill and a slower "trail"
## that drains a beat behind so big hits read as a satisfying chunk of loss.

@onready var _name: Label = $Name

const BAR_W := 360.0
const BAR_H := 12.0
const BAR_TOP := 22.0

var _ratio := 1.0       ## live target (0..1)
var _shown := 1.0       ## animated fill
var _trail := 1.0       ## lagging ghost
var _active := false
var _rest_y := 0.0


func _ready() -> void:
	add_to_group("boss_bar")
	_rest_y = position.y
	modulate.a = 0.0
	position.y = _rest_y - 40.0


## Wire this bar to a boss node exposing health_changed / engaged / defeated.
func bind(boss: Node, display_name: String) -> void:
	_name.text = display_name
	if boss.has_signal("health_changed"):
		boss.health_changed.connect(_on_health)
	if boss.has_signal("engaged"):
		boss.engaged.connect(_show)
	if boss.has_signal("defeated"):
		boss.defeated.connect(_on_defeated)


func _show() -> void:
	if _active:
		return
	_active = true
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.5)
	tw.tween_property(self, "position:y", _rest_y, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_health(cur: int, mx: int) -> void:
	_ratio = clampf(float(cur) / float(maxi(mx, 1)), 0.0, 1.0)
	if not _active:
		_show()


func _on_defeated() -> void:
	_ratio = 0.0
	var tw := create_tween()
	tw.tween_interval(0.9)
	tw.tween_property(self, "modulate:a", 0.0, 0.7)
	tw.tween_callback(func() -> void: _active = false)


func _process(delta: float) -> void:
	_shown = move_toward(_shown, _ratio, delta * 2.6)
	if _trail > _shown:
		_trail = move_toward(_trail, _shown, delta * 0.7)
	else:
		_trail = _shown
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var x0 := (w - BAR_W) * 0.5
	var top := BAR_TOP
	var frame := Rect2(x0 - 3, top - 3, BAR_W + 6, BAR_H + 6)
	# Backplate + frame.
	draw_rect(frame, Color(0.03, 0.02, 0.05, 0.8))
	draw_rect(frame, Color(0.45, 0.38, 0.5, 0.85), false, 1.5)
	var inner := Rect2(x0, top, BAR_W, BAR_H)
	draw_rect(inner, Color(0.1, 0.07, 0.1, 0.9))
	# Lagging damage trail (pale).
	if _trail > 0.0:
		draw_rect(Rect2(x0, top, BAR_W * _trail, BAR_H), Color(0.85, 0.78, 0.82, 0.55))
	# Live fill — violet to crimson as the boss weakens.
	if _shown > 0.0:
		var fill_col := Color(0.62, 0.2, 0.32).lerp(Color(0.78, 0.16, 0.18), 1.0 - _shown)
		draw_rect(Rect2(x0, top, BAR_W * _shown, BAR_H), fill_col)
		# Top sheen.
		draw_rect(Rect2(x0, top, BAR_W * _shown, BAR_H * 0.4), Color(1, 1, 1, 0.12))
	# Notch ticks every 1/4.
	for i in range(1, 4):
		var nx := x0 + BAR_W * (i / 4.0)
		draw_line(Vector2(nx, top), Vector2(nx, top + BAR_H), Color(0.03, 0.02, 0.05, 0.7), 1.0)
