extends Area2D
class_name ShadowBolt
## Cairn — Shadow bolt (GDD Section 5: costs 20 shadow energy, fast, pierces one
## enemy). Flies fast in the cast direction; damages enemy hurtboxes (each once),
## passing through `pierce` of them before freeing. Detects layer 4 only.

@export var speed: float = 470.0
@export var damage: int = 1
@export var pierce: int = 1      ## enemies it passes THROUGH (so it can hit pierce+1)
@export var lifetime: float = 1.4

const HIT_SPARK := preload("res://scenes/fx/HitSpark.tscn")

var _dir := 1.0
var _life := 0.0
var _hits := 0
var _already := {}


func setup(direction: int) -> void:
	_dir = signf(float(direction))


func _ready() -> void:
	if _dir < 0.0:
		scale.x = -absf(scale.x)
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position.x += _dir * speed * delta
	_life += delta
	if _life > lifetime:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	var body := area.get_parent()
	if body == null or not body.has_method("take_damage") or _already.has(body):
		return
	_already[body] = true
	body.take_damage(damage, global_position)
	var spark: AnimatedSprite2D = HIT_SPARK.instantiate()
	get_parent().add_child(spark)
	spark.global_position = global_position
	_hits += 1
	if _hits > pierce:
		queue_free()
