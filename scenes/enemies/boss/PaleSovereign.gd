extends EnemyBase
class_name PaleSovereign
## Cairn — THE FINAL BOSS: THE PALE SOVEREIGN OF CAIRN. What remains of the
## ancient king — an entity of pure grief and stone, keeping a promise that
## outlived its maker. Three forms:
##   PHASE 1 — THE KING (100–66%): a master swordsman. Three-cut combo,
##     overhead slam, dash thrust, rising slash — all telegraphed, all
##     PARRIABLE (a parry staggers him a full 2s). Summons crawlers.
##   PHASE 2 — THE SOVEREIGN (66–33%): the armour shatters; he goes spectral
##     (translucent), gains TELEPORT CUTS and the horizontal SOUL BEAM; the
##     floor tiles begin to CRUMBLE into open gaps.
##   PHASE 3 — THE CAIRN (33–0%): he merges with the throne — a colossus of
##     stacked stone fills the hall. Stone FISTS slam down, SOUL SHOCKWAVE
##     rings sweep the floor, stone shards rain. The floor is mostly gone.
## The killing blow: slow-motion, a white flash, then the ending sequence.

signal health_changed(cur: int, max: int)
signal engaged
signal defeated

enum { DORMANT, INTRO, STANCE, COMBO_TELL, COMBO, SLAM_TELL, SLAM, THRUST_TELL, THRUST,
	RISING_TELL, RISING, SUMMON, BLINK, BEAM_TELL, BEAM, ASCEND, FIST_TELL, FIST,
	RING, SHARDS, RECOVER }

const CRAWLER := preload("res://scenes/enemies/crawler/Crawler.tscn")
const BEAM_SCN := preload("res://scenes/enemies/boss/ScriptBeam.tscn")
const RING_SCN := preload("res://scenes/enemies/boss/ShockRing.tscn")
const GAP := preload("res://scenes/enemies/boss/CrumbleGap.tscn")
const SHARD := preload("res://scenes/enemies/boss/EmberFall.tscn")
const SLASH := preload("res://scenes/fx/Slash.tscn")

@export var boss_id: String = "pale_sovereign"
@export var walk_speed: float = 70.0
@export var contact_damage: int = 2
@export var gravity: float = 1100.0
@export var arena_left: float = 1790.0
@export var arena_right: float = 2670.0
@export var floor_y: float = 252.0
@export var throne_x: float = 2260.0

var bar_phases := {
	"marks": [0.66, 0.33],
	"colors": [Color(0.8, 0.68, 0.35), Color(0.6, 0.75, 0.95), Color(0.45, 0.42, 0.5)],
}

var _state := DORMANT
var _t := 0.0
var _dir := -1.0
var _cooldown := 0.0
var _engaged := false
var _dying := false
var _combo_step := 0
var _attack_idx := 0
var _gaps_spawned := 0
var _summoned := false
var _home := Vector2.ZERO

@onready var _aura: PointLight2D = get_node_or_null("Aura")


func _ready() -> void:
	super._ready()
	stagger_resist = 0.1
	_home = global_position
	if _sprite:
		_sprite.modulate = Color(0.85, 0.82, 0.95)


func _phase() -> int:
	var f := float(health) / float(max_health)
	if f <= 0.33:
		return 3
	elif f <= 0.66:
		return 2
	return 1


func engage() -> void:
	if _engaged or is_dead():
		return
	_engaged = true
	GameManager.letterbox(true)
	AudioManager.boss_music(true)
	_state = INTRO
	_t = 2.2
	var banner := get_tree().get_first_node_in_group("location_title")
	if banner and banner.has_method("reveal"):
		banner.reveal("THE PALE SOVEREIGN", "WHAT REMAINS OF A PROMISE")


func _begin() -> void:
	GameManager.letterbox(false)
	_state = STANCE
	_cooldown = 1.0
	engaged.emit()
	health_changed.emit(health, max_health)


func _process(delta: float) -> void:
	super._process(delta)
	if _cooldown > 0.0:
		_cooldown = maxf(0.0, _cooldown - delta)
	if _aura:
		var p := _phase()
		_aura.color = [Color(0.95, 0.85, 0.5), Color(0.6, 0.8, 1.0), Color(0.7, 0.68, 0.8)][p - 1]
		_aura.energy = 0.6 + 0.25 * sin(Time.get_ticks_msec() / 240.0)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if is_dead() or _dying:
		velocity = Vector2.ZERO
		return
	if _phase() < 3 and not is_on_floor():
		velocity.y += gravity * delta
	elif _phase() == 3:
		velocity = Vector2.ZERO   # the colossus does not walk
	if is_staggered():
		velocity.x = move_toward(velocity.x, 0.0, 500.0 * delta)
		move_and_slide()
		return

	var player := get_tree().get_first_node_in_group("player")
	_t -= delta
	match _state:
		DORMANT:
			velocity.x = 0.0
			if player and absf(player.global_position.x - global_position.x) < 220.0:
				engage()
		INTRO:
			velocity.x = 0.0
			if _t <= 0.0:
				_begin()
		STANCE:
			_do_stance(player)
		COMBO_TELL, SLAM_TELL, THRUST_TELL, RISING_TELL, BEAM_TELL, FIST_TELL:
			velocity.x = 0.0
			if player and _state != THRUST_TELL:
				_dir = signf(player.global_position.x - global_position.x)
			if _t <= 0.0:
				_resolve_tell(player)
		COMBO:
			velocity.x = _dir * 130.0
			if _t <= 0.0:
				_sword_hit(player, 1)
				_combo_step += 1
				if _combo_step >= 3:
					_enter_recover()
				else:
					_state = COMBO_TELL
					_t = 0.34
		SLAM:
			velocity.x = 0.0
			if _t <= 0.0:
				_sword_hit(player, 2)
				VFXManager.dust(global_position + Vector2(_dir * 20, 10), 0.8)
				_camera_shake(0.5)
				_enter_recover()
		THRUST:
			velocity.x = _dir * 360.0
			_sword_hit_passive(player, 2)
			if _t <= 0.0 or is_on_wall():
				_enter_recover()
		RISING:
			velocity = Vector2(_dir * 60.0, -240.0)
			_sword_hit_passive(player, 1)
			if _t <= 0.0:
				_enter_recover()
		SUMMON:
			velocity.x = 0.0
			if _t <= 0.0:
				_do_summon()
		BLINK:
			velocity = Vector2.ZERO
			if _t <= 0.0:
				_blink_strike(player)
		BEAM:
			velocity.x = 0.0
			if _t <= 0.0:
				_enter_recover()
		ASCEND:
			# Rising into the throne for phase 3.
			global_position = global_position.lerp(Vector2(throne_x, floor_y - 60.0), 3.0 * delta)
			if _t <= 0.0:
				_state = RECOVER
				_t = 0.8
		FIST:
			velocity = Vector2.ZERO
			if _t <= 0.0:
				_fist_impact(player)
		RING:
			if _t <= 0.0:
				_enter_recover()
		SHARDS:
			if _t <= 0.0:
				_enter_recover()
		RECOVER:
			if _phase() < 3:
				velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
			if _t <= 0.0:
				_state = STANCE
				_cooldown = [0.0, 1.0, 0.7, 0.5][_phase()]
	if _sprite and _phase() < 3:
		_sprite.flip_h = _dir < 0.0
	move_and_slide()


func _do_stance(player: Node2D) -> void:
	if player == null:
		velocity.x = 0.0
		return
	if _phase() == 3:
		if _cooldown <= 0.0:
			_choose_attack_p3(player)
		return
	_dir = signf(player.global_position.x - global_position.x)
	var dist := absf(player.global_position.x - global_position.x)
	velocity.x = _dir * walk_speed * (1.3 if _phase() == 2 else 1.0) if dist > 60.0 else 0.0
	if _cooldown <= 0.0 and dist < 240.0:
		if _phase() == 1:
			_choose_attack_p1(dist)
		else:
			_choose_attack_p2(player, dist)


func _choose_attack_p1(dist: float) -> void:
	_attack_idx += 1
	if not _summoned and float(health) / float(max_health) < 0.85:
		_summoned = true
		_state = SUMMON
		_t = 0.7
		_tell(Color(0.9, 0.8, 1.0))
		return
	if dist > 150.0:
		_enter(THRUST_TELL, 0.6, Color(1.0, 0.9, 0.6))
	else:
		match _attack_idx % 3:
			0: _enter(COMBO_TELL, 0.55, Color(1.0, 0.85, 0.55))
			1: _enter(SLAM_TELL, 0.8, Color(1.0, 0.7, 0.4))
			2: _enter(RISING_TELL, 0.5, Color(0.9, 0.95, 1.0))


func _choose_attack_p2(player: Node2D, dist: float) -> void:
	_attack_idx += 1
	match _attack_idx % 4:
		0:
			_state = BLINK
			_t = 0.45
			if _sprite:
				create_tween().tween_property(_sprite, "modulate:a", 0.1, 0.3)
		1: _enter(BEAM_TELL, 0.7, Color(0.6, 0.8, 1.0))
		2: _enter(COMBO_TELL, 0.45, Color(1.0, 0.85, 0.55))
		3:
			_crumble_floor(player)
			_enter_recover()


func _choose_attack_p3(player: Node2D) -> void:
	_attack_idx += 1
	match _attack_idx % 3:
		0: _enter(FIST_TELL, 0.9, Color(0.8, 0.78, 0.9))
		1:
			_state = RING
			_t = 0.4
			var ring := RING_SCN.instantiate()
			get_parent().add_child(ring)
			ring.global_position = Vector2(throne_x, floor_y - 10.0)
		2:
			_state = SHARDS
			_t = 1.6
			_tell(Color(0.7, 0.68, 0.8))
			for i in 6:
				var sh := SHARD.instantiate()
				get_parent().add_child(sh)
				sh.global_position = Vector2(randf_range(arena_left + 30, arena_right - 30), 40.0)
				sh.setup(1, floor_y)


func _enter(s: int, t: float, tell: Color) -> void:
	_state = s
	_t = t
	if s == COMBO_TELL:
		_combo_step = 0
	_tell(tell)


func _resolve_tell(player: Node2D) -> void:
	match _state:
		COMBO_TELL:
			_state = COMBO
			_t = 0.16
			_slash_vfx()
		SLAM_TELL:
			_state = SLAM
			_t = 0.2
			_slash_vfx(true)
		THRUST_TELL:
			_state = THRUST
			_t = 0.5
		RISING_TELL:
			_state = RISING
			_t = 0.5
			_slash_vfx()
		BEAM_TELL:
			_state = BEAM
			_t = 0.8
			var beam := BEAM_SCN.instantiate()
			get_parent().add_child(beam)
			beam.global_position = global_position + Vector2(0, -14)
			beam.length = 420.0
			beam.sweep_radians = 0.12
			beam.aim(0.0 if _dir > 0 else PI)
		FIST_TELL:
			_state = FIST
			_t = 0.25
			if player:
				_fist_x = clampf(player.global_position.x, arena_left + 30, arena_right - 30)


var _fist_x := 0.0


func _fist_impact(player: Node2D) -> void:
	AudioManager.play_at("boss_slam", Vector2(_fist_x, floor_y), 0.0)
	GameManager.hitstop(0.05)
	_camera_shake(0.8)
	VFXManager.dust(Vector2(_fist_x, floor_y), 1.0)
	if player and absf(player.global_position.x - _fist_x) < 46.0 \
			and player.global_position.y > floor_y - 90.0 \
			and player.has_method("receive_attack"):
		player.receive_attack(self, 2)
	_enter_recover()


## Sword hits route through receive_attack so the player can PARRY them —
## a successful parry calls our stagger() (2s via stagger duration below).
func _sword_hit(player: Node2D, dmg: int) -> void:
	_slash_vfx()
	AudioManager.play_at("swipe", global_position, -6.0)
	if player and absf(player.global_position.x - global_position.x) < 52.0 \
			and absf(player.global_position.y - global_position.y) < 50.0 \
			and player.has_method("receive_attack"):
		player.receive_attack(self, dmg)


func _sword_hit_passive(player: Node2D, dmg: int) -> void:
	if player and absf(player.global_position.x - global_position.x) < 30.0 \
			and absf(player.global_position.y - global_position.y) < 44.0 \
			and player.has_method("receive_attack"):
		player.receive_attack(self, dmg)


## Parried: the King reels a full 2 seconds — the skill reward.
func stagger(from_position: Vector2, force: float = 150.0, duration: float = 0.7) -> void:
	super.stagger(from_position, force, 2.0 if _phase() < 3 else 0.8)
	_tell(Color(1, 1, 1))


func _slash_vfx(big := false) -> void:
	var fx: AnimatedSprite2D = SLASH.instantiate()
	get_parent().add_child(fx)
	fx.global_position = global_position + Vector2(_dir * 26.0, -10.0)
	fx.flip_h = _dir < 0
	fx.scale *= 1.5 if big else 1.2
	fx.modulate = Color(0.9, 0.85, 1.0)


func _do_summon() -> void:
	for off in [-90.0, 90.0]:
		var c := CRAWLER.instantiate()
		c.add_to_group("summoned_bat")
		get_parent().add_child(c)
		c.global_position = global_position + Vector2(off, -10)
	AudioManager.play_at("aggro", global_position, -6.0)
	_enter_recover()


func _blink_strike(player: Node2D) -> void:
	if player:
		global_position = player.global_position + Vector2(-_dir * 40.0, -4.0)
		_dir = signf(player.global_position.x - global_position.x)
	if _sprite:
		create_tween().tween_property(_sprite, "modulate:a", 0.62, 0.15)
	VFXManager.dust(global_position, 0.4)
	_state = COMBO_TELL
	_combo_step = 1   # a single spectral cut
	_t = 0.3


func _crumble_floor(player: Node2D) -> void:
	if _gaps_spawned >= 5:
		return
	_gaps_spawned += 1
	var gap := GAP.instantiate()
	get_parent().add_child(gap)
	var gx := randf_range(arena_left + 80, arena_right - 80)
	if player and randf() < 0.5:
		gx = clampf(player.global_position.x, arena_left + 80, arena_right - 80)
	gap.global_position = Vector2(gx, floor_y)
	_camera_shake(0.4)


func _enter_recover() -> void:
	_state = RECOVER
	_t = [0.0, 1.4, 1.0, 0.9][_phase()]
	if _sprite and _phase() == 2:
		create_tween().tween_property(_sprite, "modulate:a", 0.62, 0.2)


# --- phases / damage / death -----------------------------------------------------

func take_damage(amount: int, from: Vector2 = Vector2.ZERO) -> void:
	if is_dead() or _dying:
		return
	if not _engaged:
		engage()
		return   # the intro plays before the fight counts
	var was := _phase()
	super.take_damage(amount, from)
	health_changed.emit(maxi(health, 0), max_health)
	if not is_dead() and _phase() != was:
		_phase_shift(_phase())


func _phase_shift(p: int) -> void:
	_camera_shake(0.8)
	GameManager.hitstop(0.08)
	_tell(Color(1, 1, 1))
	if p == 2:
		# The armour shatters — he goes spectral.
		VFXManager.death_burst(global_position, Color(0.8, 0.75, 0.6))
		if _sprite:
			create_tween().tween_property(_sprite, "modulate", Color(0.7, 0.85, 1.0, 0.62), 0.6)
		var banner := get_tree().get_first_node_in_group("location_title")
		if banner and banner.has_method("reveal"):
			banner.reveal("THE ARMOUR FALLS", "THE SOVEREIGN REMAINS")
	elif p == 3:
		# He goes to the throne and the throne RISES.
		if _sprite:
			create_tween().tween_property(_sprite, "modulate:a", 0.0, 0.8)
		for i in 3:
			_crumble_floor(null)
		var banner := get_tree().get_first_node_in_group("location_title")
		if banner and banner.has_method("reveal"):
			banner.reveal("THE CAIRN ITSELF", "GRIEF, CROWNED")
		_state = ASCEND
		_t = 1.6
		return
	_state = RECOVER
	_t = 1.0


func reset_fight() -> void:
	if is_dead():
		return
	health = max_health
	velocity = Vector2.ZERO
	global_position = _home
	_state = DORMANT
	_engaged = false
	_summoned = false
	_gaps_spawned = 0
	_attack_idx = 0
	_cooldown = 1.0
	if _sprite:
		_sprite.modulate = Color(0.85, 0.82, 0.95)
	for n in get_tree().get_nodes_in_group("boss_projectile"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("summoned_bat"):
		n.queue_free()
	health_changed.emit(health, max_health)


func _die() -> void:
	if _dying:
		return
	_dying = true
	defeated.emit()
	health_changed.emit(0, max_health)
	QuestTracker.report_boss_defeated(boss_id)
	if _hurtbox:
		_hurtbox.set_deferred("monitorable", false)
	for n in get_tree().get_nodes_in_group("boss_projectile"):
		n.queue_free()
	for n in get_tree().get_nodes_in_group("summoned_bat"):
		n.queue_free()
	# THE killing blow: slow-motion... massive impact... white.
	GameManager.slowmo(0.12, 1.2)
	_camera_shake(1.0)
	var white := ColorRect.new()
	white.color = Color(1, 1, 1, 0)
	white.size = Vector2(2000, 1200)
	white.position = Vector2(-500, -300)
	var layer := CanvasLayer.new()
	layer.layer = 38
	get_parent().add_child(layer)
	layer.add_child(white)
	var tw := create_tween().set_ignore_time_scale(true)
	tw.tween_interval(0.9)
	tw.tween_property(white, "color:a", 1.0, 1.4)
	tw.tween_callback(func():
		PlayerProgress.set_flag("game_beaten")
		SaveManager.autosave()
		super._die())


## Phase 3: the colossus, drawn — a mountain of throne-stone behind the dais.
func _draw() -> void:
	if _phase() != 3 or is_dead():
		return
	var t := Time.get_ticks_msec() / 1000.0
	var stone := Color(0.2, 0.18, 0.24)
	var stone_hi := Color(0.3, 0.27, 0.34)
	var breathe := sin(t * 0.9) * 3.0
	# The torso: tiers of stacked stone rising out of the dais.
	for i in 5:
		var w := 150.0 - i * 22.0
		var y := -i * 26.0 - 10.0 + breathe * (i / 5.0)
		draw_rect(Rect2(-w * 0.5, y - 26, w, 26), stone if i % 2 == 0 else stone_hi)
		draw_rect(Rect2(-w * 0.5, y - 26, w, 3), stone_hi.lightened(0.1))
	# The head: a great hooded shape with the crown fused in.
	var hy := -148.0 + breathe
	draw_circle(Vector2(0, hy), 26.0, stone_hi)
	for k in 3:
		draw_colored_polygon(PackedVector2Array([
			Vector2(-14 + k * 12, hy - 22), Vector2(-8 + k * 12, hy - 36), Vector2(-2 + k * 12, hy - 22)]),
			Color(0.7, 0.58, 0.3))
	# The eyes: cold cyan grief.
	var blink := 1.0 if fmod(t, 4.0) > 0.2 else 0.2
	draw_circle(Vector2(-9, hy - 2), 3.0, Color(0.5, 0.95, 1.0, blink))
	draw_circle(Vector2(9, hy - 2), 3.0, Color(0.5, 0.95, 1.0, blink))
	# The fists, hovering, one telegraphing if FIST state.
	for s in [-1.0, 1.0]:
		var fx: float = s * 110.0 + sin(t * 1.3 + s) * 8.0
		var fy: float = -70.0 + cos(t * 1.1 + s * 2.0) * 10.0
		if _state == FIST_TELL and signf(_fist_x - global_position.x) == s:
			fy -= 24.0   # the striking fist rears up
		draw_rect(Rect2(fx - 17, fy - 14, 34, 28), stone_hi)
		draw_rect(Rect2(fx - 17, fy - 14, 34, 5), stone_hi.lightened(0.15))


func _tell(c: Color) -> void:
	if _sprite and _sprite.modulate.a > 0.05:
		var prev := _sprite.modulate
		_sprite.modulate = Color(c.r, c.g, c.b, prev.a)
		create_tween().tween_property(_sprite, "modulate", prev, 0.3)
	elif _aura:
		var tw := create_tween()
		tw.tween_property(_aura, "energy", 1.6, 0.1)
		tw.tween_property(_aura, "energy", 0.7, 0.3)


func _camera_shake(amount: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(amount)
