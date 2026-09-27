extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	check(room.combat_targets.size() == 4,"Four independent mobs")
	for mob in room.combat_targets:
		mob.position.x = mob.patrol.x + 1
		mob.direction = -1
	await frames(150)
	for mob in room.combat_targets:
		check(mob.direction > 0 and mob.position.x >= mob.patrol.x and mob.position.x <= mob.patrol.y,"Turns at patrol edge")
		check(absf(mob.position.y - mob.spawn.y) < 1,"Keeps feet on supporting platform")
		check(mob.walk_distance > 10 and mob.sprite.sprite_frames.get_frame_count("default") == 4,"Walk animation advances")
	var enemy: Node2D = room.combat_targets[0]
	room.player.position = enemy.position + Vector2(-45,-1)
	room.player.combat.strike(enemy.hit_rect())
	check(enemy.health == 30,"Warden strike damages mob")
	enemy.receive(0,1,0.5,0)
	var stopped_at: Vector2 = enemy.position
	await frames(25)
	check(absf(enemy.position.x-stopped_at.x)<1,"Sword stun stops patrol")
	enemy.regular_hit(100)
	await frames(2)
	check(enemy.visible and enemy.hit_rect().size == Vector2.ZERO and enemy.death_time >= 0,"Defeated mob plays death without interacting")
	await frames(190)
	check(not enemy.visible,"Death animation finishes and fades out")
	enemy.reset()
	check(enemy.visible and enemy.health == 40 and enemy.position == enemy.spawn,"Reset restores mob")
	print("Forest mobs: %d failures" % failures)
	quit(failures)

func frames(count: int) -> void:
	for frame in count:
		await physics_frame

func check(passed: bool, description: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL",description])
	if not passed:
		failures += 1
