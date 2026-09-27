extends "res://scripts/warden_combat.gd"

const ELEMENTS := ["Fire","Ice","Wind","Earth"]
const TINTS := [Color("ff9b46"),Color("80ddff"),Color("b1ecd4"),Color("d6ad65")]
const COSTS := [6.0,8.0,12.0]
const DURATIONS := [0.46,0.52,0.72]
var element := 0
var released := false
var aerial := false
var eruption_origin := Vector2.ZERO
const ERUPTION_COST := 18.0
const EFFECT_DURATION := 0.56
var effects: Array[Dictionary] = []

func select_element(index: int) -> bool:
	if active or index<0 or index>=4:
		return false
	cancel()
	element = index
	return true

func start() -> bool:
	if actor.dash_time>0:
		return false
	if actor.burrowed and not active:
		return start_eruption()
	if active:
		if mode==Mode.BURROW:
			queued = time>=0.12 and actor.mana>=COSTS[0]
			return queued
		if queued or combo_index>=3 or time<0.12 or actor.mana<COSTS[combo_index]:
			return false
		queued = true
		return true
	var next := combo_index+1 if combo_window>0 and combo_index<3 else 1
	if not actor.spend_mana(COSTS[next-1]):
		actor.state = "Not enough MP"
		return false
	aerial = not actor.is_on_floor()
	combo_index = next
	combo_window = 0
	mode = Mode.REGULAR
	active = true
	queued = false
	time = 0
	released = false
	direction = actor.facing
	hits.clear()
	if aerial:
		actor.velocity.y = minf(actor.velocity.y,-100.0)
	return true

func combo_duration() -> float:
	if mode==Mode.BURROW:
		return 0.64
	return DURATIONS[clampi(combo_index-1,0,2)]

func tick(dt: float) -> void:
	time += dt
	actor.facing = direction
	actor.velocity.x = move_toward(actor.velocity.x,0,actor.mage_braking*dt)
	if mode==Mode.BURROW and not released:
		actor.velocity = Vector2.ZERO
	else:
		var gravity_scale := 0.18 if aerial and combo_index<3 else 1.0
		actor.velocity.y = minf(actor.velocity.y+actor.gravity*gravity_scale*dt,1000)
		actor.move_and_slide()
	if not released and time>=combo_duration()*0.42:
		released = true
		if mode==Mode.BURROW:
			erupt()
		else:
			cast()
	actor.state = "%s %s %d/3" % [ELEMENTS[element],"Eruption" if mode==Mode.BURROW else ("Air" if aerial else "Cast"),combo_index]
	if time>=combo_duration():
		var follow := queued
		active = false
		queued = false
		if mode==Mode.BURROW:
			combo_index = 0
		combo_window = 0.6 if combo_index<3 else 0
		if follow and combo_window>0:
			start()

func start_eruption() -> bool:
	var exit_rect := Rect2(actor.position.x-13,actor.FLOOR_Y-40,26,38)
	for block in actor.world.blocks:
		if block.intersects(exit_rect):
			actor.state = "Exit blocked — move sideways"
			return false
	if not actor.spend_mana(ERUPTION_COST):
		return false
	mode = Mode.BURROW
	aerial = false
	active = true
	queued = false
	released = false
	time = 0
	combo_index = 3
	combo_window = 0
	direction = actor.facing
	eruption_origin = Vector2(actor.position.x,actor.FLOOR_Y-20)
	hits.clear()
	return true

func erupt() -> void:
	actor.burrowed = false
	actor.burrow_exit_requested = false
	actor.begin_burrow_cooldown()
	actor.collision_mask = 1
	actor.position = Vector2(eruption_origin.x,actor.FLOOR_Y-actor.HALF_HEIGHT-2)
	actor.velocity = Vector2(direction*45,-650)
	actor.air_jump = true
	actor.jump_buffer = 0
	actor.feedback.emit("emerge",eruption_origin)
	var effect := {"from":eruption_origin,"to":eruption_origin+Vector2(direction,0),"life":EFFECT_DURATION,"element":element,"finisher":true,"eruption":true,"impacts":[eruption_origin]}
	effects.append(effect)
	for enemy in actor.world.combat_targets:
		if enemy.health<=0 or absf(enemy.position.x-eruption_origin.x)>155 or absf(enemy.position.y-eruption_origin.y)>100:
			continue
		var ray := PhysicsRayQueryParameters2D.create(eruption_origin,enemy.position,1,[actor.get_rid()])
		if not actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		enemy.regular_hit(12)
		if element==3:
			enemy.position.x = move_toward(enemy.position.x,eruption_origin.x,48)
		enemy.apply_element(element,direction)
		if element==2:
			enemy.velocity.y = -720
		hits.append(enemy)
		actor.feedback.emit("regular_hit",enemy.position)

func animation_frame() -> int:
	# Anticipation, release and recovery; damage lands on the release frame.
	var phase := time/combo_duration()
	return 0 if phase<0.42 else (1 if phase<0.72 else 2)

func cast() -> void:
	var reach := 245.0 if combo_index==3 else 200.0
	var box := Rect2(actor.position+Vector2(-reach if direction<0 else 0,-95 if aerial else -75),Vector2(reach,170 if aerial else 100))
	var origin: Vector2 = actor.position+Vector2(direction*26,-49)
	var endpoint := origin+Vector2(direction*(reach-26),0)
	var ray := PhysicsRayQueryParameters2D.create(origin,endpoint,1,[actor.get_rid()])
	var wall: Dictionary = actor.get_world_2d().direct_space_state.intersect_ray(ray)
	if not wall.is_empty():
		endpoint = wall.position
	var effect := {"from":origin,"to":endpoint,"life":EFFECT_DURATION,"element":element,"finisher":combo_index==3,"aerial":aerial,"impacts":[]}
	effects.append(effect)
	for enemy in actor.world.combat_targets:
		if enemy.health<=0 or enemy in hits or not box.intersects(enemy.hit_rect()):
			continue
		ray = PhysicsRayQueryParameters2D.create(origin,enemy.position,1,[actor.get_rid()])
		if not actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		effect.impacts.append(enemy.position+Vector2(0,-14))
		hits.append(enemy)
		enemy.regular_hit([6,7,9][combo_index-1])
		if aerial and combo_index<3 and enemy.has_method("apply_element"):
			enemy.apply_element(2,direction)
			enemy.velocity = Vector2(direction*25,-180)
		if combo_index==3 and enemy.has_method("apply_element"):
			enemy.apply_element(element,direction)
		actor.feedback.emit("regular_hit",enemy.position)

func _process(dt: float) -> void:
	for i in range(effects.size()-1,-1,-1):
		effects[i].life -= dt
		if effects[i].life<=0:
			effects.remove_at(i)
