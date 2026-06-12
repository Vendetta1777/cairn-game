extends Node2D
## Cairn — an ASH VENT (The Ashpits): a fissure in the forge floor that roars a
## column of hot ash upward (or sideways). Stand in the column and it carries
## you — a hazard turned traversal tool. The boss arena's vents switch on in
## phase 2 via set_active(). Drawn procedurally: a cracked grate over a glow,
## with rising ember particles scaled to the column height.

@export var column_height: float = 120.0    ## how far the push column reaches
@export var push_accel: float = 2400.0      ## fights gravity (1100) hard
@export var max_carry_speed: float = 250.0  ## terminal speed inside the column
@export var sideways: bool = false          ## push along +x * direction instead of up
@export var direction: int = 1              ## for sideways vents: 1 right, -1 left
@export var active: bool = true

var _t := 0.0
var _player: Node2D    # set while the player is inside the column

@onready var _zone: Area2D = $Zone
@onready var _shape: CollisionShape2D = $Zone/Shape
@onready var _glow: PointLight2D = $Glow
@onready var _embers: CPUParticles2D = $Embers


func _ready() -> void:
	# Size the detection column and particle stream to column_height.
	var rect := RectangleShape2D.new()
	if sideways:
		rect.size = Vector2(column_height, 44)
		_shape.position = Vector2(direction * column_height * 0.5, -22)
		_embers.direction = Vector2(direction, 0)
		_embers.gravity = Vector2(direction * 60, -10)
	else:
		rect.size = Vector2(44, column_height)
		_shape.position = Vector2(0, -column_height * 0.5)
	_shape.shape = rect
	_embers.emitting = active
	_zone.area_entered.connect(_on_enter)
	_zone.area_exited.connect(_on_exit)


func set_active(v: bool) -> void:
	active = v
	_embers.emitting = v


func _on_enter(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_player = b


func _on_exit(area: Area2D) -> void:
	var b := area.get_parent()
	if b and b.is_in_group("player"):
		_player = null


func _physics_process(delta: float) -> void:
	if not active or _player == null or not is_instance_valid(_player):
		return
	if sideways:
		_player.velocity.x += direction * push_accel * delta
		_player.velocity.x = clampf(_player.velocity.x, -max_carry_speed * 1.4, max_carry_speed * 1.4)
	else:
		_player.velocity.y -= push_accel * delta
		_player.velocity.y = maxf(_player.velocity.y, -max_carry_speed)


func _process(delta: float) -> void:
	_t += delta
	_glow.energy = (0.85 + sin(_t * 7.0) * 0.25 + sin(_t * 13.0) * 0.1) if active else 0.12
	queue_redraw()


func _draw() -> void:
	# Cracked stone grate over an ember glow.
	var glow_c := Color(1.0, 0.45, 0.12, 0.8 if active else 0.15)
	draw_rect(Rect2(-20, -4, 40, 5), Color(0.16, 0.13, 0.12))
	draw_rect(Rect2(-22, 0, 44, 3), Color(0.1, 0.08, 0.07))
	for i in range(4):
		var gx := -15.0 + i * 10.0
		draw_rect(Rect2(gx, -3, 4, 3), glow_c)
	if not active:
		return
	# The shimmering column — faint vertical (or horizontal) heat streaks.
	var wob := sin(_t * 9.0) * 2.0
	for i in range(3):
		var off := (i - 1) * 9.0 + wob * (1.0 if i % 2 == 0 else -1.0)
		var a := 0.10 + 0.05 * sin(_t * 5.0 + i * 2.0)
		if sideways:
			draw_rect(Rect2(0 if direction > 0 else -column_height, -30 + off, column_height, 3),
				Color(1.0, 0.6, 0.25, a))
		else:
			draw_rect(Rect2(off - 1.5, -column_height, 3, column_height - 6),
				Color(1.0, 0.6, 0.25, a))
