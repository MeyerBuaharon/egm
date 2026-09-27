extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var room: Node2D = load("res://forest_slice.tscn").instantiate()
	root.add_child(room)
	await physics_frame
	room.player.set_physics_process(false)
	for mob in room.combat_targets:
		mob.set_physics_process(false)
	var enemy: Node2D = room.combat_targets[0]
	prepare(room,enemy)
	step(enemy,20)
	enemy._process(0)
	check(enemy.attack_time > 0 and room.player.health == 100 and enemy.sprite.animation == "attack","Visible wind-up before damage")
	step(enemy,22)
	check(room.player.health == 90 and enemy.sprite.sprite_frames.get_frame_count("attack") == 3,"Swipe deals damage at strike phase")
	step(enemy,35)
	check(room.player.health == 90,"Only one damage event per swipe")
	prepare(room,enemy)
	step(enemy,15)
	enemy.regular_hit()
	enemy._process(0)
	check(enemy.attack_time < 0 and enemy.hurt_timer > 0 and enemy.sprite.animation == "hurt","Player hit interrupts attack and plays recoil")
	step(enemy,50)
	check(room.player.health == 100,"Interrupted attack deals no damage")
	prepare(room,enemy)
	step(enemy,20)
	room.player.position.x = enemy.position.x - 40
	step(enemy,22)
	check(room.player.health == 100,"Attack stays committed to original facing")
	prepare(room,enemy)
	room.player.dash_time = 1
	step(enemy,45)
	check(room.player.health == 100,"Dash avoids swipe damage")
	prepare(room,enemy)
	room.player.burrowed = true
	step(enemy,45)
	check(enemy.attack_time < 0 and room.player.health == 100,"Burrowed player is not attacked")
	prepare(room,enemy)
	room.player.position.y -= 150
	step(enemy,45)
	check(enemy.attack_time < 0 and room.player.health == 100,"Does not attack across platform heights")
	print("Rootling combat: %d failures" % failures)
	quit(failures)

func prepare(room: Node2D, enemy: Node2D) -> void:
	room.player.reset()
	enemy.reset()
	room.player.position = enemy.position + Vector2(40,0)

func step(enemy: Node2D, count: int) -> void:
	for i in count:
		enemy._physics_process(1.0/120.0)

func check(passed: bool, description: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL",description])
	if not passed:
		failures += 1
