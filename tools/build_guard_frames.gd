extends SceneTree
func _initialize():
	var sheet: Texture2D = load("res://assets/sprites/npc/guard_idle.png")
	var fr := SpriteFrames.new(); fr.remove_animation("default")
	fr.add_animation("idle"); fr.set_animation_speed("idle", 6.0); fr.set_animation_loop("idle", true)
	for i in 4:
		var a := AtlasTexture.new(); a.atlas = sheet; a.region = Rect2(i*128, 0, 128, 96); fr.add_frame("idle", a)
	print("err=", ResourceSaver.save(fr, "res://scenes/npc/guard_frames.tres")); quit()
