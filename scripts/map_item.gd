extends Node2D
const PROPS = preload("res://assets/levels/forest-kit/loot-props.png")
var world: Node2D
var kind := "ember"
var item_id := ""
var amount := 6
var class_id := -1
var slot := -1
var clock := 0.0
var taken := false
var fall_speed := 0.0
func _ready() -> void:
	z_index=5
func _physics_process(dt: float) -> void:
	if taken or item_id!="" or kind not in ["ember","potion"]: return
	var old_y := position.y
	fall_speed+=1200*dt
	position.y+=fall_speed*dt
	for block in world.blocks:
		if position.x>=block.position.x and position.x<=block.end.x and old_y<=block.position.y+1 and position.y>=block.position.y:
			position.y=block.position.y
			fall_speed=0
			break
func _process(dt: float) -> void:
	clock+=dt
	queue_redraw()
func is_claimed() -> bool:
	return taken or (item_id!="" and item_id in world.progress.collected)
func in_reach() -> bool:
	return not world.transitioning and not world.player.burrowed and not world.player.combat.active and world.player.position.distance_to(position+Vector2(0,-19))<48
func can_collect() -> bool:
	if is_claimed() or not in_reach(): return false
	if kind=="potion" and world.player.health>=100 and world.player.mana>=world.player.max_mana: return false
	if kind=="shrine":
		return world.progress.embers>=10 and (world.player.health<100 or world.player.mana<world.player.max_mana or world.player.stamina<world.player.max_stamina)
	return true
func collect() -> bool:
	if not can_collect(): return false
	if item_id!="" and not world.progress.claim(item_id): return false
	match kind:
		"ember":
			world.progress.embers+=amount
			world.notify_player("+%d embers" % amount)
		"potion":
			world.player.health=mini(100,world.player.health+35)
			world.player.mana=minf(world.player.max_mana,world.player.mana+20)
			world.notify_player("Wild tonic: +35 HP, +20 MP")
		"cache":
			world.progress.embers+=amount
			world.award_experience(30)
			world.notify_player("Cache opened: +%d embers, +30 XP" % amount)
		"memory":
			world.progress.points+=1
			world.notify_player("Forest memory found: +1 passive point · P to spend")
		"seal":
			world.progress.points+=3
			world.progress.embers+=30
			world.notify_player("Mansion seal claimed: +3 points, +30 embers, +10% damage")
		"shrine":
			world.progress.embers-=10
			world.player.health=100
			world.player.mana=world.player.max_mana
			world.player.stamina=world.player.max_stamina
			world.notify_player("Restored at the wayshrine")
	if kind!="shrine": taken=true
	world.progress.changed.emit()
	world.save_progress()
	queue_redraw()
	return true
func _draw() -> void:
	var claimed := is_claimed()
	if claimed and kind!="cache": return
	var gold := Color("e8c579")
	var bob := sin(clock*2.5)*2
	match kind:
		"cache":
			var source := Rect2(680,445,405,389) if claimed else Rect2(140,540,380,292)
			var anchor := Vector2(880,824) if claimed else Vector2(330,824)
			draw_texture_rect_region(PROPS,Rect2((source.position-anchor)*0.125,source.size*0.125),source)
			if claimed and in_reach(): draw_string(ThemeDB.fallback_font,Vector2(-42,-82),"Cache emptied",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("bcc5b4"))
		"shrine":
			draw_circle(Vector2(0,-60),20,Color(0.35,0.85,0.7,0.08+sin(clock*2)*0.02))
			var source := Rect2(1200,20,490,820)
			draw_texture_rect_region(PROPS,Rect2((source.position-Vector2(1450,832))*0.093,source.size*0.093),source)
		"memory","seal":
			var center := Vector2(0,-26+bob)
			var tint := Color("b5dcee") if kind=="memory" else gold
			draw_circle(center,20,Color(tint,0.12))
			draw_arc(center,15,clock,clock+PI*1.6,24,tint,1.5)
			draw_colored_polygon(PackedVector2Array([center+Vector2(0,-11),center+Vector2(8,0),center+Vector2(0,11),center+Vector2(-8,0)]),tint)
		"potion":
			draw_circle(Vector2(0,-13+bob),8,Color("924c5e"))
			draw_rect(Rect2(-4,-26+bob,8,9),Color("c6bfa5"))
			draw_line(Vector2(-5,-12+bob),Vector2(5,-12+bob),Color("f4a6ae"),2)
		_:
			var center := Vector2(0,-14+bob)
			draw_circle(center,12,Color(1,0.6,0.2,0.12))
			draw_colored_polygon(PackedVector2Array([center+Vector2(0,-7),center+Vector2(6,0),center+Vector2(0,7),center+Vector2(-6,0)]),gold)
	if not claimed and in_reach() and (world.nearest_pickup()==self or (kind=="shrine" and not can_collect())):
		var labels := {"ember":"Gather embers","potion":"Drink wild tonic","cache":"Open cache","memory":"Claim memory","seal":"Claim mansion seal","shrine":"Rest · 10 embers"}
		var caption: String="F · "+labels[kind]
		if kind=="shrine" and world.progress.embers<10: caption="Wayshrine · needs 10 embers"
		draw_string(ThemeDB.fallback_font,Vector2(-80,-95 if kind=="shrine" else -82),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,12,gold)
