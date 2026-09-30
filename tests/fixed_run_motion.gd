extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for i in 12: await physics_frame
	var p: CharacterBody2D=room.player
	p.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	for item in room.pickups:
		item.set_process(false)
		item.hide()
	room.camera.zoom=Vector2(3,3)
	room.camera.position=Vector2(210,648)
	var render := DisplayServer.get_name()!="headless"
	if render: DirAccess.make_dir_recursive_absolute("/tmp/fixed-run-motion")
	var image_index := 0
	var caption_layer := CanvasLayer.new()
	root.add_child(caption_layer)
	var caption := Label.new()
	caption.position=Vector2(425,105)
	caption.add_theme_font_size_override("font_size",22)
	caption_layer.add_child(caption)
	for class_id in [1,3]:
		room.select_class(class_id)
		await process_frame
		var visual: Node2D=p.appearance.get_child(3)
		visual.set_process(false)
		var seen: Array[int]=[]
		for frame in 120:
			p.position=Vector2(210,681)
			p.velocity=Vector2(0,1)
			p.move_and_slide()
			p.facing=1 if frame%60<30 else -1
			room.camera.zoom=Vector2.ONE*(3 if frame<60 else 1)
			caption.text=("Strider" if class_id==1 else "Wildborn")+" · "+("right" if p.facing>0 else "left")+" · "+("close-up" if frame<60 else "gameplay size")
			p.velocity.x=p.current_run_speed()*p.facing
			visual._process(1.0/30)
			if not visual.run_frame in seen: seen.append(visual.run_frame)
			if render:
				await process_frame
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("/tmp/fixed-run-motion/frame-%03d.png" % image_index)
				image_index+=1
		if seen.size()!=4: failures+=1
		print("%s class %d covers all four full-body run frames" % ["PASS" if seen.size()==4 else "FAIL",class_id])
		visual.set_process(true)
	quit(failures)
