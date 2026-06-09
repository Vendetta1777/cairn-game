extends Node2D
class_name PlayerAnimator
## Cairn — Player animation driver (GDD Section 4).
##
## Until we have sprite sheets (the real M2 art task), this drives the
## placeholder Polygon2D with PROCEDURAL squash-and-stretch + a per-state tint,
## so movement has real game-feel and reads clearly:
##   - jump  -> stretch tall/thin       - land  -> hard squash that springs back
##   - fall  -> slight stretch          - dash  -> stretch wide/flat
##   - crouch/crawl -> squash down       - idle/run -> subtle breathing bob
##
## THE SEAM (M2 with art): keep these state strings, but in play_state() call
##   anim_tree.get("parameters/playback").travel(state)
## on a real AnimationTree instead of setting tint/stretch. Nothing else changes.
##
## Facing is folded into scale.x here (we own the sprite's scale entirely), so
## there's no separate flip node to fight with.

@export var controller_path: NodePath = NodePath("..")
@export var sprite_path: NodePath = NodePath("../Sprite")

@export_group("Feel")
@export var stretch_follow_speed: float = 14.0  ## how fast scale eases to its target
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

const STATE_COLORS := {
	"idle":   Color(0.65, 0.70, 0.80),
	"run":    Color(0.55, 0.80, 0.65),
	"jump":   Color(0.80, 0.80, 0.50),
	"fall":   Color(0.80, 0.65, 0.45),
	"dash":   Color(0.55, 0.75, 0.95),
	"crouch": Color(0.50, 0.55, 0.65),
	"crawl":  Color(0.45, 0.55, 0.60),
	"hurt":   Color(0.90, 0.35, 0.35),
	"dead":   Color(0.35, 0.30, 0.35),
}

# Untyped: avoids a parse-time dependency on PlayerController's global class name.
var _controller
var _sprite: Node2D

var _stretch := Vector2.ONE       ## current eased stretch
var _bob_time := 0.0
var _state := "idle"


func _ready() -> void:
	_controller = get_node_or_null(controller_path)
	_sprite = get_node_or_null(sprite_path) as Node2D
	if _controller:
		_state = _controller.get_current_state()
		_controller.state_changed.connect(_on_state_changed)
		# Transient pops keyed off movement events.
		_controller.jumped.connect(func(): _stretch = jump_pop)
		_controller.landed.connect(func(): _stretch = land_squash)
		_controller.dashed.connect(func(): _stretch = Vector2(1.5, 0.6))
	_apply_color(_state)


func _process(delta: float) -> void:
	if not _sprite:
		return

	# Resting target for the current state, plus a breathing bob on idle/run.
	var target: Vector2 = STATE_STRETCH.get(_state, Vector2.ONE)
	if _state == "idle" or _state == "run":
		_bob_time += delta * (10.0 if _state == "run" else 4.0)
		var bob := sin(_bob_time) * bob_amount
		target += Vector2(-bob, bob)  # squash/stretch conserves rough volume

	# Critically-damped-ish ease toward target (frame-rate independent).
	var t := 1.0 - exp(-stretch_follow_speed * delta)
	_stretch = _stretch.lerp(target, t)

	# Fold facing into x so the sprite mirrors with movement direction.
	var facing := 1
	if _controller:
		facing = _controller.get_facing()
	_sprite.scale = Vector2(_stretch.x * facing, _stretch.y)


func _on_state_changed(new_state: String) -> void:
	_state = new_state
	_apply_color(new_state)


func _apply_color(state: String) -> void:
	if _sprite is Polygon2D and STATE_COLORS.has(state):
		(_sprite as Polygon2D).color = STATE_COLORS[state]


## THE SEAM for M2 art — swap the body for anim_tree travel(state).
func play_state(state: String) -> void:
	_on_state_changed(state)
