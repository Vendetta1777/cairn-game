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
@export var dash_stretch := Vector2(1.45, 0.7)  ## flat + long: a low comic dash
@export var dash_lean_deg: float = 26.0       ## forward lean into the dash direction
@export var dash_drop: float = 5.0            ## sink low to the ground while dashing

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
var _flash := Color.WHITE
var _state := "idle"


func _ready() -> void:
	_controller = get_node_or_null(controller_path)
	_sprite = get_node_or_null(sprite_path) as AnimatedSprite2D
	if _sprite:
		_base_scale = _sprite.scale.abs()
		_base_pos = _sprite.position
	if _controller:
		_state = _controller.get_current_state()
		_controller.state_changed.connect(_on_state_changed)
		_controller.dashed.connect(func(): _flash = FLASH_DASH)
	_play(_state)


func _process(delta: float) -> void:
	if not _sprite:
		return

	# Face movement direction (flip_h leaves scale/rotation free for the lean).
	var facing := 1
	if _controller and _controller.get_facing() != 0:
		facing = _controller.get_facing()
		_sprite.flip_h = facing < 0

	# Dash: flatten + lean forward + sink low (a low comic dash you can later
	# slide under things with). Everything eases on top of the authored base.
	var target_scale := _base_scale
	var target_rot := 0.0
	var target_pos := _base_pos
	if _state == "dash":
		target_scale = _base_scale * dash_stretch
		target_rot = deg_to_rad(dash_lean_deg) * facing
		target_pos = _base_pos + Vector2(0, dash_drop)

	var t := 1.0 - exp(-scale_follow_speed * delta)
	_sprite.scale = _sprite.scale.lerp(target_scale, t)
	_sprite.rotation = lerp_angle(_sprite.rotation, target_rot, t)
	_sprite.position = _sprite.position.lerp(target_pos, t)

	# Hit/dash flash eases back to white.
	_flash = _flash.lerp(Color.WHITE, 1.0 - exp(-flash_fade_speed * delta))
	_sprite.modulate = _flash


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


## Seam for combat (M3): let attacks request a one-shot animation.
func play_oneshot(anim: String) -> void:
	if _sprite and _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)
