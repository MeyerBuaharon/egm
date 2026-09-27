extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	await process_frame
	var p = room.player
	p.set_physics_process(false)
	p.appearance.set_process(false)
	var rig = p.appearance.get_child(0)
	rig.set_process(false)
	p.combat.air.set_process(false)
	room.camera.position_smoothing_enabled = false
	for e in room.combat_targets: e.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("/tmp/warden-air-review")
	for scenario in 5:
		p.reset()
		p.position = Vector2(650,300)
		p.facing = 1
		p.velocity = Vector2.ZERO
		p.move_and_slide()
		p.combat.selected = mini(scenario,3)
		for e in room.combat_targets:
			e.reset()
			e.hovering = false
			e.position = Vector2(160,682)
		room.combat_targets[0].position = Vector2(692,300)
		room.combat_targets[1].position = Vector2(800,335)
		if scenario < 4: p.combat.start()
		else: p.start_dash()
		for i in 100:
			if p.combat.active and p.combat.mode == p.combat.Mode.AIR:
				if p.combat.air.time>0.14 and p.combat.air.stage<3 and not p.combat.air.queued: p.combat.start()
			p._physics_process(1.0/30)
			for e in room.combat_targets: e._physics_process(1.0/30)
			p.combat.air._process(1.0/30)
			rig._process(1.0/30)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/warden-air-review/frame-%03d.png" % (scenario*100+i))
	quit()
