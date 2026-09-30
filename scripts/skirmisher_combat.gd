extends "res://scripts/warden_combat.gd"

var wildborn := false
var style := 0
var aerial := false
var released := false
var pulses := 0
var eruption_origin := Vector2.ZERO
const COLORS := [Color("ef6688"),Color("9cdc65"),Color("b795f2"),Color("f5d18b")]

func select_style(index: int) -> bool:
	if active or index<0 or index>3: return false
	cancel()
	style=index
	return true

func start() -> bool:
	if actor.dash_time>0: return false
	if active:
		if queued or time<0.08 or (combo_index>=3 and mode!=Mode.BURROW): return false
		if not actor.can_pay_stamina(attack_cost()): return false
		queued=true
		return true
	var underground: bool=actor.burrowed
	if underground:
		var exit_rect := Rect2(actor.position.x-13,actor.FLOOR_Y-40,26,38)
		for block in actor.world.blocks:
			if block.intersects(exit_rect): return false
	if not actor.spend_stamina(22.0 if underground else attack_cost()): return false
	combo_index=1 if underground or combo_window<=0 or combo_index>=3 else combo_index+1
	mode=Mode.BURROW if underground else Mode.REGULAR
	aerial=not actor.is_on_floor() and not underground
	active=true
	queued=false
	released=false
	pulses=0
	time=0
	combo_window=0
	direction=actor.facing
	hits.clear()
	eruption_origin=Vector2(actor.position.x,actor.FLOOR_Y-20)
	if aerial: actor.velocity.y=minf(actor.velocity.y,-80)
	return true

func attack_cost() -> float:
	return 11.0 if wildborn else (7.0 if style==3 else 9.0)

func combo_duration() -> float:
	if mode==Mode.BURROW: return 0.62 if wildborn else 0.48
	var durations := [0.46,0.50,0.65] if wildborn else ([0.27,0.30,0.38] if style==3 else [0.34,0.38,0.50])
	return durations[clampi(combo_index-1,0,2)]

func animation_frame() -> int:
	var u := time/combo_duration()
	return 0 if u<0.36 else (1 if u<0.67 else 2)

func tick(dt: float) -> void:
	time+=dt
	actor.facing=direction
	if mode==Mode.BURROW and not released:
		actor.velocity=Vector2.ZERO
	else:
		actor.velocity.x=move_toward(actor.velocity.x,0,1000*dt)
		actor.velocity.y=minf(actor.velocity.y+actor.gravity*(0.35 if aerial and combo_index<3 else 1.0)*dt,1100)
		actor.move_and_slide()
	if not released and time>=combo_duration()*0.36:
		released=true
		if mode==Mode.BURROW: erupt()
		else: strike_style()
	# Flurry has three distinct, deliberately low-damage contacts per swing.
	if not wildborn and style==3 and mode==Mode.REGULAR and released:
		var wanted := mini(2,int(maxf(0,time/combo_duration()-0.36)/0.13))
		while pulses<wanted:
			pulses+=1
			hits.clear()
			strike_style()
	actor.state="%s %s %d/3" % [preload("res://scripts/class_roster.gd").STYLES[3 if wildborn else 1][style],"Ambush" if mode==Mode.BURROW else ("Air" if aerial else "Combo"),combo_index]
	if time>=combo_duration():
		var follow := queued
		active=false
		queued=false
		if mode==Mode.BURROW: combo_index=0
		combo_window=0.5 if combo_index<3 else 0
		if follow and combo_window>0: start()

func strike_style() -> void:
	var origin: Vector2=actor.position+Vector2(direction*22,-30)
	if wildborn and style==1:
		var aim := Vector2(direction,0)
		var closest := 600.0
		for enemy in actor.world.combat_targets:
			var delta: Vector2=enemy.position+Vector2(0,-8)-origin
			if enemy.health>0 and delta.x*direction>0 and absf(delta.y)<110 and delta.length()<closest:
				closest=delta.length()
				aim=delta.normalized()
		for angle in ([-0.16,0.0,0.16] if combo_index==3 else [0.0]):
			var thorn := preload("res://scripts/thorn_projectile.gd").new()
			thorn.actor=actor
			thorn.position=origin
			thorn.velocity=(aim*520).rotated(angle)
			thorn.damage=8 if combo_index<3 else 6
			actor.world.add_child(thorn)
		add_effect(origin,"thorns",COLORS[1],42)
		return
	var reach := 85.0 if wildborn else (105.0 if style==2 else 68.0)
	if combo_index==3: reach+=20
	var box := Rect2(actor.position+Vector2(-reach if direction<0 else 0,-70),Vector2(reach,100))
	for enemy in actor.world.combat_targets:
		if enemy.health<=0 or enemy in hits or not box.intersects(enemy.hit_rect()): continue
		if not clear_path(origin,enemy.position): continue
		hits.append(enemy)
		var damage: int = [8,9,13][clampi(combo_index-1,0,2)] if wildborn else [6,7,10][clampi(combo_index-1,0,2)]
		if not wildborn and style==3: damage=3 if combo_index<3 else 4
		if not wildborn and style==2 and combo_index==3: damage=16
		enemy.regular_hit(damage)
		if enemy.has_method("apply_ailment"):
			if not wildborn and style==0: enemy.apply_ailment("bleed",3.0,2)
			elif not wildborn and style==1: enemy.apply_ailment("poison",4.0,2)
			elif wildborn and style==2: enemy.apply_ailment("root",1.2 if combo_index<3 else 2.5,0)
		if wildborn and style==3 and combo_index==3:
			enemy.knocked=true
			enemy.velocity=Vector2(direction*150,-420)
		elif aerial and combo_index<3:
			enemy.knocked=true
			enemy.velocity=Vector2(direction*30,-190)
		actor.feedback.emit("regular_hit",enemy.position)
	add_effect(origin,"claw" if wildborn else "slash",COLORS[style],reach)

func clear_path(from: Vector2, to: Vector2) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(from,to,1,[actor.get_rid()])
	return actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func erupt() -> void:
	actor.burrowed=false
	actor.burrow_exit_requested=false
	actor.begin_burrow_cooldown()
	actor.collision_mask=1
	actor.position=Vector2(eruption_origin.x,actor.FLOOR_Y-actor.HALF_HEIGHT-2)
	actor.velocity=Vector2(direction*(80 if wildborn else 160),-640)
	actor.air_jump=true
	actor.jump_buffer=0
	actor.feedback.emit("emerge",eruption_origin)
	for enemy in actor.world.combat_targets:
		if enemy.health<=0 or enemy.position.distance_to(eruption_origin)>145 or not clear_path(eruption_origin,enemy.position): continue
		enemy.regular_hit((14 if wildborn else 16)+(6 if not wildborn and style==2 else 0))
		if wildborn:
			if style==2:
				if enemy.has_method("apply_ailment"): enemy.apply_ailment("root",2.5,0)
				enemy.buried=2.0
				if "half_buried" in enemy: enemy.half_buried=true
				enemy.position.x=move_toward(enemy.position.x,eruption_origin.x,24)
			else:
				enemy.knocked=true
				enemy.velocity=Vector2(signf(enemy.position.x-eruption_origin.x)*(260 if style==3 else 60),-480 if style==0 else -240)
		else:
			enemy.knocked=true
			enemy.velocity=Vector2(direction*50,-420)
			if enemy.has_method("apply_ailment"):
				if style==0: enemy.apply_ailment("bleed",3.0,3)
				elif style==1: enemy.apply_ailment("poison",4.0,3)
		actor.feedback.emit("regular_hit",enemy.position)
	if wildborn and style==1:
		for angle in [-0.9,-0.45,0.0,0.45,0.9]:
			var thorn := preload("res://scripts/thorn_projectile.gd").new()
			thorn.actor=actor
			thorn.position=eruption_origin+Vector2(0,-25)
			thorn.velocity=Vector2(direction*520,-80).rotated(angle)
			thorn.damage=6
			actor.world.add_child(thorn)
	elif not wildborn and style==3:
		# A quick follow-up slash rewards an immediate airborne combo.
		actor.velocity.x=direction*300
		actor.velocity.y=-740
	add_effect(eruption_origin,"roots" if wildborn else "ambush",COLORS[style],145)

func add_effect(at: Vector2, kind: String, color: Color, radius: float) -> void:
	var effect := preload("res://scripts/skirmisher_effect.gd").new()
	effect.position=at
	effect.kind=kind
	effect.tint=color
	effect.radius=radius
	effect.facing=direction
	actor.world.add_child(effect)
