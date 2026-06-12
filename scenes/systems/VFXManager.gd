extends Node
## Cairn — VFXManager (autoload): one place for every transient effect, so any
## script can fire-and-forget. All procedural (CPUParticles2D + drawn rings) in
## the current scene; everything frees itself.
##   dust(pos, power)        — landing/jump dust, scaled by impact
##   splatter(pos, dir)      — dark ichor, arcs away from the hit
##   death_burst(pos, tint)  — enemy death: burst out, then a soul orb drifts
##                             to the player and feeds the shadow meter glow
##   parry_ring(pos)         — the bright expanding parry ring
##   ember_trail(pos)        — small fire puff (ashen flask, furnace moments)

func _scene() -> Node:
	return get_tree().current_scene if get_tree().current_scene else get_tree().root


func _particles(pos: Vector2, cfg: Dictionary) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = cfg.get("amount", 10)
	p.lifetime = cfg.get("lifetime", 0.5)
	p.explosiveness = 1.0
	p.direction = cfg.get("direction", Vector2.UP)
	p.spread = cfg.get("spread", 60.0)
	p.initial_velocity_min = cfg.get("vel_min", 30.0)
	p.initial_velocity_max = cfg.get("vel_max", 90.0)
	p.gravity = cfg.get("gravity", Vector2(0, 220))
	p.scale_amount_min = cfg.get("scale_min", 0.8)
	p.scale_amount_max = cfg.get("scale_max", 1.8)
	p.color = cfg.get("color", Color.WHITE)
	_scene().add_child(p)
	p.global_position = pos
	get_tree().create_timer(p.lifetime + 0.5).timeout.connect(func():
		if is_instance_valid(p):
			p.queue_free())
	return p


func dust(pos: Vector2, power: float = 0.5) -> void:
	_particles(pos, {
		"amount": int(6 + power * 16.0), "lifetime": 0.4 + power * 0.3,
		"direction": Vector2.UP, "spread": 80.0,
		"vel_min": 20.0 + power * 40.0, "vel_max": 60.0 + power * 90.0,
		"gravity": Vector2(0, 260), "color": Color(0.55, 0.52, 0.5, 0.7),
		"scale_min": 0.8, "scale_max": 1.4 + power * 1.2,
	})


func splatter(pos: Vector2, dir: Vector2) -> void:
	_particles(pos, {
		"amount": 7, "lifetime": 0.45,
		"direction": dir.normalized() if dir != Vector2.ZERO else Vector2.UP,
		"spread": 38.0, "vel_min": 60.0, "vel_max": 140.0,
		"gravity": Vector2(0, 420), "color": Color(0.22, 0.05, 0.1, 0.9),
		"scale_min": 0.7, "scale_max": 1.6,
	})


func death_burst(pos: Vector2, tint: Color = Color(0.6, 0.8, 0.95)) -> void:
	_particles(pos, {
		"amount": 18, "lifetime": 0.7, "direction": Vector2.UP, "spread": 180.0,
		"vel_min": 40.0, "vel_max": 130.0, "gravity": Vector2(0, 60),
		"color": Color(tint.r, tint.g, tint.b, 0.85),
	})
	_soul_orb(pos)


## The essence orb: condenses, then homes to the player and pops.
func _soul_orb(pos: Vector2) -> void:
	var orb := Node2D.new()
	orb.set_script(preload("res://scenes/fx/SoulOrb.gd"))
	_scene().add_child(orb)
	orb.global_position = pos


func parry_ring(pos: Vector2) -> void:
	var ring := Node2D.new()
	ring.set_script(preload("res://scenes/fx/ExpandRing.gd"))
	_scene().add_child(ring)
	ring.global_position = pos


func ember_trail(pos: Vector2) -> void:
	_particles(pos, {
		"amount": 5, "lifetime": 0.4, "direction": Vector2.UP, "spread": 30.0,
		"vel_min": 20.0, "vel_max": 60.0, "gravity": Vector2(0, -80),
		"color": Color(1.0, 0.55, 0.2, 0.9), "scale_min": 0.6, "scale_max": 1.3,
	})
