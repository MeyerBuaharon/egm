extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var room: Node2D=load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	room.load_map(2)
	room.select_class(1)
	var p: CharacterBody2D=room.player
	for slot in 7: p.equipment.pickup(1,slot)
	room.progress.points=3
	room.progress.embers=30
	for id in ["edge","siphon","bark"]: room.progress.buy(id)
	p.position=Vector2(700,681)
	var deaths := 0
	var was_near := false
	var frame := 0
	for i in 5400:
		frame=i
		if room.progress.boss_defeated: break
		Input.action_release("jump")
		Input.action_release("flourish")
		Input.action_release("left")
		Input.action_release("right")
		if p.position.x<300 and was_near:
			deaths+=1
			was_near=false
		if p.position.x>800: was_near=true
		if p.position.x<925: Input.action_press("right")
		elif p.position.x>950: Input.action_press("left")
		else: p.facing=1
		var danger := false
		for hazard in get_nodes_in_group("boss_hazards"):
			if not hazard.fired and hazard.warning-hazard.age<0.45 and absf(p.position.x-hazard.position.x)<hazard.radius+18:
				danger=true
		if danger and i%8==0: Input.action_press("jump")
		if i%12==0: Input.action_press("flourish")
		if p.health<65: p.use_gem(1)
		if p.position.distance_to(room.boss.position)<120: p.use_gem(0)
		await physics_frame
	for action in ["left","right","jump","flourish"]: Input.action_release(action)
	var won: bool=room.progress.boss_defeated
	print("%s live-input boss encounter: %.1fs simulated, %d deaths, player HP %d, boss HP %d" % ["PASS" if won else "FAIL",frame/60.0,deaths,p.health,room.boss.health])
	quit(0 if won else 1)
