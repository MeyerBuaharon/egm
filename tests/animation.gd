extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ", message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://main.tscn").instantiate()
	root.add_child(room)
	await create_timer(0.15).timeout
	var player: CharacterBody2D = room.player
	player.set_physics_process(false)
	var rig: Node2D = player.appearance
	rig.set_process(false)
	player.velocity.x = 340
	rig.run_blend = 1.0
	for character in 4:
		rig.class_index = character
		for gear in 2:
			rig.heavy = gear == 1
			for weapon in 4:
				rig.weapon_index = weapon
				for direction in [-1,1]:
					player.facing = direction
					for frame in 16:
						rig.phase = frame/16.0
						rig.update_pose(1.0/60)
						check(rig.grip_error < 0.001, "hand grip separates")
						check(rig.support_error < 0.001, "support grip separates")
						for i in 2:
							check(rig.knees[i].is_finite() and rig.elbows[i].is_finite(), "invalid joint")
							check(rig.feet[i].y <= 0.001, "foot penetrates floor")
		player.burrowed = true
		rig.on_action("dig", player.position)
		rig.action_time = 0.12
		rig.update_pose(0.12)
		check(rig.pose == "Burrow" and rig.render_alpha > 0, "entry pose missing")
		rig.action_time = 0
		rig.update_pose(0.12)
		check(rig.render_alpha == 0, "body still visible underground")
		player.burrowed = false
		rig.on_action("emerge", player.position)
		rig.update_pose(0.01)
		check(rig.pose == "Emerge", "emerge missing")
		rig.action_time = 0
		rig.stow = 0
	var start: Vector2 = rig.gait_foot(0.1)
	var next: Vector2 = rig.gait_foot(0.2)
	check(absf(next.x-start.x+8.4)<0.001 and start.y==0 and next.y==0, "planted foot travel differs from root")
	check(rig.gait_foot(0.99999).distance_to(rig.gait_foot(0))<0.01,"run cycle seam")
	print("Animation QA: 1024 pose/loadout/facing samples; burrow transitions; contact timing. Failures: ",failures)
	quit(1 if failures else 0)
