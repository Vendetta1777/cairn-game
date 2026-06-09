extends AnimatedSprite2D
class_name OneShotVFX
## A fire-and-forget visual effect: plays its (non-looping) animation once,
## then frees itself. Used for the attack slash and the hit spark.

func _ready() -> void:
	animation_finished.connect(queue_free)
	play()


## Spawn helper: instances a packed VFX scene at a spot, optionally flipped.
static func spawn(packed: PackedScene, parent: Node, at: Vector2, flip := false) -> void:
	var fx := packed.instantiate() as OneShotVFX
	parent.add_child(fx)
	fx.global_position = at
	fx.flip_h = flip
