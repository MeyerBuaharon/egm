extends SceneTree
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: failures += 1
func run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	for i in 12:
		await physics_frame
		await process_frame
	var p = room.player
	var c = p.combat
	p.set_physics_process(false)
	for e in room.combat_targets: e.set_physics_process(false)
	var enemy = room.combat_targets[1]
	for weapon in 4:
		p.reset()
		p.position = Vector2(535,681)
		p.velocity.y = 1
		p.move_and_slide()
		enemy.reset()
		c.selected = weapon
		p.velocity.x = c.running_threshold-1
		Input.action_press("right")
		check(c.start() and c.mode == c.Mode.REGULAR,"below threshold is regular even with move input: %d" % weapon)
		Input.action_release("right")
		var seen := []
		for i in 400:
			if not c.active: break
			if not c.combo_index in seen: seen.append(c.combo_index)
			if c.time>0.15 and c.combo_index<3 and not c.queued: c.start()
			c.tick(1.0/120)
		check(seen == [1,2,3] and enemy.hit_count == 3,"three distinct hits, one per swing: %d" % weapon)
		check(enemy.stunned==0 and enemy.buried==0 and not enemy.knocked and not enemy.dropping,"combo applies no status: %d" % weapon)
		check(not c.active and c.combo_window==0,"third hit ends chain: %d" % weapon)
	p.reset()
	p.position = Vector2(535,681)
	p.velocity = Vector2(120,1)
	p.move_and_slide()
	c.selected = 0
	check(c.start() and c.mode==c.Mode.RUNNING,"threshold selects running attack")
	while c.active: c.tick(1.0/120)
	p.velocity.x = 180
	check(c.start() and c.mode==c.Mode.REGULAR and c.combo_index==1,"follow-up overrides speed after special")
	while c.active: c.tick(1.0/120)
	c.idle_tick(0.5)
	p.velocity.x = 180
	check(c.start() and c.mode==c.Mode.RUNNING,"expired chain allows running attack again")
	c.cancel()
	p.position = Vector2(500,350)
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	check(c.start() and c.mode == c.Mode.AIR,"air attack selected off ground")
	c.cancel()
	p.burrowed = true
	p.position = Vector2(500,725)
	check(c.start() and c.mode==c.Mode.BURROW,"burrow takes priority over regular threshold")
	quit(failures)
