extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	await frames(20)
	room.try_portal()
	check(room.map_index == 0 and not room.transitioning,"Cannot use a distant portal")
	room.player.position = Vector2(1210,681)
	await frames(5)
	room.player.burrowed = true
	check(not room.can_enter(room.portals[0]),"Cannot enter while burrowed")
	room.player.burrowed = false
	room.player.health = 80
	Input.action_press("portal")
	await create_timer(0.6).timeout
	check(room.map_index == 1 and not room.transitioning,"Portal input enters next map")
	check(room.blocks.size() == 4 and room.combat_targets.size() == 5,"Next map loads its own terrain and mobs")
	check(room.player.health == 80,"Transition preserves health")
	check(room.portals[0].destination == 0 and room.portals[0].position.x < 100,"Return portal leads back")
	await create_timer(0.2).timeout
	check(room.map_index == 1,"Held portal key does not bounce back")
	Input.action_release("portal")
	var old_marker: Vector2 = room.minimap.project(room.player.position)
	room.player.position.x += 100
	check(room.minimap.project(room.player.position).x > old_marker.x,"Minimap follows world movement")
	check(room.minimap.project(Vector2(1280,800)).is_equal_approx(Vector2(246,151)),"Minimap world bounds project correctly")
	room.player.position = Vector2(70,681)
	room.player.velocity = Vector2.ZERO
	await frames(5)
	Input.action_press("portal")
	await create_timer(0.6).timeout
	Input.action_release("portal")
	check(room.map_index == 0 and room.blocks.size() == 3 and room.combat_targets.size() == 4,"Return restores first map without duplicate mobs")
	check(room.player.position.x > 1100,"Return arrives beside the original exit")
	print("Forest portals: %d failures" % failures)
	quit(failures)

func frames(count: int) -> void:
	for frame in count:
		await physics_frame

func check(passed: bool, description: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL",description])
	if not passed:
		failures += 1
