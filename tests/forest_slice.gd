extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	for rect in room.blocks:
		room.player.reset()
		room.player.position = Vector2(rect.get_center().x,rect.position.y - 90)
		await frames(65)
		check(room.player.is_on_floor() and absf(room.player.position.y + 19 - rect.position.y) < 2,"Feet align with terrain surface")
	room.player.reset()
	await frames(30)
	Input.action_press("right")
	var has_dust := false
	for frame in 65:
		await physics_frame
		has_dust = has_dust or not room.dust.is_empty()
	Input.action_release("right")
	check(has_dust,"Walking emits dust")
	room.player.reset()
	await frames(15)
	Input.action_press("dig")
	await frames(45)
	check(room.player.burrowed and room.player.collision_mask == 0,"Hold S enters ground")
	var buried_x: float = room.player.position.x
	Input.action_press("right")
	await frames(30)
	Input.action_release("right")
	check(room.player.position.x > buried_x + 20,"Burrow moves underground")
	Input.action_release("dig")
	await frames(2)
	check(not room.player.burrowed and room.player.collision_mask == 1 and room.player.velocity.y < 0,"Release S emerges upward")
	# Exercise double jumps at the actual controller speed and physics rate.
	room.player.reset()
	room.player.position = Vector2(310,681)
	await frames(12)
	await jump_across(room,36,80,true)
	check(room.player.is_on_floor() and absf(room.player.position.y + 19 - 555) < 2,"First platform reachable")
	room.player.velocity = Vector2.ZERO
	room.player.position = Vector2(650,536)
	await frames(12)
	await jump_across(room,36,110)
	check(room.player.is_on_floor() and absf(room.player.position.y + 19 - 425) < 2,"Second platform reachable")
	print("Forest slice: %d failures" % failures)
	quit(failures)

func jump_across(_room: Node2D, delay: int, travel: int, delay_horizontal := false) -> void:
	Input.action_press("jump")
	if not delay_horizontal:
		Input.action_press("right")
	await frames(delay)
	Input.action_release("jump")
	await frames(1)
	Input.action_press("jump")
	Input.action_press("right")
	await frames(travel)
	Input.action_release("jump")
	Input.action_release("right")
	await frames(40)

func frames(count: int) -> void:
	for frame in count:
		await physics_frame

func check(passed: bool, description: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL",description])
	if not passed:
		failures += 1
