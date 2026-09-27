extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://main.tscn").instantiate()
	root.add_child(room)
	await create_timer(0.15).timeout
	var actor: CharacterBody2D = room.player
	actor.set_physics_process(false)
	var rig: Node2D = actor.appearance
	rig.set_process(false)
	actor.velocity = Vector2.ZERO
	rig.run_blend = 0
	rig.was_running = false
	rig._process(1.0/60)
	assert(rig.pose == "Idle")
	actor.velocity.x = 40
	rig._process(1.0/60)
	assert(rig.pose == "Push off" and rig.run_blend > 0 and rig.run_blend < 0.3)
	var last: Vector2 = rig.feet[0]
	var worst_jump := 0.0
	for i in 24:
		actor.velocity.x = minf(340,40+i*20)
		rig._process(1.0/60)
		worst_jump = maxf(worst_jump,last.distance_to(rig.feet[0]))
		last = rig.feet[0]
	assert(rig.pose == "Run" and rig.run_blend == 1)
	actor.velocity.x = 0
	rig._process(1.0/60)
	assert(rig.pose == "Stop" and rig.run_blend > 0)
	for i in 20:
		rig._process(1.0/60)
	assert(rig.pose == "Idle" and rig.run_blend == 0)
	assert(rig.feet[0].distance_to(Vector2(-5,0)) < 0.01)
	assert(worst_jump < 12, "foot teleports during startup")
	print("PASS idle → push-off → run → stop → idle; startup maximum foot step: ",worst_jump)
	quit()
