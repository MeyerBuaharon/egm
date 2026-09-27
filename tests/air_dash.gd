extends SceneTree
var failures := 0
var room: Node2D
var p: CharacterBody2D
var enemy: Node2D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: failures += 1
func ticks(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame
func setup(weapon: int) -> void:
	p.reset()
	p.set_physics_process(false)
	p.position = Vector2(560,390)
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	p.facing = 1
	p.combat.selected = weapon
	for e in room.combat_targets:
		e.reset()
		e.set_physics_process(false)
		e.position = Vector2(150,682)
	enemy.position = Vector2(602,390)
func step(n: int) -> void:
	for i in n:
		if p.combat.active: p.combat.tick(1.0/120)
		for e in room.combat_targets: e._physics_process(1.0/120)
func run() -> void:
	room = load("res://main.tscn").instantiate()
	root.add_child(room)
	p = room.player
	enemy = room.combat_targets[0]
	await ticks(12)
	check(not InputMap.has_action("slide"),"slide input removed")
	check(p.start_dash(),"ground dash starts")
	check(p.invulnerable and not p.take_damage(10),"dash blocks damage")
	await ticks(26)
	check(not p.invulnerable and p.take_damage(10),"damage works after dash window")
	setup(0)
	check(p.start_dash(),"dash starts in midair")
	var y := p.position.y
	for i in 12: p.tick_dash(1.0/120)
	check(absf(p.position.y-y)<0.1,"air dash suspends gravity briefly")
	check(not p.start_dash(),"dash cannot retrigger during cooldown")
	setup(0)
	check(p.combat.start() and p.combat.mode==p.combat.Mode.AIR,"air sword starts")
	step(16)
	y = p.position.y
	var enemy_y := enemy.position.y
	step(10)
	check(absf(p.position.y-y)<0.1 and absf(enemy.position.y-enemy_y)<0.1,"connected hit suspends player and enemy")
	check(p.combat.start(),"second air hit queues")
	step(35)
	check(p.combat.air.stage==2 and enemy.hit_count==2,"two air hits register")
	check(p.combat.start(),"sword finisher queues")
	step(30)
	check(p.combat.air.stage==3,"third input starts sword throw")
	var pre_hits: int = enemy.hit_count
	while p.combat.air.time<0.23: step(1)
	check(p.combat.air.teleported and enemy.hit_count==pre_hits,"teleport occurs before damage")
	while p.combat.air.time<0.44: step(1)
	check(enemy.hit_count==pre_hits+1 and enemy.stunned>0,"sheathe applies delayed path damage and stun")
	step(40)
	check(not p.combat.active,"sword finisher recovers")
	for weapon in [1,3]:
		setup(weapon)
		p.position = Vector2(650,300)
		enemy.position = Vector2(692,300)
		p.combat.start()
		step(18)
		p.combat.start()
		step(40)
		check(enemy.velocity.y>0 and enemy.velocity.x>0,"second hit knocks diagonally down: %d" % weapon)
		p.combat.start()
		step(32)
		check(p.combat.air.stage==3 and p.velocity.x>0 and p.velocity.y>0,"axe/spear finisher dives down-forward: %d" % weapon)
		step(160)
		check(not p.combat.active and p.position.y<=681,"dive ends on terrain: %d" % weapon)
	for weapon in [1,3]:
		for buffered in [false,true]:
			setup(weapon)
			p.position = Vector2(130,720)
			p.burrowed = true
			p.collision_mask = 0
			enemy.position = Vector2(150,682)
			check(p.combat.start() and p.combat.mode==p.combat.Mode.BURROW,"burrow launcher starts: %d" % weapon)
			step(18)
			check(enemy.knocked and enemy.velocity.y<0,"burrow launch retains knock-up: %d" % weapon)
			if buffered: check(p.combat.start(),"air follow-up buffers during rise: %d" % weapon)
			step(13)
			if not buffered:
				check(not p.combat.active and not p.is_on_floor(),"burrow recovery releases in air: %d" % weapon)
				check(p.combat.start(),"fresh J starts after launcher: %d" % weapon)
			check(p.combat.active and p.combat.mode==p.combat.Mode.AIR and p.combat.air.stage==1,"launcher chains into air hit one: %d buffered=%s" % [weapon,buffered])
	setup(2)
	p.combat.start()
	step(1)
	check(p.velocity.y>900 and p.combat.air.stage==1,"hammer drops immediately without somersault")
	step(150)
	check(not p.combat.active,"hammer impact recovers")
	setup(0)
	p.combat.start()
	step(18)
	p.start_dash()
	check(not p.combat.active and enemy.suspended==0,"dash cancels air attack and releases target")
	setup(0)
	p.position = Vector2(960,450)
	p.combat.start()
	p.combat.air.begin_stage(3)
	step(30)
	check(p.position.x<=1007,"sword teleport stops before solid wall")
	for weapon in [0,1,3]:
		setup(weapon)
		enemy.position = Vector2(1000,300)
		p.velocity.y = 300
		y = p.position.y
		p.combat.start()
		step(25)
		check(p.combat.air.hold_time>0 and absf(p.position.y-y)<0.1 and enemy.hit_count==0,"missed first air hit holds player: %d" % weapon)
		p.combat.start()
		step(19)
		y = p.position.y
		step(20)
		check(p.combat.air.stage==2 and absf(p.position.y-y)<0.1,"missed second air hit renews float: %d" % weapon)
		step(25)
		check(p.velocity.y>0,"gravity resumes after missed swing float: %d" % weapon)
	setup(0)
	var other = room.combat_targets[1]
	other.position = Vector2(700,390)
	p.combat.start()
	p.combat.air.begin_stage(3)
	step(28)
	check(enemy.hit_count==0 and other.hit_count==0,"throw and teleport do not deal early damage")
	step(25)
	check(enemy.stunned>0 and other.stunned>0,"delayed slash stuns every target along path")
	setup(0)
	p.position = Vector2(960,450)
	enemy.position = Vector2(1028,450)
	p.combat.start()
	p.combat.air.begin_stage(3)
	for i in 60: p.combat.tick(1.0/120)
	check(enemy.hit_count==0,"teleport damage cannot pass through wall")
	p.reset()
	check(not p.invulnerable and not p.combat.active,"reset clears dash and air combat")
	quit(failures)
