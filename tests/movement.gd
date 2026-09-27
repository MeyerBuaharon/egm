extends SceneTree

var failures := 0
var room: Node2D
var p: CharacterBody2D

func _initialize() -> void:
	call_deferred("run")

func ticks(count: int) -> void:
	for i in count:
		await physics_frame
		await process_frame

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func run() -> void:
	room = load("res://main.tscn").instantiate()
	root.add_child(room)
	p = room.player
	await ticks(12)
	check(p.is_on_floor(), "spawn settles on floor")
	Input.action_press("right")
	await ticks(20)
	check(p.velocity.x > 100 and p.velocity.x <= p.warden_run_speed, "Warden accelerates toward heavy run speed")
	Input.action_press("dash")
	await ticks(2)
	check(p.dash_time > 0 and p.velocity.x > 500, "dash bursts forward")
	Input.action_release("dash")
	await ticks(24)
	Input.action_press("jump")
	await ticks(2)
	check(p.velocity.y < -500, "jump works after dash")
	Input.action_release("jump")
	Input.action_release("right")
	await ticks(2)
	check(p.velocity.y > -300, "jump release cuts ascent")
	Input.action_press("jump")
	await ticks(2)
	check(not p.air_jump and p.velocity.y < -400, "air jump consumes charge")
	Input.action_release("jump")
	p.reset()
	await ticks(8)
	Input.action_press("dig")
	await ticks(4)
	check(p.burrowed and p.position.y > 700, "dig enters ground")
	Input.action_release("dig")
	# Observe emergence itself instead of a frame-rate-dependent delay after it.
	for i in 80:
		await ticks(1)
		if not p.burrowed: break
	check(not p.burrowed and p.velocity.y < -600 and p.air_jump, "emerge launches and restores jump")
	p.reset()
	await ticks(8)
	Input.action_press("dig")
	await ticks(3)
	p.position.x = 1030
	Input.action_release("dig")
	await ticks(40)
	check(p.burrowed, "burrow cannot emerge into solid wall")
	p.position.x = 1090
	await ticks(2)
	check(not p.burrowed, "burrow can emerge in clear shaft")
	p.reset()
	p.position = Vector2(1060, 490)
	p.velocity = Vector2(-200, 200)
	Input.action_press("left")
	await ticks(10)
	check(p.is_on_wall() and p.velocity.y <= 151, "wall slide limits falling speed")
	Input.action_press("jump")
	await ticks(2)
	check(p.velocity.x > 300 and p.velocity.y < -500, "wall jump launches away")
	Input.action_release("jump")
	Input.action_release("left")
	p.reset()
	p.position = Vector2(730, 505)
	p.velocity.y = 300
	p.air_jump = false
	await ticks(14)
	check(p.combo == 1 and p.velocity.y < 0 and p.air_jump, "enemy contact bounces and restores jump")
	p.reset()
	await ticks(8)
	if not DisplayServer.get_name() == "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://movement-lab.png")
	for index in 4:
		Input.action_press("class_%d" % index)
		await ticks(2)
		Input.action_release("class_%d" % index)
		check(p.appearance.class_index == index, "switch class %d" % (index + 1))
		Input.action_press("kit")
		await ticks(2)
		Input.action_release("kit")
		Input.action_press("jump")
		await ticks(2)
		check(p.velocity.y < -500, "class %d keeps responsive jump" % (index + 1))
		Input.action_release("jump")
		p.reset()
		await ticks(8)
	for index in 4:
		Input.action_press("weapon")
		await ticks(2)
		Input.action_release("weapon")
		check(p.appearance.weapon_index == (index + 1) % 4, "cycle weapon %d" % index)
	check(p.run_speed == 340.0 and p.jump_speed == 640.0, "outfits preserve controller tuning")
	print("RESULT: %d failures" % failures)
	quit(1 if failures else 0)
