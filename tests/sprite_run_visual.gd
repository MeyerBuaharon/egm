extends SceneTree
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
	p.position=Vector2(210,681)
	room.camera.zoom=Vector2(3,3)
	room.camera.position=Vector2(210,648)
	for class_id in [1,3]:
		room.select_class(class_id)
		p.position=Vector2(210,681)
		await process_frame
		var visual: Node2D=p.appearance.get_child(3)
		visual._process(0)
		visual.set_process(false)
		visual.run_frame=0
		visual.combat_frame=-1
		p.facing=1
		var sheet := Image.create(1280,320,false,Image.FORMAT_RGBA8)
		for phase in 4:
			visual.run_clock=phase/4.0
			visual.run_frame=phase
			visual.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			sheet.blit_rect(root.get_texture().get_image(),Rect2i(480,260,320,320),Vector2i((phase%4)*320,(phase/4)*320))
		sheet.save_png("res://previews/sprite-run-%d.png" % class_id)
		visual.set_process(true)
	quit()
