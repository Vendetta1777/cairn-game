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
@export var scale_follow_speed: float = 22.0  ## how fast the dash stretch eases
@export var dash_stretch := Vector2(1.3, 0.82)

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
var _flash := Color.WHITE
var _state := "idle"


func _ready() -> void:
	_controller = get_node_or_null(controller_path)
	_sprite = get_node_or_null(sprite_path) as AnimatedSprite2D
	if _sprite:
		_base_scale = _sprite.scale.abs()
	if _controller:
		_state = _controller.get_current_state()
		_controller.state_changed.connect(_on_state_changed)
		_controller.dashed.connect(func(): _flash = FLASH_DASH)
	_play(_state)


func _process(delta: float) -> void:
	if not _sprite:
		return

	# Face movement direction (flip_h leaves scale free for the stretch).
	if _controller and _controller.get_facing() != 0:
		_sprite.flip_h = _controller.get_facing() < 0

	# Dash stretch eases in/out on top of the authored base scale.
	var target_scale := _base_scale
	if _state == "dash":
		target_scale = _base_scale * dash_stretch
	_sprite.scale = _sprite.scale.lerp(target_scale, 1.0 - exp(-scale_follow_speed * delta))

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
