extends SceneTree
## Dev tool: build the Crawler (axe imp) SpriteFrames from individual frame PNGs.
## Run: godot --headless --path . -s res://tools/build_crawler_frames.gd
## Output: res://scenes/enemies/crawler/crawler_frames.tres

const DIR := "res://assets/sprites/enemies/crawler/"

# name -> [file_prefix, count, fps, loop]
const ANIMS := {
	"idle":   ["stand_up", 5, 6.0,  true],
	"walk":   ["walk",     6, 8.0,  true],
	"run":    ["run",      6, 12.0, true],
	"attack": ["attack1",  6, 12.0, false],
	"hurt":   ["hit",      3, 14.0, false],
	"die":    ["dead",     4, 10.0, false],
}


func _initialize() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name in ANIMS:
		var cfg: Array = ANIMS[anim_name]
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, cfg[2])
		frames.set_animation_loop(anim_name, cfg[3])
		for i in cfg[1]:
			var tex: Texture2D = load("%s%s_%d.png" % [DIR, cfg[0], i + 1])
			if tex == null:
				push_error("missing %s_%d" % [cfg[0], i + 1])
				continue
			frames.add_frame(anim_name, tex)
		print("  %-7s %d frames" % [anim_name, cfg[1]])
	var err := ResourceSaver.save(frames, "res://scenes/enemies/crawler/crawler_frames.tres")
	print("SAVED crawler_frames.tres (err=%d)" % err)
	quit()
