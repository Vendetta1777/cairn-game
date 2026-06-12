extends Node2D
## Cairn — an ABILITY RELIC: a movement power waiting in the world (metroidvania
## unlock). Walk into it and the power is yours, permanently — a slow-mo flash,
## a title banner, an autosave. Drawn procedurally: a floating shard of the old
## kingdom's craft on a broken plinth, ringed by orbiting motes. If the save
## already holds this ability the relic is gone.

@export var ability_id: String = "dash"
@export var display_name: String = "THE SHADOWSTEP"
@export var subtitle: String = "DASH UNLOCKED — SHIFT"
@export var objective: String = ""        ## optional new objective line on claim
@export var tint := Color(0.55, 0.9, 1.0)

var _t := 0.0
var _claimed := false

@onready var _zone: Area2D = $Zone
@onready var _light: PointLight2D = $Light


func _ready() -> void:
	add_to_group("relic")   # map overlay pin
	if PlayerProgress.has_ability(ability_id):
		queue_free()
		return
	_light.color = tint
	_zone.area_entered.connect(_on_enter)


func _process(delta: float) -> void:
	_t += delta
	_light.energy = 0.9 + sin(_t * 2.1) * 0.25
	queue_redraw()


func _on_enter(area: Area2D) -> void:
	if _claimed:
		return
	var body := area.get_parent()
	if not (body and body.is_in_group("player")):
		return
	_claimed = true
	PlayerProgress.grant_ability(ability_id)
	SaveManager.autosave()
	AudioManager.play("relic", -4.0)
	GameManager.slowmo(0.2, 0.45)
	var banner := get_tree().get_first_node_in_group("location_title")
	if banner and banner.has_method("reveal"):
		banner.reveal(display_name, subtitle)
	if objective != "":
		QuestTracker.set_objective(objective)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.35)
	_burst()


## The relic flares, throws a ring of motes, and fades away.
func _burst() -> void:
	_zone.set_deferred("monitoring", false)
	var tw := create_tween()
	tw.tween_property(_light, "energy", 3.2, 0.15)
	tw.tween_property(_light, "energy", 0.0, 0.9)
	for i in range(12):
		var mote := Polygon2D.new()
		var s := 2.4
		mote.polygon = PackedVector2Array([Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0)])
		mote.color = Color(tint.r, tint.g, tint.b, 0.95)
		get_parent().add_child(mote)
		mote.global_position = global_position + Vector2(0, -30)
		var dir := Vector2.from_angle(TAU * i / 12.0)
		var mt := mote.create_tween().set_parallel(true)
		mt.tween_property(mote, "global_position", mote.global_position + dir * randf_range(34.0, 58.0), 0.6) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		mt.tween_property(mote, "modulate:a", 0.0, 0.6)
		mt.chain().tween_callback(mote.queue_free)
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.8)
	fade.tween_callback(queue_free)


func _draw() -> void:
	if _claimed:
		return
	# Broken plinth.
	draw_rect(Rect2(-11, -8, 22, 8), Color(0.15, 0.14, 0.19))
	draw_rect(Rect2(-13, -2, 26, 3), Color(0.09, 0.08, 0.12))
	draw_rect(Rect2(-8, -12, 6, 4), Color(0.12, 0.11, 0.16))
	# The relic: a floating, slowly turning shard (a diamond squashed by sin for
	# a fake 3D spin) above the plinth.
	var c := Vector2(0, -30 + sin(_t * 1.7) * 3.0)
	var spin := absf(sin(_t * 1.2))
	var w := 5.0 * (0.35 + 0.65 * spin)
	var h := 11.0
	var glow := 0.55 + sin(_t * 2.1) * 0.25
	draw_circle(c, 17.0, Color(tint.r, tint.g, tint.b, 0.10 * glow))
	draw_circle(c, 9.0, Color(tint.r, tint.g, tint.b, 0.16 * glow))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -h), c + Vector2(w, 0), c + Vector2(0, h), c + Vector2(-w, 0)]),
		Color(tint.r, tint.g, tint.b, 0.92))
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(0, -h * 0.6), c + Vector2(w * 0.45, 0), c + Vector2(0, h * 0.6), c + Vector2(-w * 0.45, 0)]),
		Color(1.0, 1.0, 1.0, 0.75))
	# Orbiting motes.
	for i in range(3):
		var a := _t * 1.6 + i * TAU / 3.0
		var p := c + Vector2(cos(a) * 15.0, sin(a) * 5.0)
		var behind := sin(a) < 0.0
		draw_circle(p, 1.5, Color(tint.r, tint.g, tint.b, 0.35 if behind else 0.9))
