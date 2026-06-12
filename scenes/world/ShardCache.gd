extends Node2D
## Cairn — a SHARD CACHE: a small hoard of crystal left where only the skilled
## (or the well-equipped) can reach — the payoff behind ability gates and
## backtracking. Walk over it once: the Shards are yours and the cache is spent
## forever (persisted by cache_id). Drawn procedurally as a crystal cluster.

@export var cache_id: String = "cache_1"
@export var shards: int = 6
@export var echoes: int = 0

var _t := 0.0
var _claimed := false

@onready var _zone: Area2D = $Zone
@onready var _light: PointLight2D = $Light


func _ready() -> void:
	add_to_group("cache")   # the Pale Lantern lights these up
	if PlayerProgress.has_flag("cache_%s" % cache_id):
		queue_free()
		return
	_zone.area_entered.connect(_on_enter)


func _process(delta: float) -> void:
	_t += delta
	_light.energy = 0.55 + sin(_t * 2.4) * 0.18
	queue_redraw()


func _on_enter(area: Area2D) -> void:
	if _claimed:
		return
	var body := area.get_parent()
	if not (body and body.is_in_group("player")):
		return
	_claimed = true
	PlayerProgress.set_flag("cache_%s" % cache_id)
	var stats = body.get_node_or_null("Stats")
	if stats:
		if shards > 0:
			stats.add_shards(shards)
		if echoes > 0:
			stats.add_echoes(echoes)
	SaveManager.autosave()
	AudioManager.play("chest", -8.0)
	_float_text()
	_zone.set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(_light, "energy", 2.2, 0.12)
	tw.tween_property(self, "modulate:a", 0.0, 0.6)
	tw.tween_callback(queue_free)


## "+N SHARDS" drifts up off the cache as it's claimed.
func _float_text() -> void:
	var label := Label.new()
	label.text = "+%d SHARDS" % shards if shards > 0 else "+%d ECHOES" % echoes
	label.add_theme_font_override("font", preload("res://assets/fonts/silkscreen.ttf"))
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.7, 0.95, 1.0))
	get_parent().add_child(label)
	label.global_position = global_position + Vector2(-22, -34)
	var tw := label.create_tween().set_parallel(true)
	tw.tween_property(label, "global_position", label.global_position + Vector2(0, -18), 0.9)
	tw.tween_property(label, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tw.chain().tween_callback(label.queue_free)


func _draw() -> void:
	if _claimed:
		return
	var glow := 0.6 + sin(_t * 2.4) * 0.3
	var body := Color(0.45, 0.85, 0.95)
	draw_circle(Vector2(0, -6), 13.0, Color(body.r, body.g, body.b, 0.08 * glow))
	# A cluster of three crystals of different heights.
	for c in [[Vector2(-6, 0), 8.0, -0.25], [Vector2(0, 0), 12.0, 0.0], [Vector2(6, 0), 7.0, 0.3]]:
		var base: Vector2 = c[0]
		var hgt: float = c[1]
		var lean: float = c[2]
		var tip := base + Vector2(lean * hgt, -hgt)
		draw_colored_polygon(PackedVector2Array([
			base + Vector2(-3, 0), tip, base + Vector2(3, 0)]), body)
		draw_line(base + Vector2(-1, -1), tip + Vector2(-0.5, 1), Color(1, 1, 1, 0.6 * glow), 1.0)
	draw_rect(Rect2(-10, 0, 20, 2), Color(0.1, 0.1, 0.14))
