extends SceneTree
## Dev-only: render the test level for a few frames and save a screenshot,
## so changes can be verified headlessly-ish without a human at the screen.
## Run: godot --path . -s res://tools/screenshot.gd

var _frames := 0
var _scene_path := "res://scenes/test/TestLevel.tscn"
var _out := "/tmp/cairn_shot.png"


func _initialize() -> void:
	var packed: PackedScene = load(_scene_path)
	get_root().add_child(packed.instantiate())


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= 20:
		var img := get_root().get_texture().get_image()
		img.save_png(_out)
		print("SAVED ", _out)
		quit()
	return false
