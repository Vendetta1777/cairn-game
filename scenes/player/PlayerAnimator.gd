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
var _trail_t := 0.0


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

	# Dash: NO tilt — just duck low. The sprite squashes (head drops) and the
	# whole body sinks toward the ground, staying upright and facing forward.
	# Sets up sliding under obstacles/enemies later. Eases on the authored base.
	var target_scale := _base_scale
	var target_pos := _base_pos
	if _state == "dash":
		target_scale = _base_scale * dash_stretch
		target_pos = _base_pos + Vector2(0, dash_drop)

	var t := 1.0 - exp(-scale_follow_speed * delta)
	_sprite.scale = _sprite.scale.lerp(target_scale, t)
	_sprite.position = _sprite.position.lerp(target_pos, t)

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


## Seam for combat (M3): let attacks request a one-shot animation.
func play_oneshot(anim: String) -> void:
	if _sprite and _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)
