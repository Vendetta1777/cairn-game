extends SceneTree
## Dev-only: render ANY area scene at a chosen spot and save a screenshot.
## The player is teleported to (X,Y) so the camera frames that location.
## Run (needs GPU, not --headless):
##   SHOT_SCENE=res://scenes/world/area_01_hollowed_gate/Area1.tscn \
##   SHOT_X=1240 SHOT_Y=200 SHOT_OUT=/tmp/cairn_a1_relic.png \
##   godot --path . -s res://tools/shot_area.gd

var _frames := 0


func _initialize() -> void:
	var scene_path := OS.get_environment("SHOT_SCENE")
	if scene_path == "":
		scene_path = "res://scenes/world/area_01_hollowed_gate/Area1.tscn"
	var packed: PackedScene = load(scene_path)
	get_root().add_child(packed.instantiate())


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 5:
		var player := get_root().get_node_or_null("/root").find_child("Player", true, false)
		var x := OS.get_environment("SHOT_X")
		var y := OS.get_environment("SHOT_Y")
		if player and x != "" and y != "":
			player.global_position = Vector2(float(x), float(y))
			player.velocity = Vector2.ZERO
	if _frames >= 40:
		var out := OS.get_environment("SHOT_OUT")
		if out == "":
			out = "/tmp/cairn_shot.png"
		var img := get_root().get_texture().get_image()
		img.save_png(out)
		print("SAVED ", out)
		quit()
	return false
