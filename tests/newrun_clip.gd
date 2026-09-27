extends SceneTree

# Captures the real game view (level + HUD + camera) while the Warden runs,
# so the new run cycle can be reviewed in motion.

func run() -> void:
	var room: Node2D = load("res://main.tscn").instantiate()
	root.add_child(room)
	await create_timer(0.2).timeout
	var actor: CharacterBody2D = room.player
	actor.set_physics_process(false)
	DirAccess.make_dir_recursive_absolute("/tmp/newclip")
	var rig: Node2D = actor.appearance.get_child(0)
	var x := 200.0
	for frame in 90:
		var dt := 1.0 / 30.0
		# Drive a steady right-ward run at the warden's top speed.
		actor.velocity.x = actor.warden_run_speed
		x += actor.warden_run_speed * dt
		if x > 1150.0:
			x = 150.0
		actor.position.x = x
		actor.position.y = actor.FLOOR_Y - actor.HALF_HEIGHT - 1
		actor.facing = 1.0
		rig._process(dt)
		room._process(dt)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/newclip/f-%03d.png" % frame)
	quit()

func _initialize() -> void:
	call_deferred("run")
