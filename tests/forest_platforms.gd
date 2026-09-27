extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for mob in room.combat_targets:
		mob.set_physics_process(false)
	var p: CharacterBody2D = room.player
	p.position = Vector2(500,681)
	await frames(15)
	Input.action_press("jump")
	await frames(28)
	Input.action_release("jump")
	await frames(1)
	Input.action_press("jump")
	await frames(100)
	Input.action_release("jump")
	check(p.is_on_floor() and absf(p.position.y+19-555)<2,"Jump from directly below and land on platform")
	Input.action_press("dig")
	await frames(2)
	check(p.is_on_floor() and not p.burrowed,"Down alone does not drop or burrow on platform")
	Input.action_press("jump")
	await frames(2)
	check(p.drop_timer>0 and p.velocity.y>0 and not p.is_on_floor(),"Down plus jump drops through current platform")
	Input.action_release("jump")
	await frames(85)
	check(p.is_on_floor() and absf(p.position.y+19-700)<2 and not p.burrowed,"Main ground stays solid; held Down does not auto-burrow")
	check(p.get_collision_exceptions().is_empty(),"Collision exception clears after drop")
	Input.action_release("dig")
	await frames(2)
	Input.action_press("dig")
	await frames(4)
	check(p.burrowed,"Re-pressing Down on ground still burrows")
	Input.action_release("dig")
	p.reset()
	# A lower platform remains solid while only the upper one is ignored.
	var lower := preload("res://scripts/forest_terrain.gd").new()
	lower.position = Vector2(400,625)
	lower.width = 240
	lower.one_way = true
	room.add_child(lower)
	p.position = Vector2(500,536)
	await frames(15)
	Input.action_press("dig")
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	await frames(60)
	check(p.is_on_floor() and absf(p.position.y+19-625)<2,"Drop lands on lower platform rather than ignoring all platforms")
	Input.action_release("dig")
	await frames(2)
	Input.action_press("dig")
	Input.action_press("jump")
	await frames(2)
	p.reset()
	check(p.get_collision_exceptions().is_empty() and p.drop_timer==0,"Reset clears pending drop")
	Input.action_release("dig")
	Input.action_release("jump")
	print("Forest one-way platforms: %d failures" % failures)
	quit(failures)

func frames(count: int) -> void:
	for frame in count:
		await physics_frame

func check(passed: bool, description: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL",description])
	if not passed:
		failures += 1
