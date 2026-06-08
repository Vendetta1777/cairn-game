extends Node2D
class_name PlayerAnimator
## Cairn — Player animation driver (GDD Section 4).
##
## M1 approach (documented decision): the controller emits a string state from
## its AnimationTree state list (idle/run/jump/fall/dash/crouch/crawl/hurt/dead).
## Until we have sprite sheets (M2), there is no real AnimationTree/AnimationPlayer
## to drive — so this node:
##   1. tracks the current state,
##   2. flips the visual to face the move direction,
##   3. tints the placeholder so movement is *visible* while testing,
##   4. exposes play_state() as the single seam where the real AnimationTree
##      gets plugged in (replace the match body with anim_tree travel calls).
##
## This keeps M1 runnable today and makes the M2 swap a one-method change.

@export var controller_path: NodePath = NodePath("..")  ## the CharacterBody2D parent
@export var sprite_path: NodePath = NodePath("../Sprite") ## placeholder Polygon2D

# Placeholder tints per state — purely so you can read movement at a glance.
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

var _controller: PlayerController
var _sprite: Node2D


func _ready() -> void:
	_controller = get_node_or_null(controller_path) as PlayerController
	_sprite = get_node_or_null(sprite_path) as Node2D
	if _controller:
		_controller.state_changed.connect(play_state)
		play_state(_controller.get_current_state())


func _process(_delta: float) -> void:
	# Flip to face movement direction. (Cheap to poll; swap to signal later if needed.)
	if _controller and _sprite:
		_sprite.scale.x = absf(_sprite.scale.x) * _controller.get_facing()


## THE SEAM: when sprite sheets exist, replace the tint with:
##     anim_tree.get("parameters/playback").travel(state)
func play_state(state: String) -> void:
	if _sprite and STATE_COLORS.has(state):
		if _sprite is Polygon2D:
			(_sprite as Polygon2D).color = STATE_COLORS[state]
