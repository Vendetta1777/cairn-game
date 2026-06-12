extends Node2D
## Cairn — a PRESSURE PLATE (The Pale Library): an old counterweighted floor
## stone. While weight rests on it (the player, or a carried urn set down on
## it) every linked node with `set_active(bool)` is driven — bridges extend,
## doors part. `latch` plates stay pressed forever once triggered; momentary
## plates release when the weight leaves (timed puzzles).

@export var targets: Array[NodePath] = []
@export var latch: bool = false

var _pressed := false
var _bodies := 0
var _t := 0.0

@onready var _zone: Area2D = $Zone


func _ready() -> void:
	# Areas only: the player's hurtbox and the urn's WeightTag both live on
	# layer 2. (Bodies would catch the floor itself.)
	_zone.area_entered.connect(_on_enter)
	_zone.area_exited.connect(_on_exit)


func _on_enter(area: Area2D) -> void:
	var b := area.get_parent()
	if b and (b.is_in_group("player") or b.is_in_group("weight")):
		_change(1)


func _on_exit(area: Area2D) -> void:
	var b := area.get_parent()
	if b and (b.is_in_group("player") or b.is_in_group("weight")):
		_change(-1)


func _change(delta: int) -> void:
	_bodies = maxi(0, _bodies + delta)
	var want := _bodies > 0
	if latch and _pressed:
		return
	if want == _pressed:
		return
	_pressed = want
	AudioManager.play_at("checkpoint" if _pressed else "enemy_hurt", global_position, -14.0)
	for path in targets:
		var n := get_node_or_null(path)
		if n and n.has_method("set_active"):
			n.set_active(_pressed)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var stone := Color(0.32, 0.31, 0.28)
	var stone_d := Color(0.18, 0.17, 0.15)
	var rune := Color(0.85, 0.8, 0.6)
	var sink := 3.0 if _pressed else 0.0
	# Housing slot.
	draw_rect(Rect2(-16, -2, 32, 5), stone_d)
	# The plate itself, sunk when pressed.
	draw_rect(Rect2(-13, -6 + sink, 26, 5), stone)
	draw_rect(Rect2(-13, -6 + sink, 26, 1.5), Color(0.45, 0.44, 0.4))
	# A faint rune that lights while pressed.
	var a := (0.8 if _pressed else 0.2) + sin(_t * 3.0) * 0.1
	draw_circle(Vector2(0, -3.5 + sink), 1.8, Color(rune.r, rune.g, rune.b, a))
