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
@export var swing_thrust := Vector2(0.2, 0.12) ## scale punch (wide, short)
@export var swing_lean_deg: float = 15.0      ## lean into the swing arc

# Controller state -> animation name that exists in player_frames.tres.
const STATE_ANIM := {
	"idle":   "idle",
	"run":    "run",
	"jump":   "jump",
	"fall":   "jump",
	"dash":   "dash",
	"crouch": "crouch",
	"crawl":  "crouch",
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
var _swing_sign := 1.0
var _attack_mult := 1.0


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
	var combat := get_node_or_null("../Combat")
	if combat and combat.has_signal("attacked"):
		combat.attacked.connect(_on_attacked)
	_play(_state)


## Procedural swing — kicks off on each attack (the combo middle hit swings the
## opposite way; the finisher lunges harder).
func _on_attacked(step: int) -> void:
	_attack_t = swing_duration
	_attack_facing = _controller.get_facing() if _controller else 1
	_swing_sign = -1.0 if step == 1 else 1.0
	_attack_mult = 1.4 if step == 2 else 1.0


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

	# Attack swing: a quick forward lunge + thrust + lean, additive on the base,
	# so the body reads as swinging even though the sheet has no attack frame.
	var atk_off := Vector2.ZERO
	var atk_scale := Vector2.ONE
	var atk_rot := 0.0
	if _attack_t > 0.0:
		_attack_t = maxf(0.0, _attack_t - delta)
		var p := clampf(1.0 - _attack_t / swing_duration, 0.0, 1.0)
		var s := sin(p * PI)   # 0 -> 1 -> 0 over the swing
		atk_off = Vector2(_attack_facing * swing_lunge * _attack_mult * s, swing_dip * s)
		atk_scale = Vector2(1.0 + swing_thrust.x * s, 1.0 - swing_thrust.y * s)
		atk_rot = _attack_facing * deg_to_rad(swing_lean_deg) * _swing_sign * s

	_sprite.scale = _cur_scale * atk_scale
	_sprite.position = _cur_pos + atk_off
	_sprite.rotation = atk_rot

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
