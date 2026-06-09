extends Node2D
class_name PlayerAnimator
## Cairn — Player animation driver (GDD Section 4).
##
## Drives the AnimatedSprite2D player rig from the controller's state string:
##   - plays the matching animation (idle/run/jump/attack/crouch/hurt)
##   - flips horizontally to face movement
##   - brief modulate flashes (cyan on dash, red on hurt) for readable juice
##
## The controller emits states from its full list; we map them onto the
## animations we actually have art for (fall reuses jump, dash reuses run,
## crawl reuses crouch, dead reuses hurt) so nothing ever plays a missing clip.

@export var controller_path: NodePath = NodePath("..")
@export var sprite_path: NodePath = NodePath("../Sprite")

@export_group("Feel")
@export var flash_fade_speed: float = 9.0   ## how fast modulate returns to white

# Controller state -> animation name that exists in player_frames.tres.
const STATE_ANIM := {
	"idle":   "idle",
	"run":    "run",
	"jump":   "jump",
	"fall":   "jump",
	"dash":   "run",
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

var _flash := Color.WHITE
var _state := "idle"


func _ready() -> void:
	_controller = get_node_or_null(controller_path)
	_sprite = get_node_or_null(sprite_path) as AnimatedSprite2D
	if _controller:
		_state = _controller.get_current_state()
		_controller.state_changed.connect(_on_state_changed)
		_controller.dashed.connect(func(): _flash = FLASH_DASH)
	_play(_state)


func _process(delta: float) -> void:
	if not _sprite:
		return
	# Face movement direction.
	if _controller and _controller.get_facing() != 0:
		_sprite.flip_h = _controller.get_facing() < 0
	# Ease the hit/dash flash back to white.
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
