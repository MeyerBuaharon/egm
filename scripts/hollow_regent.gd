extends "res://scripts/combat_dummy.gd"
signal defeated
const ART = preload("res://assets/mobs/hollow-regent.png")
const MAX_HEALTH := 480
var state := "idle"
var timer := 1.2
var sequence := 0
var engaged := false
var enraged := false
var death_time := -1.0
var frozen := 0.0
var burning := 0.0
var burn_tick := 0.0
var pivot: Node2D
var sprite: Sprite2D
var tell := ""
func _ready() -> void:
	pivot=Node2D.new()
	pivot.position.y=18
	add_child(pivot)
	sprite=Sprite2D.new()
	sprite.texture=ART
	sprite.centered=false
	sprite.scale=Vector2.ONE*0.14
	sprite.position=Vector2(-ART.get_width()*0.07,-ART.get_height()*0.14)
	pivot.add_child(sprite)
	reset()
func reset() -> void:
	max_health=MAX_HEALTH
	super.reset()
	health=MAX_HEALTH
	state="idle"
	timer=1.2
	sequence=0
	engaged=false
	enraged=false
	death_time=-1
	frozen=0
	burning=0
	burn_tick=0
	tell=""
	visible=true
	if is_instance_valid(pivot):
		pivot.rotation=0
		pivot.modulate=Color.WHITE
	if world.progress.boss_defeated:
		health=0
		death_time=3
		visible=false
func hit_rect() -> Rect2:
	return Rect2(position+Vector2(-62,-154),Vector2(124,172)) if health>0 else Rect2()
func regular_hit(amount: int = 10) -> void:
	if health<=0: return
	engaged=true
	super.regular_hit(amount)
	if health<=0: die()
func receive(_weapon: int, _direction: float, _stun_time: float, _bury_time: float) -> void:
	regular_hit()
	# A rooted boss resists launch/bury displacement; hits still deal damage.
func apply_element(element: int, _facing: float) -> void:
	if health<=0: return
	match element:
		0: burning=4.0
		1: frozen=0.7
		2,3: frozen=maxf(frozen,0.3)
func apply_ailment(kind: String, duration: float, damage: int) -> void:
	if kind=="root":
		frozen=maxf(frozen,0.4)
		return
	super.apply_ailment(kind,duration,damage)
func hazard(at: Vector2, width: float, delay: float, amount: int) -> void:
	var root := preload("res://scripts/boss_root.gd").new()
	root.world=world
	root.position=at
	root.radius=width
	root.warning=delay
	root.damage=amount
	root.wide=width>70
	world.add_child(root)
func choose_attack() -> void:
	sequence+=1
	if sequence%3==0:
		state="summon"
		tell="The roots awaken — reinforcements"
		timer=0.9
	elif sequence%2==0 and absf(world.player.position.x-position.x)<210:
		state="slam"
		tell="Ground slam — jump or retreat"
		timer=1.1 if not enraged else 0.85
		hazard(Vector2(position.x,700),180,timer,24)
	else:
		state="roots"
		tell="Root eruption — leave the marked ground"
		timer=1.15 if not enraged else 0.9
		var target: float=world.player.position.x
		for i in (5 if enraged else 3):
			var x := clampf(target+(i-(2 if enraged else 1))*100,80,1210)
			var ground := 700.0
			for block in world.blocks:
				if x>=block.position.x and x<=block.end.x and block.position.y>=world.player.position.y+17:
					ground=minf(ground,block.position.y)
			hazard(Vector2(x,ground),35,timer,18)
func summon() -> void:
	var alive := 0
	for mob in world.combat_targets:
		if mob!=self and mob.health>0: alive+=1
	for i in maxi(0,2-alive):
		var mob := preload("res://scripts/forest_mob.gd").new()
		mob.world=world
		mob.spawn=Vector2(680+i*130,682)
		mob.patrol=Vector2(280,1130)
		mob.speed=48
		mob.defeated.connect(world.award_mob_xp.bind(mob))
		world.add_child(mob)
		world.combat_targets.append(mob)
func die() -> void:
	if death_time>=0: return
	death_time=0
	state="dead"
	tell="The Hollow Regent falls"
	for root in get_tree().get_nodes_in_group("boss_hazards"):
		root.set_physics_process(false)
		root.queue_free()
	defeated.emit()
func _physics_process(dt: float) -> void:
	clock+=dt
	flash=maxf(0,flash-dt)
	if health<=0:
		if death_time<0: die()
		death_time+=dt
		pivot.rotation=minf(0.32,death_time*0.12)
		pivot.modulate.a=clampf(1-(death_time-0.8)/1.5,0,1)
		return
	tick_ailments(dt)
	if health<=0:
		die()
		return
	if burning>0:
		burn_tick+=minf(dt,burning)
		burning=maxf(0,burning-dt)
		while burn_tick>=0.5 and health>0:
			burn_tick-=0.5
			regular_hit(2)
	if health<=0: return
	if not engaged and world.player.position.x>530:
		engaged=true
		world.notify_player("The Hollow Regent · watch the marked ground")
	if health<=MAX_HEALTH/2 and not enraged:
		enraged=true
		world.notify_player("The Regent is enraged — eruptions spread wider")
	var step := dt*(0.5 if frozen>0 else 1.0)
	frozen=maxf(0,frozen-dt)
	pivot.modulate=Color(1.7,1.5,1.15) if flash>0 else (Color(0.6,0.85,1.15) if frozen>0 else Color.WHITE)
	pivot.rotation=sin(clock*1.7)*0.012
	if not engaged: return
	timer-=step
	if state!="idle": pivot.rotation=-sin(clampf(1-timer,0,1)*PI)*0.07
	if timer<=0:
		if state=="idle": choose_attack()
		else:
			if state=="summon": summon()
			state="idle"
			tell=""
			timer=1.35 if enraged else 1.9

func _draw() -> void:
	draw_set_transform(Vector2(0,16),0,Vector2(1,0.16))
	draw_circle(Vector2.ZERO,64,Color(0,0,0,0.35))
	draw_set_transform(Vector2.ZERO)
