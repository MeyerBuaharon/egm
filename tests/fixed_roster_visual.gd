extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func capture() -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()
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
	p.velocity=Vector2(0,1)
	p.move_and_slide()
	room.camera.zoom=Vector2(3,3)
	room.camera.position=Vector2(210,648)
	for class_id in 4:
		room.select_class(class_id)
		await process_frame
		var visual: Node2D=p.appearance.get_child(0 if class_id==0 else (1 if class_id==2 else 3))
		visual._process(0)
		visual.set_process(false)
		var before := (await capture()).get_region(Rect2i(430,180,410,390))
		for slot in 7: p.equipment.pickup(class_id,slot)
		visual.queue_redraw()
		var after := (await capture()).get_region(Rect2i(430,180,410,390))
		var changed := 0
		for y in before.get_height():
			for x in before.get_width():
				var delta := before.get_pixel(x,y)-after.get_pixel(x,y)
				if absf(delta.r)+absf(delta.g)+absf(delta.b)>0.05: changed+=1
		print("%s class %d equipment changes %d character pixels" % ["PASS" if changed==0 else "FAIL",class_id,changed])
		if changed!=0: failures+=1
		(await capture()).save_png("res://previews/fixed-class-%d.png" % class_id)
		room.equipment_panel.show()
		room.equipment_panel.refresh()
		(await capture()).save_png("res://previews/gem-inventory-%d.png" % class_id)
		room.equipment_panel.hide()
		if class_id in [1,3]:
			var sheet := Image.create(1280,640,false,Image.FORMAT_RGBA8)
			for side in 2:
				p.facing=1 if side==0 else -1
				for step in 4:
					visual.run_frame=step
					visual.run_clock=step/4.0
					visual.queue_redraw()
					sheet.blit_rect(await capture(),Rect2i(480,260,320,320),Vector2i(step*320,side*320))
			sheet.save_png("res://previews/fixed-run-%d.png" % class_id)
			visual.run_frame=-1
		p.facing=1
		visual.set_process(true)
	print("Fixed roster: %d failures" % failures)
	quit(failures)
