extends SceneTree
## Dev tool: slice the Bat enemy sheets into a SpriteFrames resource.
## Run: godot --headless --path . -s res://tools/build_bat_frames.gd
## Output: res://scenes/enemies/fly/bat_frames.tres

const FRAME := 64
const DIR := "res://assets/sprites/enemies/bat/"

# name -> [file, frames, fps, loop]
const ANIMS := {
	"idle_fly": ["Bat-IdleFly.png", 9, 12.0, true],
	"fly":      ["Bat-Run.png",     8, 12.0, true],
	"attack":   ["Bat-Attack1.png", 8, 14.0, false],
	"hurt":     ["Bat-Hurt.png",    5, 16.0, false],
	"die":      ["Bat-Die.png",    12, 14.0, false],
}


func _initialize() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for anim_name in ANIMS:
		var cfg: Array = ANIMS[anim_name]
		var sheet: Texture2D = load(DIR + cfg[0])
		if sheet == null:
			push_error("Missing: " + cfg[0])
			continue
		frames.add_animation(anim_name)
		frames.set_animation_speed(anim_name, cfg[2])
		frames.set_animation_loop(anim_name, cfg[3])
		for i in cfg[1]:
			var atlas := AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(i * FRAME, 0, FRAME, FRAME)
			frames.add_frame(anim_name, atlas)
		print("  %-9s %d frames" % [anim_name, cfg[1]])
	var err := ResourceSaver.save(frames, "res://scenes/enemies/fly/bat_frames.tres")
	print("SAVED bat_frames.tres (err=%d)" % err)
	quit()
