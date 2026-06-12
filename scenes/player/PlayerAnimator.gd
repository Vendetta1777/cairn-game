extends Node2D
class_name PlayerAnimator
## Cairn — Player animation driver (GDD Section 4).
##
## Drives the AnimatedSprite2D player rig from the controller's state string:
##   - plays the matching animation (idle/run/jump/dash/crouch/hurt)
##   - flips horizontally to face movement (flip_h, independent of scale)
##   - DASH gets a horizontal speed-stretch so it reads as a burst, not a slide
##   - brief modulate flashes (cyan on dash, red on hurt) for readable juice
##
## Scale work is layered on top of the sprite's authored base scale (set in the
## scene), so resizing the character there doesn't break the dash stretch.

@export var controller_path: NodePath = NodePath("..")
@export var sprite_path: NodePath = NodePath("../Sprite")

@export_group("Feel")
@export var flash_fade_speed: float = 9.0     ## how fast modulate returns to white
@export var scale_follow_speed: float = 26.0  ## how fast the dash stretch eases
@export var dash_stretch := Vector2(1.4, 0.55) ## long + squashed: head ducks low
@export var dash_drop: float = 9.0            ## sink the whole body low to the ground

@export_group("Dash trail")
@export var trail_interval: float = 0.022     ## seconds between afterimages
@export var trail_color := Color(0.5, 0.85, 1.0, 0.5)  ## cold shadow ghost
@export var trail_fade: float = 0.3           ## ghost fade-out time

@export_group("Attack swing")
@export var swing_duration: float = 0.2       ## procedural swing length (no attack frame on the sheet)
@export var swing_lunge: float = 7.0          ## forward thrust px
@export var swing_dip: float = 2.0            ## small dip into the swing
@export var swing_thrust := Vector2(0.22, 0.14) ## scale punch (wide, short)
@export var swing_windup: float = 0.5         ## how far she pulls back before striking (no tilt)

# Controller state -> animation name that exists in player_frames.tres.
const STATE_ANIM := {
	"idle":   "idle",
	"run":    "run",
	"jump":   "jump",
	"fall":   "jump",
	"dash":   "dash",
	"crouch": "crouch",
	"crawl":  "crouch",
	"wall_slide": "jump",
	"hurt":   "hurt",
	"dead":   "hurt",
}

const FLASH_DASH := Color(0.7, 0.95, 1.0)
const FLASH_HURT := Color(1.0, 0.5, 0.5)

# Untyped: avoids a parse-time dependency on PlayerController's global class name.
var _controller
var _sprite: AnimatedSprite2D

var _base_scale := Vector2.ONE
var _base_pos := Vector2.ZERO
var _cur_scale := Vector2.ONE
var _cur_pos := Vector2.ZERO
var _flash := Color.WHITE
var _state := "idle"
var _trail_t := 0.0
var _attack_t := 0.0
var _attack_facing := 1
var _attack_mult := 1.0
var _was_wall_sliding := false
var _wall_dust_t := 0.0


func _ready() -> void:
	_controller = get_node_or_null(controller_path)
	_sprite = get_node_or_null(sprite_path) as AnimatedSprite2D
	if _sprite:
		_base_scale = _sprite.scale.abs()
		_base_pos = _sprite.position
		_cur_scale = _base_scale
		_cur_pos = _base_pos
	if _controller:
		_state = _controller.get_current_state()
		_controller.state_changed.connect(_on_state_changed)
		_controller.dashed.connect(func(): _flash = FLASH_DASH)
		if _controller.has_signal("jumped"):
			_controller.jumped.connect(_on_jumped)
		if _controller.has_signal("grappled"):
			_controller.grappled.connect(_on_grappled)
	var combat := get_node_or_null("../Combat")
	if combat and combat.has_signal("attacked"):
		combat.attacked.connect(_on_attacked)
	_play(_state)


## Procedural swing — kicks off on each attack (the combo middle hit swings the
## opposite way; the finisher lunges harder).
func _on_attacked(step: int) -> void:
	_attack_t = swing_duration
	_attack_facing = _controller.get_facing() if _controller else 1
	_attack_mult = 1.35 if step == 2 else 1.0   # finisher lunges harder


## Swing motion over p in [0,1], normalized: a quick wind-back to -windup, a
## snappy strike to +1, then a smooth recover to 0. (smoothstep eases.)
func _swing_curve(p: float) -> float:
	if p < 0.18:
		return -swing_windup * (p / 0.18)
	elif p < 0.46:
		var q := (p - 0.18) / 0.28
		return lerpf(-swing_windup, 1.0, q * q * (3.0 - 2.0 * q))
	var r := (p - 0.46) / 0.54
	return lerpf(1.0, 0.0, r * r * (3.0 - 2.0 * r))


func _process(delta: float) -> void:
	if not _sprite:
		return

	# Face movement direction (flip_h leaves scale/rotation free for the lean).
	var facing := 1
	if _controller and _controller.get_facing() != 0:
		facing = _controller.get_facing()
		_sprite.flip_h = facing < 0

	# Dash: NO tilt — just duck low. The sprite squashes (head drops) and the
	# whole body sinks toward the ground, staying upright and facing forward.
	# Sets up sliding under obstacles/enemies later. Eases on the authored base.
	# Eased base (dash duck/stretch) kept separate from the transient swing.
	var target_scale := _base_scale
	var target_pos := _base_pos
	if _state == "dash":
		target_scale = _base_scale * dash_stretch
		target_pos = _base_pos + Vector2(0, dash_drop)
	var t := 1.0 - exp(-scale_follow_speed * delta)
	_cur_scale = _cur_scale.lerp(target_scale, t)
	_cur_pos = _cur_pos.lerp(target_pos, t)

	# Attack swing (NO tilt): wind back -> snap forward into the strike -> recover,
	# plus a forward scale-thrust. Sells a swing even though the sheet has no
	# attack frame. Additive on the eased base.
	var atk_off := Vector2.ZERO
	var atk_scale := Vector2.ONE
	if _attack_t > 0.0:
		_attack_t = maxf(0.0, _attack_t - delta)
		var p := clampf(1.0 - _attack_t / swing_duration, 0.0, 1.0)
		var c := _swing_curve(p)          # -windup .. +1 .. 0
		var fwd := maxf(c, 0.0)
		atk_off = Vector2(_attack_facing * swing_lunge * _attack_mult * c, swing_dip * fwd)
		atk_scale = Vector2(1.0 + swing_thrust.x * fwd, 1.0 - swing_thrust.y * fwd)

	# Wall-slide pose: cling toward the wall with a small lean, and trail dust
	# down the wall face.
	var lean := 0.0
	if _state == "wall_slide":
		var wall_dir: int = _controller.get_facing() if _controller else 1
		lean = wall_dir * 0.14
		_wall_dust_t -= delta
		if _wall_dust_t <= 0.0:
			_spawn_wall_dust(wall_dir)
			_wall_dust_t = 0.05
	_was_wall_sliding = _state == "wall_slide"

	_sprite.scale = _cur_scale * atk_scale
	_sprite.position = _cur_pos + atk_off
	_sprite.rotation = lean

	# Dash leaves a fading shadow afterimage trail.
	if _state == "dash":
		_trail_t -= delta
		if _trail_t <= 0.0:
			_spawn_ghost()
			_trail_t = trail_interval
	else:
		_trail_t = 0.0

	# Hit/dash flash eases back to white.
	_flash = _flash.lerp(Color.WHITE, 1.0 - exp(-flash_fade_speed * delta))
	_sprite.modulate = _flash


## One frozen, fading copy of the current frame — the dash trail.
func _spawn_ghost() -> void:
	if _sprite.sprite_frames == null:
		return
	var tex := _sprite.sprite_frames.get_frame_texture(_sprite.animation, _sprite.frame)
	if tex == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = tex
	ghost.global_position = _sprite.global_position
	ghost.scale = _sprite.scale
	ghost.flip_h = _sprite.flip_h
	ghost.modulate = trail_color
	var host: Node = _controller.get_parent() if _controller else get_parent()
	host.add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, trail_fade)
	tw.tween_callback(ghost.queue_free)


## The grapple line: a taut iron-grey wire from the player to the anchor, alive
## only while the flight lasts.
func _on_grappled(target: Vector2) -> void:
	var line := Line2D.new()
	line.width = 1.6
	line.default_color = Color(0.75, 0.78, 0.85, 0.9)
	var host: Node = _controller.get_parent()
	host.add_child(line)
	var ctrl = _controller
	var upd := func():
		if not is_instance_valid(line):
			return
		line.clear_points()
		line.add_point(ctrl.global_position + Vector2(0, -8))
		line.add_point(target)
	upd.call()
	var timer := Timer.new()
	timer.wait_time = 0.016
	timer.autostart = true
	line.add_child(timer)
	timer.timeout.connect(func():
		if not is_instance_valid(ctrl) or not ctrl.get("_grappling"):
			if is_instance_valid(line):
				var tw := line.create_tween()
				tw.tween_property(line, "modulate:a", 0.0, 0.12)
				tw.tween_callback(line.queue_free)
			timer.stop()
		else:
			upd.call())


## A jump while clinging = wall jump: kick a burst of dust off the wall.
func _on_jumped() -> void:
	if _was_wall_sliding:
		var wall_dir: int = _controller.get_facing() if _controller else 1
		# facing has already flipped away from the wall, so dust goes off the
		# opposite side (where the wall was).
		for i in range(5):
			_spawn_wall_dust(-wall_dir, 1.0 + i * 0.2)


## A small fading puff of dust on the wall side, drifting down (or out, on a jump).
func _spawn_wall_dust(wall_dir: int, spread := 0.0) -> void:
	if _sprite == null:
		return
	var puff := Polygon2D.new()
	var s := 2.2
	puff.polygon = PackedVector2Array([Vector2(0, -s), Vector2(s, 0), Vector2(0, s), Vector2(-s, 0)])
	puff.color = Color(0.62, 0.66, 0.78, 0.5)
	var host: Node = _controller.get_parent() if _controller else get_parent()
	host.add_child(puff)
	puff.global_position = _sprite.global_position + Vector2(wall_dir * 7.0, 6.0 + randf() * 6.0)
	var drift := Vector2(wall_dir * (4.0 + spread * 8.0) + randf_range(-3, 3), 10.0 + randf() * 8.0)
	var tw := puff.create_tween().set_parallel(true)
	tw.tween_property(puff, "global_position", puff.global_position + drift, 0.35)
	tw.tween_property(puff, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(puff.queue_free)


func _on_state_changed(new_state: String) -> void:
	_state = new_state
	if new_state == "hurt":
		_flash = FLASH_HURT
	_play(new_state)


func _play(state: String) -> void:
	if not _sprite:
		return
	var anim: String = STATE_ANIM.get(state, "idle")
	if _sprite.animation != anim:
		_sprite.play(anim)


## Tint flash (e.g. white on a parry); eases back to normal automatically.
func flash(color: Color) -> void:
	_flash = color


## Seam for combat (M3): let attacks request a one-shot animation.
func play_oneshot(anim: String) -> void:
	if _sprite and _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)
