extends "res://scripts/skirmisher_combat.gd"
func combo_duration() -> float:
	if mode==Mode.BURROW: return 0.6
	var speeds: Array=[0.36,0.42,0.58]
	if not wildborn and style==3: speeds=[0.48,0.56,0.72]
	if wildborn and style==3: speeds=[0.44,0.54,0.66]
	return speeds[clampi(combo_index-1,0,2)]
func start() -> bool:
	var already := active
	var result := super.start()
	if result and not already and wildborn and style==3 and mode!=Mode.BURROW:
		if combo_index==1: actor.velocity=Vector2(direction*320,-190)
		elif combo_index==2: actor.velocity=Vector2(direction*160,-480)
		else: actor.velocity=Vector2(direction*240,560)
		aerial=true
	return result
func tick(dt: float) -> void:
	time+=dt
	actor.facing=direction
	if mode==Mode.BURROW and not released: actor.velocity=Vector2.ZERO
	else:
		actor.velocity.x=move_toward(actor.velocity.x,0,(180 if wildborn and style==3 else 1000)*dt)
		actor.velocity.y=minf(actor.velocity.y+actor.gravity*(0.28 if aerial and combo_index<3 else 1.0)*dt,1100)
		actor.move_and_slide()
	if not released and time>=combo_duration()*0.36:
		released=true
		if mode==Mode.BURROW: erupt()
		else: strike_style()
	actor.state="%s · %d/3" % [actor.world.current_item().name,combo_index]
	if time>=combo_duration():
		var follow := queued
		active=false
		queued=false
		if mode==Mode.BURROW: combo_index=0
		combo_window=0.7 if combo_index<3 else 0
		if follow and combo_window>0: start()
func projectile(kind: String, angle: float, damage: int, status: String="") -> void:
	var shot := preload("res://scripts/class_sandbox/projectile.gd").new()
	shot.actor=actor
	shot.position=actor.position+Vector2(direction*26,-26)
	shot.velocity=Vector2(direction*600,0).rotated(angle)
	shot.damage=damage
	shot.kind=kind
	shot.status=status
	actor.world.add_child(shot)
func strike_style() -> void:
	if not wildborn and style in [1,2]:
		var kind := "dart" if style==1 else "star"
		var count := combo_index if style==2 else (2 if combo_index==2 else 1)
		for i in count: projectile(kind,(i-(count-1)*0.5)*0.14,12 if combo_index==3 else 7,"poison" if style==1 else "")
		if style==1:
			for enemy in actor.world.combat_targets:
				if enemy.health>0 and enemy.position.distance_to(actor.position)<48:
					enemy.regular_hit(5)
					enemy.apply_ailment("poison",4.0,2)
		return
	if wildborn and style==1:
		for i in combo_index: projectile("thorn",(i-(combo_index-1)*0.5)*0.18,8)
		return
	var reach := 82.0
	if not wildborn and style==3: reach=185 if combo_index==3 else 155
	if wildborn and style==2: reach=180
	if wildborn and style==3: reach=100
	var origin: Vector2=actor.position+Vector2(0,-20)
	var box := Rect2(origin+Vector2(-reach if direction<0 else 0,-55),Vector2(reach,110))
	for enemy in actor.world.combat_targets:
		if enemy.health<=0 or not box.intersects(enemy.hit_rect()) or not clear_path(origin,enemy.position): continue
		enemy.regular_hit([8,10,16][clampi(combo_index-1,0,2)])
		if not wildborn and style==0: enemy.apply_ailment("bleed",3,2)
		if not wildborn and style==3 and combo_index==3: enemy.stunned=1.0
		if wildborn and style==2:
			enemy.apply_ailment("root",1.2 if combo_index<3 else 2.5,0)
			if combo_index==2:
				pull_target(enemy,actor.position.x+direction*45,95)
			if combo_index==3: enemy.buried=1.5
		if wildborn and style==3:
			enemy.knocked=true
			enemy.velocity=Vector2(direction*100,560 if combo_index==3 else -400)
		actor.feedback.emit("regular_hit",enemy.position)
	actor.world.flash_effect(origin,"roots" if wildborn and style==2 else ("whip" if not wildborn and style==3 else "claw"),reach,direction)
func erupt() -> void:
	actor.burrowed=false
	actor.burrow_exit_requested=false
	actor.begin_burrow_cooldown()
	actor.collision_mask=1
	actor.position=Vector2(eruption_origin.x,actor.FLOOR_Y-actor.HALF_HEIGHT-2)
	actor.velocity=Vector2(direction*(180 if wildborn and style==3 else 90),-640)
	actor.air_jump=true
	actor.jump_buffer=0
	actor.feedback.emit("emerge",eruption_origin)
	for enemy in actor.world.combat_targets:
		if enemy.health<=0 or enemy.position.distance_to(eruption_origin)>160 or not clear_path(eruption_origin,enemy.position): continue
		enemy.regular_hit(16)
		if wildborn and style==2:
			pull_target(enemy,eruption_origin.x,70)
			enemy.apply_ailment("root",2.5,0)
			enemy.buried=2.0
			if "half_buried" in enemy: enemy.half_buried=true
		else:
			enemy.knocked=true
			enemy.velocity=Vector2(direction*70,-450)
			if not wildborn and style==0: enemy.apply_ailment("bleed",3,3)
			if not wildborn and style==1: enemy.apply_ailment("poison",4,3)
	if (not wildborn and style in [1,2]) or (wildborn and style==1):
		for angle in [-0.6,-0.3,0.0,0.3,0.6]:
			projectile("thorn" if wildborn else ("dart" if style==1 else "star"),angle,8,"poison" if not wildborn and style==1 else "")
	actor.world.flash_effect(eruption_origin,"roots" if wildborn else "whip",145,direction)

func pull_target(enemy: Node2D, destination: float, distance: float) -> void:
	var pull := enemy.create_tween()
	pull.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	pull.tween_property(enemy,"position:x",move_toward(enemy.position.x,destination,distance),0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
