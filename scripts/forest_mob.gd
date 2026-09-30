extends "res://scripts/combat_dummy.gd"

signal defeated

const SHEET = preload("res://assets/mobs/rootling-walk.png")
const COMBAT_SHEET = preload("res://assets/mobs/rootling-combat.png")
const DEATH_SHEET = preload("res://assets/mobs/rootling-death.png")
const DEATH_FRAMES := [Rect2(250,55,400,480),Rect2(870,170,510,370),Rect2(100,665,695,295),Rect2(860,780,580,185)]
const DEATH_ROOTS := [180.0,290.0,340.0,280.0]
const DEATH_FEET := [465.0,358.0,285.0,173.0]
const DEATH_DURATION := 1.5
const COMBAT_FRAMES := [Rect2(52,50,455,414),Rect2(548,74,535,389),Rect2(1101,68,391,399),Rect2(35,508,458,429),Rect2(562,567,378,370),Rect2(1090,527,328,410)]
const COMBAT_ROOTS := [270.0,193.0,175.0,260.0,183.0,166.0]
const COMBAT_FEET := [404.0,382.0,389.0,420.0,360.0,401.0]
const WINDUP := 0.32
const ATTACK_DURATION := 0.76
const HURT_DURATION := 0.34
# Each pose is registered to its feet, avoiding atlas whitespace in the pivot.
const FRAMES := [Rect2(270,65,330,402),Rect2(955,75,304,394),Rect2(267,549,345,402),Rect2(951,554,307,400)]
const BASELINES := [397.0,389.0,396.0,395.0]
const ROOT_X := [165.0,152.0,172.0,153.0]
const ART_SCALE := 0.15
var patrol := Vector2(50,1230)
var home_patrol := Vector2(50,1230)
var direction := 1.0
var speed := 32.0
var walk_distance := 0.0
var sprite: AnimatedSprite2D
var attack_time := -1.0
var attack_cooldown := 0.0
var attack_hit := false
var hurt_timer := 0.0
var death_time := -1.0
var frozen := 0.0
var burning := 0.0
var burn_tick := 0.0
var half_buried := false

func _ready() -> void:
	z_index = 1
	var cutout := ShaderMaterial.new()
	cutout.shader = preload("res://shaders/mob_cutout.gdshader")
	sprite = AnimatedSprite2D.new()
	sprite.material = cutout
	sprite.sprite_frames = SpriteFrames.new()
	for i in FRAMES.size():
		var frame_texture := AtlasTexture.new()
		frame_texture.atlas = SHEET
		frame_texture.region = FRAMES[i]
		frame_texture.margin = Rect2(Vector2(320-ROOT_X[i],420-BASELINES[i]),Vector2(640,440)-FRAMES[i].size)
		sprite.sprite_frames.add_frame("default",frame_texture)
	for animation in ["attack","hurt"]:
		sprite.sprite_frames.add_animation(animation)
		for i in 3:
			var pose: int = i + (3 if animation == "hurt" else 0)
			var texture := AtlasTexture.new()
			texture.atlas = COMBAT_SHEET
			texture.region = COMBAT_FRAMES[pose]
			texture.margin = Rect2(Vector2(320-COMBAT_ROOTS[pose],420-COMBAT_FEET[pose]),Vector2(640,440)-COMBAT_FRAMES[pose].size)
			sprite.sprite_frames.add_frame(animation,texture)
	sprite.sprite_frames.add_animation("death")
	for i in DEATH_FRAMES.size():
		var texture := AtlasTexture.new()
		texture.atlas = DEATH_SHEET
		texture.region = DEATH_FRAMES[i]
		texture.margin = Rect2(Vector2(400-DEATH_ROOTS[i],500-DEATH_FEET[i]),Vector2(800,520)-DEATH_FRAMES[i].size)
		sprite.sprite_frames.add_frame("death",texture)
	sprite.scale = Vector2.ONE * ART_SCALE
	sprite.position.y = 18 - 200 * ART_SCALE
	add_child(sprite)
	home_patrol = patrol
	reset()

func reset() -> void:
	max_health=40
	super.reset()
	health = 40
	patrol = home_patrol
	visible = true
	walk_distance = 0
	flash = 0
	attack_time = -1
	attack_cooldown = 0
	attack_hit = false
	hurt_timer = 0
	death_time = -1
	frozen = 0
	burning = 0
	burn_tick = 0
	half_buried = false
	queue_redraw()

func apply_element(element: int, facing: float) -> void:
	if health<=0:
		return
	attack_time = -1
	match element:
		0:
			burning = 4.0
			burn_tick = 0
		1:
			frozen = 2.0
			velocity = Vector2.ZERO
		2:
			frozen = 0
			stunned = 0
			buried = 0
			half_buried = false
			knocked = true
			dropping = false
			velocity = Vector2(facing*55,-620)
		3:
			frozen = 0
			stunned = 0
			half_buried = true
			var supported := false
			for block in world.blocks:
				if position.x>=block.position.x and position.x<=block.end.x and absf(position.y+18-block.position.y)<3:
					supported = true
			if supported:
				buried = 2.5
				knocked = false
				velocity = Vector2.ZERO
			else:
				knocked = true
				dropping = true
				bury_on_land = 2.5
				velocity = Vector2(0,650)

func regular_hit(amount: int = 10) -> void:
	if health <= 0:
		return
	super.regular_hit(amount)
	hurt_timer = HURT_DURATION
	attack_time = -1
	attack_cooldown = 0.55
	velocity.x = 0

func player_in_reach() -> bool:
	var actor: CharacterBody2D = world.player
	if actor.burrowed or absf(actor.position.y-position.y)>28 or absf(actor.position.x-position.x)>65:
		return false
	var ray := PhysicsRayQueryParameters2D.create(position,actor.position,1)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func tick_attack(dt: float) -> void:
	if stunned > 0 or knocked or hurt_timer > 0:
		attack_time = -1
		return
	if attack_time < 0:
		if attack_cooldown > 0 or not player_in_reach() or absf(velocity.y)>1:
			return
		direction = 1 if world.player.position.x >= position.x else -1
		attack_time = 0
		attack_hit = false
	attack_time += dt
	if attack_time >= WINDUP and not attack_hit:
		attack_hit = true
		var actor: CharacterBody2D = world.player
		var strike := Rect2(position+Vector2(-70 if direction<0 else 0,-38),Vector2(70,56))
		var target := Rect2(actor.position-Vector2(13,19),Vector2(26,38))
		if player_in_reach() and strike.intersects(target):
			actor.take_damage(10)
	if attack_time >= ATTACK_DURATION:
		attack_time = -1
		attack_cooldown = 0.7

func hit_rect() -> Rect2:
	if health <= 0:
		return Rect2()
	return Rect2(position + Vector2(-22,-39),Vector2(44,57))

func _physics_process(dt: float) -> void:
	tick_ailments(dt)
	if health <= 0:
		tick_death(dt)
		return
	clock += dt
	flash = maxf(0,flash-dt)
	stunned = maxf(0,stunned-dt)
	hurt_timer = maxf(0,hurt_timer-dt)
	attack_cooldown = maxf(0,attack_cooldown-dt)
	if burning>0:
		burn_tick += minf(dt,burning)
		burning = maxf(0,burning-dt)
		while burn_tick>=0.5:
			burn_tick -= 0.5
			var dot_damage: int=world.modify_damage(2,health,max_health) if world.has_method("modify_damage") else 2
			health = maxi(0,health-dot_damage)
		if health<=0:
			tick_death(dt)
			return
	if frozen>0:
		frozen = maxf(0,frozen-dt)
		queue_redraw()
		return
	if buried > 0:
		buried = maxf(0,buried-dt)
		if buried<=0:
			half_buried = false
		queue_redraw()
		return
	if suspended > 0:
		suspended = maxf(0,suspended-dt)
		queue_redraw()
		return
	tick_attack(dt)
	if not knocked:
		if attack_time < 0 and position.x <= patrol.x:
			direction = 1
		elif attack_time < 0 and position.x >= patrol.y:
			direction = -1
		velocity.x = 0 if stunned > 0 or hurt_timer > 0 or attack_time >= 0 else direction * speed
		position.x = clampf(position.x,patrol.x,patrol.y)
	var old_bottom := position.y + 18
	velocity.y += 1500 * dt
	position += velocity * dt
	position.x = clampf(position.x,25,1255)
	if velocity.y >= 0:
		for block in world.blocks:
			if dropping and not half_buried and block.position.y != 700:
				continue
			if position.x < block.position.x + 5 or position.x > block.end.x - 5:
				continue
			if old_bottom <= block.position.y + 1 and position.y + 18 >= block.position.y:
				position.y = block.position.y - 18
				velocity.y = 0
				if knocked and absf(block.position.y - spawn.y - 18) > 1:
					patrol = Vector2(block.position.x+28,block.end.x-28)
				knocked = false
				if dropping:
					buried = bury_on_land
					bury_on_land = 0
					dropping = false
				break
	if position.y > 850:
		reset()
	if stunned <= 0 and not knocked:
		walk_distance += absf(velocity.x) * dt
	queue_redraw()

func tick_death(dt: float) -> void:
	if death_time < 0:
		death_time = 0
		defeated.emit()
		attack_time = -1
		hurt_timer = 0
		buried = 0
		half_buried = false
		frozen = 0
		burning = 0
		suspended = 0
		knocked = false
		dropping = false
		velocity = Vector2.ZERO
	death_time += dt
	# A rootling killed in midair still falls onto terrain instead of hovering.
	var old_bottom := position.y + 18
	velocity.y += 1500 * dt
	position.y += velocity.y * dt
	for block in world.blocks:
		if position.x >= block.position.x and position.x <= block.end.x and old_bottom <= block.position.y+1 and position.y+18 >= block.position.y:
			position.y = block.position.y-18
			velocity.y = 0
			break
	visible = death_time < DEATH_DURATION
	queue_redraw()

func _process(_delta: float) -> void:
	sprite.material.set_shader_parameter("clip_y",10000.0)
	if health <= 0:
		sprite.visible = true
		sprite.animation = "death"
		sprite.frame = mini(3,int(maxf(death_time,0)/0.2))
		sprite.scale = Vector2.ONE * 0.13
		sprite.position = Vector2(0,18-240*0.13)
		sprite.flip_h = direction < 0
		sprite.modulate = Color(1,1,1,clampf((DEATH_DURATION-maxf(death_time,0))/0.5,0,1))
		return
	sprite.scale = Vector2.ONE * ART_SCALE
	sprite.position.y = 18-200*ART_SCALE
	sprite.visible = health > 0 and (buried <= 0 or half_buried)
	sprite.flip_h = direction < 0
	if hurt_timer > 0:
		sprite.animation = "hurt"
		sprite.frame = mini(2,int((1-hurt_timer/HURT_DURATION)*3))
	elif attack_time >= 0:
		sprite.animation = "attack"
		sprite.frame = 0 if attack_time < WINDUP else (1 if attack_time < WINDUP+0.14 else 2)
	else:
		sprite.animation = "default"
		sprite.frame = 1 if stunned > 0 or knocked else int(walk_distance / 7.0) % 4
	sprite.position.x = -direction * sin(hurt_timer/HURT_DURATION*PI)*5
	sprite.modulate = Color.WHITE if flash <= 0 else Color(1.65,1.5,1.1)
	if frozen>0:
		sprite.frame = 1
		sprite.modulate = Color(0.5,0.85,1.5)
	if half_buried and buried>0:
		sprite.position.y += 26
		sprite.material.set_shader_parameter("clip_y",(18-sprite.position.y)/ART_SCALE)

func _draw() -> void:
	if health<=0:
		return
	for kind in ailments:
		var tint := Color("b8e47c") if kind=="poison" else (Color("ee7790") if kind=="bleed" else Color("a58d58"))
		if kind=="root":
			for i in 3:
				draw_arc(Vector2((i-1)*10,10-i*6),12,-2.8,0.8,12,tint,2,true)
		else:
			for i in 4:
				var t := fposmod(clock+i*0.23,1)
				draw_circle(Vector2(-15+i*10,8-t*38),1.7,Color(tint,1-t))
	if frozen>0:
		var ice := PackedVector2Array([Vector2(-25,18),Vector2(-28,-24),Vector2(-10,-49),Vector2(15,-48),Vector2(28,-17),Vector2(24,18),Vector2(-25,18)])
		draw_colored_polygon(ice,Color(0.4,0.85,1,0.16))
		draw_polyline(ice,Color(0.65,0.95,1,0.8),2,true)
	if burning>0:
		for i in 7:
			var t := fposmod(clock*2+i/7.0,1)
			draw_circle(Vector2(-17+i*5+sin(clock*7+i)*3,15-t*55),3*(1-t)+1,Color(1,0.35+t*0.3,0.08,(1-t)*0.8))
	if health > 0 and buried > 0:
		draw_line(Vector2(-18,17),Vector2(18,17),Color("bca26a"),3)
	if attack_time >= WINDUP and attack_time < WINDUP+0.14:
		draw_arc(Vector2(direction*24,-12),25,-1.1 if direction>0 else PI-1.1,1.1 if direction>0 else PI+1.1,16,Color(0.95,0.81,0.43,0.75),2,true)
