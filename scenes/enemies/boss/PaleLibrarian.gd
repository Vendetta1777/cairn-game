extends EnemyBase
class_name PaleLibrarian
## Cairn — BOSS: THE PALE LIBRARIAN (end of Area 4). A colossal construct of
## compacted books and bound knowledge, animated by the forbidden script it was
## built to contain. Drawn entirely procedurally — a floating tower of tomes
## with burning glyph eyes and two orbiting "hand" volumes.
##
## PHASE 1 (100–60%): PAGE RAIN (3 arcing waves with dodge windows) ·
##   SUMMON (2 Archivist Shades) · TOME SLAM (drops, floor shockwaves).
## PHASE 2 (60–30%): a SPINNING PAGE SHIELD with one gap — damage only lands
##   through the gap · INK FLOOD rises from the floor (platform!).
## PHASE 3 (30–0%): shield breaks, RAGE (double speed) · FORBIDDEN SCRIPT
##   BEAMS sweep the arena. Death = staged collapse, then the GRAPPLE relic.

signal health_changed(cur: int, max: int)
signal engaged
signal defeated

enum { DORMANT, HOVER, PAGE_RAIN, SUMMON, SLAM_RISE, SLAM_DROP, FLOOD, BEAMS, RECOVER }

const PAGE := preload("res://scenes/enemies/archivist/BladedPage.tscn")
const SHADE := preload("res://scenes/enemies/archivist/ArchivistShade.tscn")
const WAVE := preload("res://scenes/enemies/boss/AshWave.tscn")
const INK := preload("res://scenes/enemies/boss/InkFlood.tscn")
const BEAM := preload("res://scenes/enemies/boss/ScriptBeam.tscn")
const RELIC := preload("res://scenes/world/AbilityRelic.tscn")

@export var boss_id: String = "pale_librarian"
@export var arena_left: float = 0.0
@export var arena_right: float = 600.0
@export var floor_y: float = 252.0
@export var home_y: float = 120.0

## BossBar reads this: white -> grey -> black through the phases.
var bar_phases := {
	"marks": [0.6, 0.3],
	"colors": [Color(0.92, 0.9, 0.86), Color(0.55, 0.54, 0.58), Color(0.16, 0.14, 0.2)],
}

var _state := DORMANT
var _t := 0.0
var _cooldown := 0.0
var _engaged := false
var _collapsing := false
var _bob := 0.0
var _wave_n := 0
var _shield_angle := 0.0
var _shield_gap := 0.0       ## gap centre angle
var _attack_idx := 0
var _home := Vector2.ZERO

@onready var _glow: PointLight2D = get_node_or_null("Glow")


func _ready() -> void:
	super._ready()
	stagger_resist = 0.05
	_home = global_position
	_bob = randf() * TAU


func _phase() -> int:
	var f := float(health) / float(max_health)
	if f <= 0.3:
		return 3
	elif f <= 0.6:
		return 2
	return 1


func _shield_active() -> bool:
	return _phase() == 2 and not is_dead()


func engage() -> void:
	if _engaged or is_dead():
		return
	_engaged = true
	_state = HOVER
	_cooldown = 1.2
	AudioManager.boss_music(true)
	engaged.emit()
	health_changed.emit(health, max_health)


func _process(delta: float) -> void:
	super._process(delta)
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	_shield_angle += delta * (2.2 if _phase() == 2 else 0.6)
	if _glow:
		_glow.energy = 0.7 + sin(Time.get_ticks_msec() / 220.0) * 0.2
	queue_redraw()


func _physics_process(delta: float) -> void:
	if is_dead() or _collapsing:
		velocity = Vector2.ZERO
		return
	if is_staggered():
		velocity = velocity.move_toward(Vector2.ZERO, 500.0 * delta)
		move_and_slide()
		return
	_bob += delta * 1.6
	var player := get_tree().get_first_node_in_group("player")
	var rage := 2.0 if _phase() == 3 else 1.0
	match _state:
		DORMANT:
			velocity = Vector2(0, (home_y + sin(_bob) * 6.0 - global_position.y) * 2.0)
		HOVER:
			_do_hover(player)
		PAGE_RAIN:
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
			_t -= delta * rage
			if _t <= 0.0:
				_fire_page_wave(player)
				_wave_n -= 1
				if _wave_n <= 0:
					_enter_recover()
				else:
					_t = 0.9   # the dodge window between waves
		SUMMON:
			velocity = Vector2.ZERO
			_t -= delta
			if _t <= 0.0:
				_do_summon()
		SLAM_RISE:
			velocity = Vector2(0, -120.0)
			_t -= delta * rage
			if _t <= 0.0:
				_state = SLAM_DROP
		SLAM_DROP:
			velocity = Vector2(0, 460.0)
			if global_position.y >= floor_y - 46.0:
				_slam_impact(player)
		FLOOD:
			velocity = Vector2(0, (home_y - 20.0 - global_position.y) * 2.0)
			_t -= delta
			if _t <= 0.0:
				_enter_recover()
		BEAMS:
			velocity = velocity.move_toward(Vector2.ZERO, 200.0 * delta)
			_t -= delta
			if _t <= 0.0:
				_enter_recover()
		RECOVER:
			_do_hover(player)
			_t -= delta * rage
			if _t <= 0.0:
				_state = HOVER
				_cooldown = 1.2 / rage
	move_and_slide()


func _do_hover(player: Node2D) -> void:
	var tx := (arena_left + arena_right) * 0.5
	if player:
		tx = clampf(player.global_position.x, arena_left + 80.0, arena_right - 80.0)
	velocity = Vector2(
		clampf((tx - global_position.x) * 1.6, -90.0, 90.0),
		(home_y + sin(_bob) * 9.0 - global_position.y) * 2.2)
	if _state == HOVER and _cooldown <= 0.0 and player and _engaged:
		_choose_attack()


func _choose_attack() -> void:
	var p := _phase()
	_attack_idx += 1
	match p:
		1:
			# Rotate the three phase-1 moves so each gets read and learned.
			match _attack_idx % 3:
				0: _enter_page_rain(3)
				1: _enter_summon()
				2: _enter_slam()
		2:
			match _attack_idx % 3:
				0: _enter_flood()
				1: _enter_page_rain(2)
				2: _enter_slam()
		3:
			match _attack_idx % 3:
				0: _enter_beams()
				1: _enter_page_rain(3)
				2: _enter_slam()


func _enter_page_rain(waves: int) -> void:
	_state = PAGE_RAIN
	_wave_n = waves
	_t = 0.5
	_tell(Color(1.0, 0.97, 0.85))


func _fire_page_wave(player: Node2D) -> void:
	AudioManager.play_at("swipe", global_position, -8.0)
	var aim_x := (arena_left + arena_right) * 0.5
	if player:
		aim_x = player.global_position.x
	for i in 5:
		var page := PAGE.instantiate()
		get_parent().add_child(page)
		var off := (i - 2) * 34.0
		page.global_position = global_position + Vector2(off * 0.4, -10)
		var target := Vector2(aim_x + off, floor_y)
		var dir: Vector2 = (target - page.global_position).normalized()
		page.launch(dir, 200.0, 1)


func _enter_summon() -> void:
	_state = SUMMON
	_t = 0.8
	_tell(Color(0.7, 0.75, 1.0))


func _do_summon() -> void:
	for off in [Vector2(-110, -30), Vector2(110, -30)]:
		var shade := SHADE.instantiate()
		shade.add_to_group("summoned_bat")   # cleared on fight reset, like bats
		get_parent().add_child(shade)
		shade.global_position = global_position + off
	AudioManager.play_at("aggro", global_position, -6.0)
	_enter_recover()


func _enter_slam() -> void:
	_state = SLAM_RISE
	_t = 0.7
	_tell(Color(1.0, 0.8, 0.6))


func _slam_impact(player: Node2D) -> void:
	AudioManager.play_at("boss_slam", global_position, 0.0)
	GameManager.hitstop(0.05)
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.75)
	for d in [-1.0, 1.0]:
		var wave := WAVE.instantiate()
		get_parent().add_child(wave)
		wave.global_position = Vector2(global_position.x + d * 24.0, floor_y)
		wave.launch(d, 2)
	if player and player.has_method("receive_attack") \
			and absf(player.global_position.x - global_position.x) < 60.0 \
			and player.global_position.y > global_position.y - 30.0:
		player.receive_attack(self, 2)
	_enter_recover()
	# Drift back up out of the floor.
	velocity = Vector2(0, -160)


func _enter_flood() -> void:
	_state = FLOOD
	_t = 5.2
	_tell(Color(0.3, 0.25, 0.5))
	var ink := INK.instantiate()
	get_parent().add_child(ink)
	ink.arena_left = arena_left
	ink.arena_right = arena_right
	ink.floor_y = floor_y
	ink.global_position = Vector2.ZERO


func _enter_beams() -> void:
	_state = BEAMS
	_t = 2.4
	_tell(Color(0.85, 0.8, 1.0))
	var player := get_tree().get_first_node_in_group("player")
	for i in 3:
		var beam := BEAM.instantiate()
		get_parent().add_child(beam)
		beam.global_position = global_position
		var ang := 0.0
		if player:
			ang = global_position.angle_to_point(player.global_position)
		beam.aim(ang + (i - 1) * 0.55)


func _enter_recover() -> void:
	_state = RECOVER
	_t = 1.6 if _phase() < 3 else 0.8


# --- damage: the page shield ---------------------------------------------------

func take_damage(amount: int, from: Vector2 = Vector2.ZERO) -> void:
	if is_dead() or _collapsing:
		return
	if not _engaged:
		engage()
	# Phase 2: the orbiting pages deflect anything that doesn't come through
	# the gap (the gap drifts with the shield's spin).
	if _shield_active() and from != Vector2.ZERO:
		var hit_angle := global_position.angle_to_point(from)
		var gap := wrapf(_shield_gap + _shield_angle, -PI, PI)
		var diff := absf(wrapf(hit_angle - gap, -PI, PI))
		if diff > 0.5:   # outside the gap cone (slightly tighter than the visual gap)
			AudioManager.play_at("parry", global_position, -10.0)
			_tell(Color(1, 1, 1))
			return
	var was := _phase()
	super.take_damage(amount, from)
	health_changed.emit(maxi(health, 0), max_health)
	if not is_dead() and _phase() != was:
		_on_phase_change(_phase())


func _on_phase_change(p: int) -> void:
	_tell(Color(1, 1, 1))
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.6)
	if p == 2:
		_shield_gap = randf() * TAU
	elif p == 3:
		# The shield shatters into a burst of dead pages.
		_burst_pages(14)
	_state = RECOVER
	_t = 0.9


func reset_fight() -> void:
	if is_dead():
		return
	health = max_health
	velocity = Vector2.ZERO
	global_position = _home
	_state = DORMANT
	_engaged = false
	_cooldown = 1.0
	_attack_idx = 0
	for n in get_tree().get_nodes_in_group("boss_projectile"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("summoned_bat"):
		n.queue_free()
	health_changed.emit(health, max_health)


func _die() -> void:
	if _collapsing:
		return
	_collapsing = true
	defeated.emit()
	health_changed.emit(0, max_health)
	QuestTracker.report_boss_defeated(boss_id)
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)
	for n in get_tree().get_nodes_in_group("boss_projectile"):
		n.queue_free()
	# The collapse: the construct loses its binding — books shed in bursts as it
	# sinks, then the whole mass lets go at once.
	var tw := create_tween()
	for i in 3:
		tw.tween_callback(func():
			_burst_pages(8)
			var cam := get_viewport().get_camera_2d()
			if cam and cam.has_method("add_trauma"):
				cam.add_trauma(0.35))
		tw.tween_property(self, "global_position:y", global_position.y + 24.0 * (i + 1), 0.5)
	tw.tween_callback(func():
		_burst_pages(22)
		GameManager.hitstop(0.1)
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method("add_trauma"):
			cam.add_trauma(0.9)
		# The grapple hook waits in the wreckage.
		var relic := RELIC.instantiate()
		relic.ability_id = "grapple"
		relic.display_name = "THE RIGGER'S HOOK"
		relic.subtitle = "GRAPPLE UNLOCKED — F at iron rings"
		relic.objective = "Grapple the rings — press F in range"
		relic.tint = Color(0.95, 0.85, 0.5)
		get_parent().add_child(relic)
		relic.global_position = Vector2(global_position.x, floor_y)
		super._die())


func _burst_pages(n: int) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = n
	p.lifetime = 1.0
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 170.0
	p.gravity = Vector2(0, 200)
	p.scale_amount_min = 1.4
	p.scale_amount_max = 2.6
	p.color = Color(0.88, 0.85, 0.75)
	get_parent().add_child(p)
	p.global_position = global_position
	get_tree().create_timer(1.4).timeout.connect(p.queue_free)


func _tell(c: Color) -> void:
	if _glow:
		_glow.color = c
		var tw := create_tween()
		tw.tween_property(_glow, "energy", 1.8, 0.12)
		tw.tween_property(_glow, "energy", 0.8, 0.4)


# --- the construct, drawn -------------------------------------------------------

func _draw() -> void:
	var f := float(health) / float(max_health) if max_health > 0 else 1.0
	var sway := sin(_bob) * 2.0
	# Tome palette: pale leathers and one forbidden black volume.
	var tomes := [Color(0.62, 0.58, 0.5), Color(0.5, 0.47, 0.42), Color(0.68, 0.64, 0.55), Color(0.42, 0.4, 0.37)]
	# The torso: a swaying stack of huge books.
	var y := 30.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in 7:
		var w := 52.0 - absf(i - 3) * 6.0
		var h := 11.0
		var off := sin(_bob * 0.9 + i * 0.8) * (2.0 + i * 0.4) + sway
		var col: Color = tomes[i % tomes.size()]
		if i == 4:
			col = Color(0.12, 0.1, 0.16)   # the forbidden volume
		draw_rect(Rect2(-w * 0.5 + off, y - h, w, h - 1.0), col)
		draw_rect(Rect2(-w * 0.5 + off, y - h, 4.0, h - 1.0), col.darkened(0.35))
		draw_rect(Rect2(-w * 0.5 + off, y - h, w, 1.5), col.lightened(0.2))
		y -= h
	# The cowl: an open tome as a head, glyph-light burning between covers.
	var head_y := y - 6.0 + sway * 0.5
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22, head_y), Vector2(0, head_y - 14), Vector2(22, head_y),
		Vector2(0, head_y + 4)]), Color(0.75, 0.72, 0.62))
	var eye := Color(0.95, 0.92, 1.0, 0.85 + sin(_bob * 3.0) * 0.15)
	draw_circle(Vector2(-6, head_y - 3), 2.2, eye)
	draw_circle(Vector2(6, head_y - 3), 2.2, eye)
	# Orbiting hand-volumes.
	for s in [-1.0, 1.0]:
		var a: float = _bob * 1.2 * s + (0.0 if s > 0 else PI)
		var hp := Vector2(cos(a) * 58.0, 6.0 + sin(a) * 12.0)
		draw_rect(Rect2(hp.x - 9, hp.y - 6, 18, 12), tomes[1])
		draw_rect(Rect2(hp.x - 9, hp.y - 6, 18, 2), tomes[2])
	# Phase 2: the page shield ring with its gap.
	if _shield_active():
		for i in 14:
			var ang := TAU * i / 14.0 + _shield_angle
			var gap := wrapf(_shield_gap + _shield_angle, -PI, PI)
			if absf(wrapf(ang - gap, -PI, PI)) < 0.55:
				continue   # the gap
			var pp := Vector2.from_angle(ang) * 74.0
			var pd := Vector2.from_angle(ang + PI * 0.5)
			draw_line(pp - pd * 6.0, pp + pd * 6.0, Color(0.9, 0.87, 0.78, 0.9), 3.0)
			draw_line(pp - pd * 6.0, pp + pd * 6.0, Color(0.6, 0.56, 0.5, 0.8), 1.0)
	# Low health: the binding glow dies down.
	if f < 0.3:
		draw_circle(Vector2(0, 0), 40.0, Color(0.4, 0.3, 0.6, 0.05 + sin(_bob * 4.0) * 0.03))
