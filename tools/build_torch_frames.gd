extends SceneTree
func _initialize():
	var sheet: Texture2D = load("res://assets/decor/torch.png")
	var fr := SpriteFrames.new(); fr.remove_animation("default")
	fr.add_animation("burn"); fr.set_animation_speed("burn", 10.0); fr.set_animation_loop("burn", true)
	for i in 4:
		var a := AtlasTexture.new(); a.atlas = sheet; a.region = Rect2(i*16, 0, 16, 16); fr.add_frame("burn", a)
	print("err=", ResourceSaver.save(fr, "res://scenes/decor/torch_frames.tres")); quit()
