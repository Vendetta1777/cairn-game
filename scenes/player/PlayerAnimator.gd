extends Node2D
class_name PlayerAnimator
## Cairn — Player animation driver (GDD Section 4).
##
## Drives the layered-Polygon2D assassin rig (the "Sprite" container) with:
##   - PROCEDURAL squash-and-stretch for game feel:
##       jump -> stretch tall/thin   land -> hard squash that springs back
##       fall -> slight stretch      dash -> stretch wide/flat
##       crouch/crawl -> squash down  idle/run -> subtle breathing bob
##   - facing flip (folded into scale.x)
##   - brief modulate flashes (cyan on dash, red on hurt) for readable juice
##
## THE SEAM (M2 with real sprite art): keep these state strings, but swap the
## body of _process()/_on_state_changed() to drive an AnimationTree on a
## Sprite2D/AnimatedSprite2D — controller + signals stay identical.

@export var controller_path: NodePath = NodePath("..")
@export var sprite_path: NodePath = NodePath("../Sprite")

@export_group("Feel")
@export var stretch_follow_speed: float = 14.0  ## how fast scale eases to its target
@export var flash_fade_speed: float = 9.0       ## how fast modulate returns to white
@export var bob_amount: float = 0.04            ## idle/run breathing depth
@export var land_squash: Vector2 = Vector2(1.35, 0.65)
@export var jump_pop: Vector2 = Vector2(0.7, 1.3)

# Per-state resting stretch target (x = width, y = height; 1.0 = neutral).
const STATE_STRETCH := {
	"idle":   Vector2(1.0, 1.0),
	"run":    Vector2(1.0, 1.0),
	"jump":   Vector2(0.82, 1.18),
	"fall":   Vector2(0.9, 1.1),
	"dash":   Vector2(1.35, 0.7),
	"crouch": Vector2(1.25, 0.7),
	"crawl":  Vector2(1.25, 0.7),
	"hurt":   Vector2(1.1, 0.9),
	"dead":   Vector2(1.3, 0.6),
}

const FLASH_DASH := Color(0.7, 0.95, 1.0)   ## cold cyan pop
const FLASH_HURT := Color(1.0, 0.5, 0.5)    ## red sting

# Untyped: avoids a parse-time dependency on PlayerController's global class name.
var _controller
var _sprite: Node2D

var _stretch := Vector2.ONE       ## current eased stretch
var _flash := Color.WHITE         ## current modulate, eases back to white
var _bob_time := 0.0
var _state := "idle"


func _ready() -> void:
	_controller = get_node_or_null(controller_path)
	_sprite = get_node_or_null(sprite_path) as Node2D
	if _controller:
		_state = _controller.get_current_state()
		_controller.state_changed.connect(_on_state_changed)
		_controller.jumped.connect(func(): _stretch = jump_pop)
		_controller.landed.connect(func(): _stretch = land_squash)
		_controller.dashed.connect(func():
			_stretch = Vector2(1.5, 0.6)
			_flash = FLASH_DASH)


func _process(delta: float) -> void:
	if not _sprite:
		return

	# Resting target for the current state, plus a breathing bob on idle/run.
	var target: Vector2 = STATE_STRETCH.get(_state, Vector2.ONE)
	if _state == "idle" or _state == "run":
		_bob_time += delta * (10.0 if _state == "run" else 4.0)
		var bob := sin(_bob_time) * bob_amount
		target += Vector2(-bob, bob)  # squash/stretch conserves rough volume

	# Frame-rate-independent ease toward targets.
	var t := 1.0 - exp(-stretch_follow_speed * delta)
	_stretch = _stretch.lerp(target, t)
	_flash = _flash.lerp(Color.WHITE, 1.0 - exp(-flash_fade_speed * delta))

	# Fold facing into x so the figure mirrors with movement direction.
	var facing: int = _controller.get_facing() if _controller else 1
	_sprite.scale = Vector2(_stretch.x * facing, _stretch.y)
	_sprite.modulate = _flash


func _on_state_changed(new_state: String) -> void:
	_state = new_state
	if new_state == "hurt":
		_flash = FLASH_HURT


## THE SEAM for M2 art — swap the body for anim_tree travel(state).
func play_state(state: String) -> void:
	_on_state_changed(state)
