extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var world: Node2D=load("res://class_sandbox.tscn").instantiate()
	world.training_mode=false
	root.add_child(world)
	await process_frame
	for row in world.Catalog.ITEMS:
		for entry in row:
			if not entry.id in world.unlocked: world.unlocked.append(entry.id)
	var camera := Camera2D.new()
	camera.position=Vector2(600,590)
	camera.zoom=Vector2(2.5,2.5)
	world.add_child(camera)
	DirAccess.make_dir_recursive_absolute("/tmp/class-sandbox-motion")
	var index := 0
	for job in [3,2,0]:
		world.show_choices()
		world.selected_job=job
		world.selected_slot=0
		world.start_selected()
		var p: CharacterBody2D=world.player
		p.set_physics_process(false)
		p.position=Vector2(360,681)
		for enemy in world.combat_targets: enemy.set_physics_process(false)
		world.female_visual.set_process(false)
		for frame in 60:
			p.facing=1 if frame<30 else -1
			p.position.x+=p.facing*p.current_run_speed()/30.0
			p.velocity=Vector2(0,1)
			p.move_and_slide()
			p.velocity.x=p.facing*p.current_run_speed()
			world.female_visual._process(1.0/30)
			camera.position.x=p.position.x+40
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/class-sandbox-motion/frame-%03d.png" % index)
			index+=1
		world.female_visual.set_process(true)
	print("Sandbox motion captured: quadruped run, glide and Warden run, both facings")
	quit()
