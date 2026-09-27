extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for mob in room.combat_targets:
		mob.set_physics_process(false)
	await frames(20)
	var p: CharacterBody2D = room.player
	p.set_physics_process(false)
	check(p.combat.start() and p.stamina==88,"Attack spends stamina")
	for i in 20:
		p.combat.tick(1.0/120)
	check(p.combat.start() and p.stamina==88,"Queue does not charge before next swing")
	for i in 60:
		p.combat.tick(1.0/120)
		if p.combat.combo_index==2:
			break
	check(p.combat.combo_index==2 and p.stamina==76,"Second combo hit spends once")
	check(room.action_hud.attack_status().hit==2 and room.action_hud.attack_status().remaining>0,"HUD tracks actual combo and recovery")
	p.combat.cancel()
	p.stamina = 5
	check(not p.combat.start() and not p.start_dash() and p.stamina==5,"Insufficient stamina blocks attack and dash")
	p.reset()
	check(p.start_dash() and p.stamina==80,"Dash spends stamina")
	p.reset()
	p.stamina = 40
	p.stamina_regen_wait = 0.9
	p.tick_resources(0.4)
	check(p.stamina==40,"Regeneration waits after spending")
	p.tick_resources(0.6)
	check(p.stamina>40,"Stamina recovers while idle")
	p.reset()
	p.velocity = Vector2(0,1)
	p.move_and_slide()
	Input.action_press("dig")
	p._physics_process(1.0/120)
	check(p.burrowed and p.stamina==90,"Burrow entry costs stamina")
	for i in 120:
		p._physics_process(1.0/120)
	check(p.stamina<77 and p.stamina>75,"Burrow drains over duration")
	p.stamina = 0.01
	p._physics_process(1.0/120)
	check(not p.burrowed and p.burrow_cooldown>1.9,"Exhaustion forces emergence and cooldown")
	p.stamina = 100
	p.position = Vector2(130,681)
	p.velocity = Vector2(0,1)
	p.move_and_slide()
	p._physics_process(1.0/120)
	check(not p.burrowed and p.stamina==100,"Burrow cannot restart during recharge")
	Input.action_release("dig")
	check(not p.spend_mana(101) and p.spend_mana(25) and p.mana==75,"MP spending validates amount")
	p.tick_resources(1)
	check(p.mana>75 and p.mana<=p.max_mana,"MP regenerates within maximum")
	p.reset()
	p.position = Vector2(130,400)
	p.velocity = Vector2.ZERO
	p.move_and_slide()
	check(p.combat.start() and p.stamina==88,"First air attack spends stamina")
	p.combat.air.begin_stage(2)
	check(p.stamina==76,"Second air combo stage spends stamina")
	p.stamina = 2
	check(not p.combat.air.begin_stage(3) and not p.combat.active and p.stamina==2,"Unaffordable air finisher ends safely")
	var enemy: Node2D = room.combat_targets[0]
	enemy.regular_hit(100)
	enemy._physics_process(0.01)
	enemy._physics_process(0.01)
	check(room.experience==25,"Kill awards XP exactly once")
	for i in 3:
		room.award_mob_xp()
	check(room.character_level==2 and room.experience==0 and room.experience_needed==150,"XP bar advances level and threshold")
	p.stamina = 43
	p.mana = 61
	await room.change_map(1)
	check(p.stamina==43 and p.mana==61 and room.character_level==2,"Map transition preserves resources and progression")
	print("Forest resources: %d failures" % failures)
	quit(failures)

func frames(count: int) -> void:
	for frame in count:
		await physics_frame

func check(passed: bool, description: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL",description])
	if not passed:
		failures += 1
