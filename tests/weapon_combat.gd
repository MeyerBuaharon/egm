extends SceneTree
var failures := 0
var room: Node2D
var p: CharacterBody2D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ")+label)
	if not ok: failures += 1
func ticks(n: int) -> void:
	for i in n:
		await physics_frame
		await process_frame
func setup(weapon: int, at: Vector2, underground := false) -> void:
	p.reset()
	for enemy in room.combat_targets: enemy.reset()
	p.position = at
	p.combat.selected = weapon
	p.facing = 1
	if underground:
		p.burrowed = true
		p.position.y = 725
		p.collision_mask = 0
func run() -> void:
	room = load("res://main.tscn").instantiate()
	root.add_child(room)
	p = room.player
	await ticks(10)
	setup(0,Vector2(305,681),true)
	check(p.combat.start(),"sword attack starts from burrow")
	check(not p.burrowed and p.collision_mask == 1 and p.air_jump,"burrow attack restores collisions and air jump")
	var start: Vector2 = p.position
	Input.action_press("left")
	Input.action_press("jump")
	Input.action_press("dig")
	await ticks(35)
	check(p.position.x>start.x+40 and p.position.x<start.x+110 and p.facing==1,"sword burst goes forward with locked direction")
	check(not p.burrowed and p.position.y>650,"attack blocks jump and dig")
	check(room.combat_targets[0].stunned>0 and room.combat_targets[0].hit_count==1,"sword stuns once per attack")
	for a in ["left","jump","dig"]: Input.action_release(a)
	await ticks(180)
	check(not p.combat.active and room.combat_targets[0].stunned==0,"attack and stun recover")
	for weapon in [1,3]:
		setup(weapon,Vector2(550,681),true)
		p.combat.start()
		await ticks(12)
		check(p.velocity.y<0 and room.combat_targets[1].velocity.y<0,"axe/spear launches player and enemy: %d" % weapon)
	setup(2,Vector2(540,681),true)
	p.combat.start()
	await ticks(100)
	check(room.combat_targets[1].buried>0,"hammer buries ground enemy after slam")
	await ticks(280)
	check(room.combat_targets[1].buried==0,"buried enemy recovers after timer")
	setup(2,Vector2(460,454))
	await ticks(4)
	p.velocity.x = 180
	p.combat.start()
	await ticks(150)
	check(room.combat_targets[2].position.y>680 and room.combat_targets[2].buried>0,"hammer knocks platform enemy to main floor then buries it")
	setup(0,Vector2(1030,725),true)
	check(not p.combat.start() and p.burrowed,"blocked burrow exit cannot attack through wall")
	setup(0,Vector2(1230,681))
	p.velocity.x = 180
	p.combat.start()
	await ticks(40)
	check(p.position.x<=1237,"sword dash respects wall collision")
	p.reset()
	check(not p.combat.active,"reset clears combat")
	quit(failures)
