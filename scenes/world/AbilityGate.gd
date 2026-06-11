extends Node2D
## Cairn — an ABILITY GATE: a shimmering ward of old runes sealing a route until
## the player holds the required movement ability (the metroidvania "come back
## later" check). While locked it is solid; the moment the matching Ability
## Relic is claimed — even mid-level — the ward dissolves with a ripple. Routes
## are gated by these scenes (our levels are procedural, so this is the
## equivalent of tagging tiles with metadata).

@export var required_ability: String = "dash"
@export var gate_height: float = 70.0
@export var gate_width: float = 12.0

## Ward colour per ability, so gates read at a glance.
const TINTS := {
	"dash": Color(0.55, 0.9, 1.0),
	"wall_jump": Color(1.0, 0.62, 0.38),
	"double_jump": Color(0.55, 0.95, 0.7),
}

var _open := false
var _dissolve := 0.0     ## 0 sealed .. 1 gone
var _t := 0.0
var _blocker: StaticBody2D


func _ready() -> void:
	add_to_group("gate")   # map overlay pin
	if PlayerProgress.has_ability(required_ability):
		_open = true
		_dissolve = 1.0
	else:
		_make_blocker()
		PlayerProgress.ability_unlocked.connect(_on_ability)


func _make_blocker() -> void:
	_blocker = StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(gate_width, gate_height)
	cs.shape = shape
	cs.position = Vector2(0, -gate_height * 0.5)
	_blocker.add_child(cs)
	add_child(_blocker)


func _on_ability(id: String) -> void:
	if _open or id != required_ability:
		return
	_open = true
	if _blocker:
		_blocker.queue_free()
		_blocker = null


func _process(delta: float) -> void:
	_t += delta
	if _open and _dissolve < 1.0:
		_dissolve = minf(1.0, _dissolve + delta * 1.4)
	queue_redraw()


func _draw() -> void:
	var tint: Color = TINTS.get(required_ability, Color(0.7, 0.7, 0.9))
	var h := gate_height
	# Carved anchor stones top and bottom always remain — the ward's frame.
	for y in [0.0, -h]:
		draw_rect(Rect2(-7, y - 4, 14, 6), Color(0.18, 0.17, 0.23))
		draw_rect(Rect2(-5, y - 2, 10, 2), Color(0.3, 0.29, 0.38))
	if _dissolve >= 1.0:
		# Open: just a faint dead glyph on each anchor.
		for y in [-4.0, -h - 2.0]:
			draw_circle(Vector2(0, y), 1.6, Color(tint.r, tint.g, tint.b, 0.3))
		return
	var a := 1.0 - _dissolve
	var pulse := 0.55 + sin(_t * 2.6) * 0.25
	# The veil: layered translucent bands that waver.
	for i in range(3):
		var w := (3.0 - i) * 2.4
		var wob := sin(_t * 3.0 + i * 1.7) * 1.5
		draw_rect(Rect2(-w * 0.5 + wob, -h, w, h),
			Color(tint.r, tint.g, tint.b, (0.16 + 0.1 * i) * pulse * a))
	# Floating rune glyphs stacked up the veil.
	var n := int(h / 16.0)
	for i in range(n):
		var gy := -8.0 - i * 16.0 + sin(_t * 1.8 + i) * 2.0
		var ga := (0.7 + 0.3 * sin(_t * 2.2 + i * 2.0)) * a
		var gc := Color(tint.r, tint.g, tint.b, ga)
		draw_arc(Vector2(0, gy), 3.4, 0, TAU, 10, gc, 1.2)
		draw_line(Vector2(0, gy - 5), Vector2(0, gy + 5), gc, 1.0)
