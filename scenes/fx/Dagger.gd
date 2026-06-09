extends Area2D
class_name DaggerProjectile
## Cairn — thrown dagger (GDD Section 5: 3 charges). Flies straight in the throw
## direction, damages the first enemy hurtbox it touches (spawning a hit spark),
## then frees. Detects enemy hurtboxes only (mask = layer 4), so it never hits
## the thrower.

@export var speed: float = 330.0
@export var damage: int = 1
@export var lifetime: float = 1.6

const HIT_SPARK := preload("res://scenes/fx/HitSpark.tscn")

var _dir := 1.0
var _life := 0.0


## Call right after instancing, before adding to the tree.
func setup(direction: int) -> void:
	_dir = signf(float(direction))


func _ready() -> void:
	var spr := get_node_or_null("Sprite") as Sprite2D
	if spr:
		spr.flip_h = _dir < 0.0
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position.x += _dir * speed * delta
	_life += delta
	if _life > lifetime:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	if body and body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		var spark: AnimatedSprite2D = HIT_SPARK.instantiate()
		get_parent().add_child(spark)
		spark.global_position = global_position
		queue_free()
