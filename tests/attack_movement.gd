extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	print(("PASS " if ok else "FAIL ")+text)
	if not ok: failures += 1
func ticks(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame
func run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	await ticks(10)
	var p = room.player
	var rig = p.appearance.get_child(0)
	rig.set_process(false)
	p.velocity = Vector2.ZERO
	rig.start_slash()
	var start: Vector2 = p.position
	Input.action_press("right")
	Input.action_press("jump")
	Input.action_press("dig")
	await ticks(20)
	check(p.position.distance_to(start)<1 and not p.burrowed,"standing slash blocks move jump and dig")
	for action in ["right","jump","dig"]: Input.action_release(action)
	p.combat.cancel()
	p.velocity.x = 180
	rig.start_slash()
	start = p.position
	Input.action_press("left")
	await ticks(40)
	check(p.position.x>start.x+10 and p.position.x<start.x+110,"running slash slides a short distance forward")
	check(p.facing == 1 and p.velocity.x == 0,"opposite input cannot steer attack and slide brakes to rest")
	p.combat.cancel()
	await ticks(10)
	check(p.velocity.x<0,"movement returns after recovery")
	Input.action_release("left")
	p.reset()
	check(not p.combat.active,"reset clears attack lock")
	quit(failures)
