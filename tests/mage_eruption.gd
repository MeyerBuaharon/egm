extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, label: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL",label])
	if not ok: failures += 1
func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	room.select_class(2)
	var p: CharacterBody2D = room.player
	p.set_physics_process(false)
	for mob in room.combat_targets: mob.set_physics_process(false)
	await physics_frame
	var mob: Node2D = room.combat_targets[0]
	for element in 4:
		p.reset()
		p.position = Vector2(200,725)
		p.burrowed = true
		p.collision_mask = 0
		p.combat.select_element(element)
		mob.reset()
		mob.position = Vector2(300,682)
		check(p.combat.start() and p.mana==82,"Eruption starts for 18 MP")
		p.combat.tick(0.1)
		check(p.burrowed and mob.health==40,"Wind-up stays underground without damage")
		p.combat.tick(0.18)
		check(not p.burrowed and p.collision_mask==1 and p.velocity.y<0,"Eruption restores collision and launches mage")
		check(mob.health==28,"Eruption damages once")
		match element:
			0: check(mob.burning>0,"Fire eruption burns")
			1: check(mob.frozen>0,"Ice eruption freezes")
			2: check(mob.knocked and mob.velocity.y< -650,"Wind eruption launches enemy")
			3: check(mob.half_buried and mob.position.x<300,"Earth pulls inward and half-buries")
		check(p.combat.start(),"Air follow-up buffers during eruption")
		p.combat.tick(0.4)
		check(p.combat.active and p.combat.aerial and p.combat.combo_index==1 and p.mana==76,"Eruption chains into air hit 1")
		p.combat.cancel()
	p.reset()
	p.position = Vector2(200,420)
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	for stage in range(1,4):
		mob.reset()
		mob.position = p.position+Vector2(80,0)
		check(p.combat.start() and p.combat.aerial,"Air combo starts stage %d" % stage)
		while p.combat.active: p.combat.tick(1.0/120)
		check(mob.health<40,"Air stage hits enemy")
	check(p.mana==74,"Air combo spends 26 MP")
	p.reset()
	p.position = Vector2(200,725)
	p.burrowed = true
	p.collision_mask = 0
	p.mana = 0
	p.exit_burrow()
	check(not p.burrowed and p.collision_mask==1 and not p.combat.active,"Zero MP still allows ordinary emergence")
	p.reset()
	p.burrowed = true
	p.position = Vector2(200,725)
	room.blocks.append(Rect2(180,650,40,40))
	check(not p.combat.start() and p.mana==100 and p.burrowed,"Blocked exit spends no MP")
	print("Mage eruption: %d failures" % failures)
	quit(failures)
