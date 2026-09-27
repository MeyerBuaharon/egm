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
	for enemy in room.combat_targets: enemy.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("/tmp/warden-combo-review")
	for weapon in 8:
		p.reset()
		p.position = Vector2(535 if weapon < 4 else 610,681)
		p.facing = 1 if weapon < 4 else -1
		p.burrowed = false
		p.collision_mask = 1
		p.velocity.y = 1
		p.move_and_slide()
		p.combat.selected = weapon % 4
		for enemy in room.combat_targets: enemy.reset()
		p.combat.start()
		for i in 100:
			if p.combat.active and p.combat.time>0.15 and p.combat.combo_index<3 and not p.combat.queued: p.combat.start()
			p._physics_process(1.0/30)
			for enemy in room.combat_targets: enemy._physics_process(1.0/30)
			rig._process(1.0/30)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/warden-combo-review/frame-%03d.png" % (weapon*100+i))
	quit()
