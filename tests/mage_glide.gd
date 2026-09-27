extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for mob in room.combat_targets:
		mob.set_physics_process(false)
	room.select_class(2)
	await frames(20)
	var p: CharacterBody2D = room.player
	check(p.appearance.get_child(1).visible and not p.appearance.get_child(2).visible and p.appearance.pose=="Hover","Complete full-body mage renderer hovers; cutout renderer is hidden")
	check(p.appearance.lift.y < -10 and p.is_on_floor(),"Visual hover keeps grounded collision")
	Input.action_press("right")
	await frames(65)
	var phase: float = p.appearance.phase
	await frames(20)
	check(p.velocity.x>200 and p.velocity.x<=p.mage_glide_speed+1 and p.appearance.pose=="Glide","Movement reaches controlled glide speed")
	check(p.appearance.phase==phase and p.appearance.feet[0].y<0 and p.appearance.feet[1].y<0,"Feet trail without a running cycle")
	check(room.dust.is_empty(),"Gliding creates no footstep dust")
	Input.action_release("right")
	await frames(45)
	check(absf(p.velocity.x)<1 and p.appearance.pose=="Hover","Glide brakes back into hover")
	Input.action_press("left")
	await frames(40)
	check(p.facing<0 and p.appearance.pose=="Glide","Gliding also works facing left")
	Input.action_release("left")
	await frames(40)
	Input.action_press("jump")
	await frames(8)
	check(p.velocity.y<0 and p.appearance.pose=="Float rise","Jump uses floating airborne pose")
	Input.action_release("jump")
	await frames(110)
	Input.action_press("dig")
	await frames(10)
	check(p.burrowed,"Mage burrow remains functional")
	Input.action_release("dig")
	await frames(50)
	check(not p.burrowed and p.velocity.y<0,"Mage charges then erupts upward")
	await frames(120)
	room.select_class(0)
	check(p.appearance.class_index==0,"Warden remains selectable")
	print("Mage glide: %d failures" % failures)
	quit(failures)

func frames(count: int) -> void:
	for frame in count:
		await physics_frame
		await process_frame

func check(passed: bool, description: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL",description])
	if not passed:
		failures += 1
