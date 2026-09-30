extends SceneTree
var count := 0
func _initialize() -> void: call_deferred("run")
func capture(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
func run() -> void:
	var world: Node2D=load("res://class_sandbox.tscn").instantiate()
	world.training_mode=false
	root.add_child(world)
	await process_frame
	for job in 4:
		world.selected_job=job
		world.selected_slot=0
		world.refresh_choices()
		await capture("res://previews/sandbox-menu-%d.png" % job)
	for row in world.Catalog.ITEMS:
		for entry in row:
			if not entry.id in world.unlocked: world.unlocked.append(entry.id)
	var camera := Camera2D.new()
	camera.position=Vector2(600,590)
	camera.zoom=Vector2(2,2)
	world.add_child(camera)
	for job in 4:
		for slot in 4:
			world.show_choices()
			world.selected_job=job
			world.selected_slot=slot
			world.start_selected()
			var p: CharacterBody2D=world.player
			p.set_physics_process(false)
			p.position=Vector2(540,681)
			p.velocity=Vector2(0,1)
			p.move_and_slide()
			for enemy in world.combat_targets: enemy.set_physics_process(false)
			p.combat.start()
			p.combat.time=p.combat.combo_duration()*0.48
			await capture("res://previews/sandbox-item-%d-%d.png" % [job,slot])
			p.combat.cancel()
			world.set_process(false)
			world.female_visual._process(0)
			world.female_visual.set_process(false)
			p.appearance._process(0)
			for child in p.appearance.get_children():
				if child.has_method("_process"): child._process(0)
			p.appearance.set_process(false)
			for child in p.appearance.get_children(): child.set_process(false)
			await process_frame
			await RenderingServer.frame_post_draw
			var before := root.get_texture().get_image().get_region(Rect2i(400,400,240,240))
			for gear_slot in 7: p.equipment.set_worn(job,gear_slot,true)
			world.power=3
			world.female_visual._process(0)
			p.appearance._process(0)
			for child in p.appearance.get_children():
				if child.has_method("_process"): child._process(0)
			await process_frame
			await RenderingServer.frame_post_draw
			var after := root.get_texture().get_image().get_region(Rect2i(400,400,240,240))
			if before.get_data()!=after.get_data():
				push_error("Equipment altered character pixels job %d slot %d" % [job,slot])
				quit(1)
				return
			world.set_process(true)
			world.female_visual.set_process(true)
			p.appearance.set_process(true)
			for child in p.appearance.get_children(): child.set_process(true)
	world.show_choices()
	world.selected_job=3
	world.selected_slot=0
	world.start_selected()
	var p: CharacterBody2D=world.player
	p.set_physics_process(false)
	p.position=Vector2(540,681)
	for enemy in world.combat_targets: enemy.set_physics_process(false)
	world.female_visual.set_process(false)
	var sheet := Image.create(1280,640,false,Image.FORMAT_RGBA8)
	for side in 2:
		p.facing=1 if side==0 else -1
		for phase in 4:
			p.velocity=Vector2(0,1)
			p.move_and_slide()
			p.velocity.x=200*p.facing
			world.female_visual.phase=phase/4.0
			world.female_visual._process(0)
			await process_frame
			await RenderingServer.frame_post_draw
			sheet.blit_rect(root.get_texture().get_image(),Rect2i(350,300,320,320),Vector2i(phase*320,side*320))
	sheet.save_png("res://previews/sandbox-wildborn-run.png")
	print("Sandbox visual review captures complete")
	quit()
