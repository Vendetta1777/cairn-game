extends Node2D
## Cairn — drifting glowing motes ("fireflies"/spores). Animated: each mote
## floats a slow ellipse and pulses. Spawned in a few deliberate clusters in the
## darker pockets of the cave, not scattered everywhere. Additive glow.

@export var color := Color(0.5, 0.92, 0.75)
# Cluster centres (x, y) and how many motes each.
const CLUSTERS := [Vector2(500, 168), Vector2(1100, 178), Vector2(1700, 140), Vector2(2300, 150), Vector2(2650, 160), Vector2(3050, 158), Vector2(3360, 150)]
const PER_CLUSTER := 5

var _motes: Array = []


func _ready() -> void:
	var tex := _radial()
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for c in CLUSTERS:
		for i in PER_CLUSTER:
			var base: Vector2 = c + Vector2(rng.randf_range(-26.0, 26.0), rng.randf_range(-20.0, 20.0))
			var s := Sprite2D.new()
			s.texture = tex
			s.material = mat
			s.scale = Vector2.ONE * rng.randf_range(0.12, 0.2)
			s.modulate = color
			s.position = base
			add_child(s)
			_motes.append({
				"s": s, "base": base, "ph": rng.randf() * TAU,
				"sp": rng.randf_range(0.3, 0.8),
				"rx": rng.randf_range(10.0, 28.0), "ry": rng.randf_range(8.0, 18.0),
			})


func _process(delta: float) -> void:
	for m in _motes:
		m["ph"] += delta * m["sp"]
		m["s"].position = m["base"] + Vector2(cos(m["ph"]) * m["rx"], sin(m["ph"] * 1.3) * m["ry"])
		m["s"].modulate.a = 0.35 + 0.4 * (0.5 + 0.5 * sin(m["ph"] * 2.0))


func _radial() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var gt := GradientTexture2D.new()
	gt.gradient = g
	gt.width = 64
	gt.height = 64
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	return gt
