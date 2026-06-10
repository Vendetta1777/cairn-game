extends SceneTree
func _initialize():
	var sheet: Texture2D = load("res://assets/sprites/npc/keeper.png")
	var frames := SpriteFrames.new(); frames.remove_animation("default")
	frames.add_animation("idle"); frames.set_animation_speed("idle", 4.0); frames.set_animation_loop("idle", true)
	for i in 4:
		var a := AtlasTexture.new(); a.atlas = sheet; a.region = Rect2(i*48, 0, 48, 48)
		frames.add_frame("idle", a)
	var err := ResourceSaver.save(frames, "res://scenes/npc/keeper_frames.tres")
	print("SAVED keeper_frames (err=", err, ")"); quit()
