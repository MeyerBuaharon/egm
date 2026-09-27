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
	room.player.position = enemy.position+Vector2(35,0)
	enemy.attack_time = 0.3
	enemy.regular_hit(100)
	step(enemy,1)
	check(enemy.attack_time<0 and enemy.hit_rect().size==Vector2.ZERO,"Lethal hit cancels attack and hitbox")
	check(enemy.sprite.animation=="death" and enemy.sprite.frame==0,"Collapse begins with first pose")
	step(enemy,25)
	check(enemy.sprite.frame==1,"Second collapse pose plays")
	step(enemy,25)
	check(enemy.sprite.frame==2,"Fallen pose plays")
	step(enemy,25)
	check(enemy.sprite.frame==3 and enemy.visible,"Bark remains before fading")
	step(enemy,110)
	check(not enemy.visible and room.player.health==100,"Death fades out without dealing damage")
	enemy.reset()
	enemy._process(0)
	check(enemy.visible and enemy.sprite.animation=="default" and enemy.sprite.modulate.a==1,"Reset clears death state and opacity")
	enemy.position.y -= 120
	enemy.regular_hit(100)
	step(enemy,120)
	check(absf(enemy.position.y-enemy.spawn.y)<1,"Airborne corpse lands on ground")
	print("Rootling death: %d failures" % failures)
	quit(failures)

func step(enemy: Node2D, count: int) -> void:
	for i in count:
		enemy._physics_process(1.0/120.0)
		enemy._process(1.0/120.0)

func check(passed: bool, description: String) -> void:
	print("%s %s" % ["PASS" if passed else "FAIL",description])
	if not passed:
		failures += 1
