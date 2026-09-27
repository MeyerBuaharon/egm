extends Node2D

@export var float_duration := 0.32
@export var dive_speed := 1000.0
@export var throw_distance := 240.0
var combat: Node
var stage := 1
var time := 0.0
var waiting := false
var wait_time := 0.0
var queued := false
var hold_time := 0.0
var hit_targets: Array[Node] = []
var held_targets: Array[Node] = []
var pending_targets: Array[Node] = []
var dive_direction := Vector2.ZERO
var impacted := false
var recovery := 0.0
var teleported := false
var detonated := false
var path_start := Vector2.ZERO
var path_end := Vector2.ZERO
var sword_at := Vector2.ZERO
var fx_time := 0.0
var shock_time := 0.0

func start() -> bool:
	if not combat.actor.can_pay_stamina(combat.actor.attack_stamina_cost): return false
	combat.weapon = combat.selected
	combat.mode = combat.Mode.AIR
	combat.active = true
	combat.combo_window = 0
	combat.combo_index = 0
	combat.direction = combat.actor.facing
	combat.actor.jump_buffer = 0
	combat.actor.velocity.x = 0
	return begin_stage(1)

func begin_stage(next: int) -> bool:
	if not combat.actor.spend_stamina(combat.actor.attack_stamina_cost):
		end()
		return false
	stage = next
	time = 0
	waiting = false
	wait_time = 0
	queued = false
	hit_targets.clear()
	impacted = false
	recovery = 0
	teleported = false
	detonated = false
	if combat.weapon != 2 and stage < 3:
		# Air swings hold the player up even without a target to connect with.
		hold_time = float_duration
		combat.actor.velocity = Vector2.ZERO
	if combat.weapon == 2 or stage == 3:
		if combat.weapon == 0:
			# Keep connected combo targets aloft through the throw and delayed slash.
			for enemy in held_targets:
				if is_instance_valid(enemy): enemy.suspended = 0.42
		else:
			release_targets()
		dive_direction = Vector2(0,1) if combat.weapon == 2 else Vector2(combat.direction*0.6,0.8)
		if combat.weapon == 0:
			path_start = combat.actor.position
			path_end = path_start+Vector2(combat.direction*throw_distance,0)
			var ray := PhysicsRayQueryParameters2D.create(path_start,path_end,1,[combat.actor.get_rid()])
			var hit: Dictionary = combat.actor.get_world_2d().direct_space_state.intersect_ray(ray)
			if not hit.is_empty(): path_end = hit.position-Vector2(combat.direction*18,0)
			sword_at = path_start
	return true

func queue_next() -> bool:
	if combat.weapon == 2 or stage >= 3 or queued or time < 0.10: return false
	if not combat.actor.can_pay_stamina(combat.actor.attack_stamina_cost): return false
	if waiting:
		begin_stage(stage+1)
	else:
		queued = true
	return true

func release_targets() -> void:
	for enemy in held_targets:
		if is_instance_valid(enemy): enemy.suspended = 0
	held_targets.clear()
	hold_time = 0

func clear() -> void:
	release_targets()
	hit_targets.clear()
	pending_targets.clear()
	fx_time = 0
	shock_time = 0
	waiting = false

func end() -> void:
	release_targets()
	combat.active = false
	combat.combo_window = 0
	combat.combo_index = 0
	queued = false

func tick(dt: float) -> void:
	time += dt
	combat.time = time
	var actor: CharacterBody2D = combat.actor
	actor.facing = combat.direction
	actor.jump_buffer = 0
	actor.coyote = 0
	if combat.weapon == 0 and stage == 3:
		tick_teleport(dt)
	elif combat.weapon == 2 or stage == 3:
		tick_dive(dt)
	else:
		hold_time = maxf(0,hold_time-dt)
		if hold_time > 0:
			actor.velocity = Vector2.ZERO
		else:
			actor.velocity.x = 0
			actor.velocity.y = minf(actor.velocity.y+actor.gravity*dt,1000)
		actor.move_and_slide()
		if not waiting and time >= 0.10 and time < 0.25:
			air_hit()
		actor.state = "Air %d/2 · J follow-up" % stage
		if actor.is_on_floor():
			end()
		elif not waiting and time >= 0.36:
			if queued: begin_stage(stage+1)
			else: waiting = true
		elif waiting:
			wait_time += dt
			if wait_time >= 0.28: end()
	if actor.position.y > 900: actor.reset()
	actor.queue_redraw()
	queue_redraw()

func air_hit() -> void:
	var actor: CharacterBody2D = combat.actor
	var reach := 80.0
	var box := Rect2(actor.position+Vector2(-reach if combat.direction<0 else 0,-48),Vector2(reach,80))
	for enemy in actor.world.combat_targets:
		if enemy in hit_targets or not box.intersects(enemy.hit_rect()): continue
		var ray := PhysicsRayQueryParameters2D.create(actor.position,enemy.position,1,[actor.get_rid()])
		if not actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		hit_targets.append(enemy)
		enemy.regular_hit()
		hold_time = float_duration
		actor.velocity = Vector2.ZERO
		if stage == 2 and combat.weapon in [1,3]:
			enemy.suspended = 0
			held_targets.erase(enemy)
			enemy.knocked = true
			enemy.dropping = true
			enemy.bury_on_land = 0
			enemy.velocity = Vector2(combat.direction*360,480)
		else:
			enemy.velocity = Vector2.ZERO
			enemy.knocked = true
			enemy.suspended = float_duration
			if not enemy in held_targets: held_targets.append(enemy)
		actor.feedback.emit("regular_hit",enemy.position)

func tick_dive(dt: float) -> void:
	var actor: CharacterBody2D = combat.actor
	actor.state = "Hammer drop-slam" if combat.weapon == 2 else "Spear / axe missile dive"
	if not impacted:
		actor.velocity = dive_direction*dive_speed
		var old := actor.position
		actor.move_and_slide()
		var box := Rect2(old-Vector2(24,24),Vector2(48,48)).expand(actor.position+Vector2(24,24)).expand(actor.position-Vector2(24,24))
		dive_hit(box)
		if actor.get_slide_collision_count()>0 or time>1.5:
			impacted = true
			actor.velocity = Vector2.ZERO
			dive_hit(Rect2(actor.position-Vector2(85,45),Vector2(170,100)))
			actor.feedback.emit("air_impact",actor.position)
	else:
		actor.velocity = Vector2.ZERO
		recovery += dt
		if recovery > 0.20: end()

func dive_hit(box: Rect2) -> void:
	var actor: CharacterBody2D = combat.actor
	for enemy in actor.world.combat_targets:
		if enemy in hit_targets or not box.intersects(enemy.hit_rect()): continue
		var ray := PhysicsRayQueryParameters2D.create(actor.position,enemy.position,1,[actor.get_rid()])
		if not actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		hit_targets.append(enemy)
		if combat.weapon == 2: enemy.receive(2,combat.direction,0,combat.bury_duration)
		else:
			enemy.regular_hit(20)
			enemy.suspended = 0
			enemy.knocked = true
			enemy.dropping = true
			enemy.bury_on_land = 0
			enemy.velocity = Vector2(combat.direction*120,700)

func tick_teleport(_dt: float) -> void:
	var actor: CharacterBody2D = combat.actor
	actor.velocity = Vector2.ZERO
	actor.state = "Throw → blink → sheathe"
	sword_at = path_start.lerp(path_end,clampf(time/0.16,0,1))
	if time >= 0.18 and not teleported:
		teleported = true
		var motion := path_end-actor.position
		var collision: KinematicCollision2D = actor.move_and_collide(motion,true)
		if collision: motion = collision.get_travel()
		actor.position += motion
		path_end = actor.position
		sword_at = path_end
		fx_time = 0.22
		pending_targets.clear()
		for enemy in actor.world.combat_targets:
			var closest := Geometry2D.get_closest_point_to_segment(enemy.position,path_start,path_end)
			if enemy.position.distance_to(closest)<=34:
				var ray := PhysicsRayQueryParameters2D.create(closest,enemy.position,1,[actor.get_rid()])
				if actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): pending_targets.append(enemy)
	if time >= 0.40 and not detonated:
		detonated = true
		release_targets()
		for enemy in pending_targets:
			if is_instance_valid(enemy):
				enemy.receive(0,combat.direction,combat.stun_duration,0)
				enemy.health = maxi(0,enemy.health-10)
		actor.feedback.emit("sword_shockwave",path_end)
		fx_time = 0.18
		shock_time = 0.25
	if time >= 0.64: end()

func art_frame() -> int:
	if combat.weapon == 2: return 11 if impacted else 10
	if stage == 3: return combat.weapon*4+(3 if impacted else 1)
	var phase := 0 if time<0.10 else (1 if time<0.20 else (2 if stage==1 else 3))
	return combat.weapon*4+phase

func _process(dt: float) -> void:
	fx_time = maxf(0,fx_time-dt)
	shock_time = maxf(0,shock_time-dt)
	queue_redraw()

func _draw() -> void:
	if combat.active and combat.mode == combat.Mode.AIR and combat.weapon == 0 and stage == 3 and not teleported:
		var at := to_local(sword_at)
		var dir := Vector2(combat.direction,0)
		draw_line(at-dir*12,at+dir*20,Color("efffff"),3)
		draw_line(at-dir*8+Vector2(0,-5),at-dir*8+Vector2(0,5),Color("e6b661"),3)
	if fx_time>0:
		for i in 5:
			var offset := Vector2(0,(i-2)*5)
			var color := Color("fff0ed") if i == 2 else Color("ff183a")
			color.a = clampf(fx_time*4,0,1)
			draw_line(to_local(path_start)+offset,to_local(path_end)+offset,color,2 if i==2 else 1)
	if shock_time>0:
		draw_arc(to_local(path_end),12+(0.25-shock_time)*260,0,TAU,40,Color(1,0.12,0.23,shock_time*4),2)
