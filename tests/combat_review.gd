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
	DirAccess.make_dir_recursive_absolute("/tmp/warden-combat-review")
	for weapon in 4:
		p.reset()
		p.position = Vector2(520,725)
		p.burrowed = true
		p.collision_mask = 0
		p.combat.selected = weapon
		for enemy in room.combat_targets: enemy.reset()
		p.combat.start()
		for i in 60:
			p._physics_process(1.0/30)
			for enemy in room.combat_targets: enemy._physics_process(1.0/30)
			rig._process(1.0/30)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/warden-combat-review/frame-%03d.png" % (weapon*60+i))
	quit()
