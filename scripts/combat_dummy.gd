extends Node2D
var hovering := false
var world: Node2D
var spawn := Vector2.ZERO
var velocity := Vector2.ZERO
var stunned := 0.0
var buried := 0.0
var bury_on_land := 0.0
var dropping := false
var knocked := false
var clock := 0.0
var hit_count := 0
var flash := 0.0
var suspended := 0.0
var health := 100
func reset() -> void:
	position = spawn
	velocity = Vector2.ZERO
	stunned = 0
	buried = 0
	bury_on_land = 0
	dropping = false
	knocked = false
	hit_count = 0
	suspended = 0
	health = 100
func hit_rect() -> Rect2:
	return Rect2(position+Vector2(-17,-18),Vector2(34,36))
func regular_hit(amount: int = 10) -> void:
	health = maxi(0,health-amount)
	hit_count += 1
	flash = 0.18

func receive(weapon: int, direction: float, stun_time: float, bury_time: float) -> void:
	regular_hit()
	buried = 0
	if weapon == 0:
		stunned = stun_time
		velocity.x = 0
	elif weapon in [1,3]:
		stunned = 0
		dropping = false
		bury_on_land = 0
		knocked = true
		velocity = Vector2(direction*65,-620)
	else:
		stunned = 0
		knocked = true
		dropping = true
		bury_on_land = bury_time
		velocity = Vector2(0,850)
func _physics_process(dt: float) -> void:
	clock += dt
	flash = maxf(0,flash-dt)
	stunned = maxf(0,stunned-dt)
	if buried > 0:
		buried = maxf(0,buried-dt)
		queue_redraw()
		return
	if suspended > 0:
		suspended = maxf(0,suspended-dt)
		queue_redraw()
		return
	if stunned <= 0 and not knocked and position.distance_to(world.player.position)<28:
		world.player.take_damage(10)
	if hovering and health == 100 and not knocked:
		position = spawn+Vector2(0,sin(clock*2)*4)
		queue_redraw()
		return
	var old_y := position.y+18
	velocity.y += 1500*dt
	if not knocked:
		velocity.x = 0 if stunned > 0 else cos(clock*1.8)*15
	position += velocity*dt
	position.x = clampf(position.x,55,1000)
	if velocity.y >= 0:
		for block in world.blocks:
			if dropping and block.position.y != 700: continue
			if position.x < block.position.x or position.x > block.end.x: continue
			if old_y <= block.position.y+1 and position.y+18 >= block.position.y:
				position.y = block.position.y-18
				velocity = Vector2.ZERO
				knocked = false
				if dropping:
					buried = bury_on_land
					bury_on_land = 0
					dropping = false
				break
	queue_redraw()
func _draw() -> void:
	var color := Color("c39f70")
	var label := "Air target" if hovering and health==100 else "Target"
	if flash > 0:
		color = Color.WHITE
		label = "Hit %d" % hit_count
	if stunned>0:
		color = Color("ffe08a")
		label = "Stun %.1f" % stunned
	elif buried>0:
		color = Color("9c7960")
		label = "Buried %.1f" % buried
	elif dropping: label = "Knockdown"
	elif suspended>0: label = "Air hold"
	elif knocked: label = "Knock-up"
	var offset := 17.0 if buried>0 else 0.0
	draw_rect(Rect2(-15,-18+offset,30,36-offset),Color("51453f"))
	draw_arc(Vector2(0,offset),16,PI,TAU,16,color,3)
	for x in [-6,6]: draw_circle(Vector2(x,-5+offset),2,color)
	if buried>0:
		draw_line(Vector2(-22,18),Vector2(22,18),Color("ba9473"),4)
	draw_string(ThemeDB.fallback_font,Vector2(-30,-27),label,HORIZONTAL_ALIGNMENT_LEFT,-1,11,color)
