extends Node
## Cairn — the player's RING INVENTORY + item effects. HOLD I: a radial ring of
## the carried items fades in around the player (game keeps running — drinking
## mid-fight is a risk, like it should be). A/D rotate the selection; RELEASE I
## to use the selected item. All effects live here:
##   ichor (heal) · smoke (i-frames + stagger) · prism (shadow refill) ·
##   charm (passive death-cancel, checked by PlayerStats) · shatter (burst) ·
##   lantern (reveal secrets 30s) · flask (burning dash-trail 10s) ·
##   echo (rewind your position 2s).

const Items = preload("res://scenes/systems/ItemDB.gd")
const FONT := preload("res://assets/fonts/silkscreen.ttf")

var _controller
var _stats
var _ring_open := false
var _sel := 0
var _ring_ui: Control

# Echo stone: a 2s position history (sampled at 20 Hz).
var _history: Array[Vector2] = []
var _hist_t := 0.0
# Ashen flask state.
var _flask_t := 0.0
var _flame_t := 0.0
# Pale lantern state.
var _lantern_t := 0.0
var _lantern_lights: Array = []


func _ready() -> void:
	_controller = get_parent()
	_stats = get_node_or_null("../Stats")
	# The ring UI rides a CanvasLayer so it sits above the world.
	var layer := CanvasLayer.new()
	layer.layer = 14
	add_child(layer)
	_ring_ui = Control.new()
	_ring_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ring_ui.draw.connect(_paint_ring)
	_ring_ui.visible = false
	layer.add_child(_ring_ui)
	# Sized AFTER parenting — presets only take once a parent rect exists.
	_ring_ui.set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	# Position history for the echo stone.
	_hist_t += delta
	if _hist_t >= 0.05:
		_hist_t = 0.0
		_history.append(_controller.global_position)
		if _history.size() > 40:   # 40 * 0.05s = 2s
			_history.pop_front()
	# Ashen flask: burning trail while dashing.
	if _flask_t > 0.0:
		_flask_t -= delta
		if _controller.get_current_state() == "dash":
			_flame_t -= delta
			if _flame_t <= 0.0:
				_flame_t = 0.045
				_spawn_flame(_controller.global_position + Vector2(0, 6))
	# Pale lantern timeout.
	if _lantern_t > 0.0:
		_lantern_t -= delta
		if _lantern_t <= 0.0:
			_clear_lantern()

	# Ring input.
	if Input.is_action_pressed("inventory"):
		if not _ring_open:
			_ring_open = true
			_sel = 0
			_ring_ui.visible = true
		if Input.is_action_just_pressed("move_left"):
			_sel = wrapi(_sel - 1, 0, maxi(_owned().size(), 1))
			AudioManager.play("step_stone", -18.0)
		elif Input.is_action_just_pressed("move_right"):
			_sel = wrapi(_sel + 1, 0, maxi(_owned().size(), 1))
			AudioManager.play("step_stone", -18.0)
		_ring_ui.queue_redraw()
	elif _ring_open:
		_ring_open = false
		_ring_ui.visible = false
		var owned := _owned()
		if not owned.is_empty():
			_use(owned[mini(_sel, owned.size() - 1)])


func _owned() -> Array:
	var out := []
	for id in Items.DB:
		if PlayerProgress.item_count(id) > 0:
			out.append(id)
	return out


func _use(id: String) -> void:
	if not PlayerProgress.use_item(id):
		return
	AudioManager.play("chest", -10.0)
	match id:
		"ichor":
			_stats.heal(2)
			AudioManager.play("heal", -8.0)
		"smoke":
			_controller.grant_iframes(2.0)
			AudioManager.play("bolt", -8.0)
			_burst_fx(Color(0.6, 0.62, 0.7), 26)
			for e in get_tree().get_nodes_in_group("enemy"):
				if e.global_position.distance_to(_controller.global_position) < 130.0 \
						and e.has_method("stagger"):
					e.stagger(_controller.global_position, 240.0, 1.2)
		"prism":
			_stats.refill_shadow()
			AudioManager.play("heal", -8.0)
		"charm":
			# Passive — using it directly just re-pockets it (it works from the ring).
			PlayerProgress.add_item("charm")
		"shatter":
			AudioManager.play("boss_slam", -6.0)
			GameManager.hitstop(0.06)
			_burst_fx(Color(0.95, 0.6, 0.3), 34)
			var cam := get_viewport().get_camera_2d()
			if cam and cam.has_method("add_trauma"):
				cam.add_trauma(0.55)
			for e in get_tree().get_nodes_in_group("enemy"):
				if e.global_position.distance_to(_controller.global_position) < 110.0 \
						and e.has_method("take_damage"):
					e.take_damage(4, _controller.global_position)
		"lantern":
			_lantern_t = 30.0
			AudioManager.play("checkpoint", -10.0)
			_light_secrets()
		"flask":
			_flask_t = 10.0
			AudioManager.play("bolt", -10.0)
		"echo":
			if not _history.is_empty():
				_burst_fx(Color(0.6, 0.55, 0.95), 18)
				_controller.global_position = _history[0]
				_controller.velocity = Vector2.ZERO
				_controller.grant_iframes(0.8)
				AudioManager.play("heal", -6.0)
	SaveManager.autosave()


## The Bone Charm check — PlayerStats calls this at the killing blow.
static func try_cancel_death() -> bool:
	if PlayerProgress.item_count("charm") > 0:
		PlayerProgress.use_item("charm")
		return true
	return false


func _burst_fx(col: Color, n: int) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = n
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 160.0
	p.gravity = Vector2(0, 60)
	p.color = col
	_controller.get_parent().add_child(p)
	p.global_position = _controller.global_position
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _spawn_flame(at: Vector2) -> void:
	var flame := Area2D.new()
	flame.collision_layer = 0
	flame.collision_mask = 4
	var cs := CollisionShape2D.new()
	var sh := CircleShape2D.new()
	sh.radius = 9.0
	cs.shape = sh
	flame.add_child(cs)
	var light := PointLight2D.new()
	light.color = Color(1.0, 0.55, 0.2)
	light.energy = 0.5
	light.texture = _radial()
	light.texture_scale = 0.4
	flame.add_child(light)
	flame.area_entered.connect(func(a):
		var b = a.get_parent()
		if b and b.is_in_group("enemy") and b.has_method("take_damage"):
			b.take_damage(1, flame.global_position))
	_controller.get_parent().add_child(flame)
	flame.global_position = at
	var tw := flame.create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(flame.queue_free)


func _light_secrets() -> void:
	for grp in ["cache", "gate", "relic", "exit", "portal", "grapple_point"]:
		for n in get_tree().get_nodes_in_group(grp):
			if not (n is Node2D):
				continue
			var l := PointLight2D.new()
			l.color = Color(0.95, 0.9, 0.6)
			l.energy = 0.9
			l.texture = _radial()
			l.texture_scale = 0.7
			n.add_child(l)
			_lantern_lights.append(l)


func _clear_lantern() -> void:
	for l in _lantern_lights:
		if is_instance_valid(l):
			l.queue_free()
	_lantern_lights.clear()


func _radial() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 96
	gt.height = 96
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0)
	return gt


# --- the ring, drawn --------------------------------------------------------------

func _paint_ring() -> void:
	var s := _ring_ui.size
	if s.x <= 0.0:
		s = _ring_ui.get_viewport_rect().size
	var c := s * 0.5
	var owned := _owned()
	_ring_ui.draw_circle(c, 120.0, Color(0.02, 0.02, 0.05, 0.55))
	_ring_ui.draw_arc(c, 120.0, 0, TAU, 48, Color(0.4, 0.42, 0.55, 0.6), 1.5)
	if owned.is_empty():
		_ring_ui.draw_string(FONT, Vector2(c.x - 150, c.y), "— no items — the Vestibule merchant trades —",
			HORIZONTAL_ALIGNMENT_CENTER, 300, 10, Color(0.6, 0.62, 0.75))
		return
	var sel: int = mini(_sel, owned.size() - 1)
	for i in owned.size():
		var ang := -PI * 0.5 + TAU * i / owned.size()
		var p := c + Vector2.from_angle(ang) * 86.0
		var id: String = owned[i]
		var item: Dictionary = Items.get_item(id)
		var tint: Color = item.get("tint", Color.GRAY)
		var is_sel := i == sel
		_ring_ui.draw_circle(p, 22.0 if is_sel else 16.0, Color(0.08, 0.08, 0.13, 0.95))
		_ring_ui.draw_arc(p, 22.0 if is_sel else 16.0, 0, TAU, 24,
			Color(1, 1, 1, 0.9) if is_sel else Color(0.4, 0.42, 0.55, 0.7), 1.5)
		# Item glyph: a tinted diamond.
		var sz := 8.0 if is_sel else 6.0
		_ring_ui.draw_colored_polygon(PackedVector2Array([
			p + Vector2(0, -sz), p + Vector2(sz, 0), p + Vector2(0, sz), p + Vector2(-sz, 0)]), tint)
		_ring_ui.draw_string(FONT, p + Vector2(10, 18), "x%d" % PlayerProgress.item_count(id),
			HORIZONTAL_ALIGNMENT_LEFT, 50, 8, Color(0.8, 0.84, 0.95))
	# Selected item name + description.
	var cur: Dictionary = Items.get_item(owned[sel])
	_ring_ui.draw_string(FONT, Vector2(c.x - 200, c.y + 146), str(cur.get("name", "")),
		HORIZONTAL_ALIGNMENT_CENTER, 400, 13, Color(0.95, 0.95, 1.0))
	_ring_ui.draw_string(FONT, Vector2(c.x - 230, c.y + 166), str(cur.get("desc", "")),
		HORIZONTAL_ALIGNMENT_CENTER, 460, 9, Color(0.6, 0.64, 0.78))
	_ring_ui.draw_string(FONT, Vector2(c.x - 150, c.y - 134), "A / D  select      release I  use",
		HORIZONTAL_ALIGNMENT_CENTER, 300, 9, Color(0.5, 0.53, 0.66))
