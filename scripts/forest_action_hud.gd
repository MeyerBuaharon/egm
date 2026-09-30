extends Control

const WIDTH := 660.0
const KEYS := ["J","SPACE","SHIFT","S / ↓","1","2","3","4"]
const NAMES := ["Attack","Jump","Dash","Burrow","Unassigned","Unassigned","Unassigned","Unassigned"]
const ABILITY_LEVELS := [1,1,15,20]
const GOLD := Color("e7c989")
var world: Node2D
var panel: StyleBoxFlat

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel = StyleBoxFlat.new()
	panel.bg_color = Color(0.025,0.045,0.05,0.96)
	panel.border_color = Color("69705a")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(7)
	# Hover descriptions explain resource costs and real bindings.
	for i in 8:
		var area := Control.new()
		area.position = Vector2(19+i*78,25)
		area.size = Vector2(74,56)
		area.mouse_filter = Control.MOUSE_FILTER_PASS
		area.tooltip_text = ["J: Attack • 12 stamina per swing. Number shows combo hit. Ring shows recovery; press again to queue the next hit.","Space / W: Jump, then one air jump. Jump through platforms from below. Down + Jump drops through a platform. No stamina cost.","Shift: Dash • 20 stamina. Ring shows recharge.","Hold S / Down: Burrow on main ground • 10 stamina + 14/sec. Release to emerge. 2 sec recharge. On platforms, Down + Jump drops through.","Spell slot 1 — unassigned. No spell equipped.","Spell slot 2 — unassigned. No spell equipped.","Spell slot 3 — unassigned. No spell equipped.","Spell slot 4 — unassigned. No spell equipped."][i]
		add_child(area)

func _process(_delta: float) -> void:
	update_tooltips()
	queue_redraw()

func update_tooltips() -> void:
	var mage: bool = world.player.appearance.class_index==2
	get_child(0).tooltip_text = "J: Three-hit elemental combo • 6 / 8 / 12 MP. Third hit applies the selected element. Q switches element. In air: juggle combo. Underground: 18 MP eruption, then J to chain an air combo." if mage else "J: Attack • 12 stamina per swing. Press again to queue the next hit."
	if "style" in world.player.combat:
		get_child(0).tooltip_text = "J: Three-hit combo • %.0f stamina per attack. Q cycles styles. Underground J/release: 22 stamina ambush; J continues in air." % world.player.combat.attack_cost()
	for i in 4:
		var unlocked: bool = world.character_level>=ABILITY_LEVELS[i]
		get_child(i+4).tooltip_text = "%d: Leveling ability slot — %s. Abilities are separate from elemental attacks." % [i+1,"unlocked, no ability equipped" if unlocked else "unlocks at level %d" % ABILITY_LEVELS[i]]
		if i<2:
			get_child(i+4).tooltip_text=world.player.equipment.DETAILS[i+5]+("" if world.player.equipment.has_equipped(world.player.appearance.class_index,i+5) else " Socket this gem in Inventory first.")

func text(at: Vector2, value: String, size := 11, color := GOLD) -> void:
	draw_string(ThemeDB.fallback_font,at,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func bar(rect: Rect2, value: float, maximum: float, tint: Color, caption: String) -> void:
	draw_rect(rect,Color("192127"))
	draw_rect(Rect2(rect.position,Vector2(rect.size.x*clampf(value/maximum,0,1),rect.size.y)),tint)
	draw_rect(rect,Color(0.6,0.65,0.6,0.4),false,1)
	text(rect.position+Vector2(6,11),caption,10,Color("f4ede0"))

func attack_status() -> Dictionary:
	var c: Node = world.player.combat
	if "style" in c:
		var duration: float=c.combo_duration()
		return {"hit":c.combo_index if c.active else 0,"remaining":maxf(0,duration-c.time) if c.active else 0.0,"duration":duration,"queued":c.queued}
	var hit: int = c.air.stage if c.active and c.mode == c.Mode.AIR else c.combo_index
	if c.active and c.mode not in [c.Mode.REGULAR,c.Mode.AIR]:
		hit = 1
	var remaining := 0.0
	var duration := 1.0
	if c.active:
		if c.mode == c.Mode.REGULAR or "element" in c:
			duration = c.combo_duration()
			remaining = maxf(0,duration-c.time)
		elif c.mode == c.Mode.AIR:
			if c.air.stage < 3 and c.weapon != 2:
				duration = 0.36
				remaining = 0 if c.air.waiting else maxf(0,duration-c.air.time)
			elif c.weapon == 0:
				duration = 0.64
				remaining = maxf(0.01,duration-c.air.time)
			else:
				duration = 0.20
				remaining = maxf(0.01,duration-c.air.recovery) if c.air.impacted else duration
		else:
			duration = 0.75
			remaining = maxf(0,duration-c.time)
	return {"hit":hit,"remaining":remaining,"duration":duration,"queued":c.queued or (c.active and c.mode==c.Mode.AIR and c.air.queued)}

func cooldown(center: Vector2, remaining: float, duration: float) -> void:
	if remaining <= 0:
		return
	var progress := 1-clampf(remaining/duration,0,1)
	var points := PackedVector2Array([center])
	for i in 33:
		var angle := -PI/2 + TAU*(progress+(1-progress)*i/32.0)
		points.append(center+Vector2(cos(angle),sin(angle))*23)
	draw_colored_polygon(points,Color(0.015,0.02,0.03,0.82))
	if progress > 0:
		draw_arc(center,23,-PI/2,-PI/2+TAU*progress,48,GOLD,2,true)
	text(center+Vector2(-11,4),"%.1f" % remaining,12,Color.WHITE)

func icon(index: int, center: Vector2, tint: Color) -> void:
	var class_id: int=world.player.appearance.class_index
	if index in [4,5] and world.player.equipment.has_equipped(class_id,index+1):
		draw_texture_rect(world.player.equipment.item_icon(index+1),Rect2(center-Vector2(15,16),Vector2(30,32)),false)
		return
	if index==0 and class_id in [1,3]:
		for i in (2 if class_id==1 else 3):
			var x := float(i)*9-9
			draw_polyline(PackedVector2Array([center+Vector2(x-4,12),center+Vector2(x+1,-4),center+Vector2(x+6,-13)]),tint,3,true)
			if class_id==1: draw_line(center+Vector2(x-8,6),center+Vector2(x+2,10),tint,2,true)
		return
	var mage: bool = world.player.appearance.class_index==2
	if mage and index==0:
		var element: int = world.player.combat.element
		var color: Color = world.player.combat.TINTS[element]
		draw_arc(center,13,0,TAU,24,color,2,true)
		text(center+Vector2(-5,5),["F","I","W","E"][element],16,color)
		return
	if index == 0:
		draw_line(center+Vector2(-10,10),center+Vector2(11,-12),tint,4,true)
		draw_line(center+Vector2(-11,2),center+Vector2(-3,10),tint,3,true)
		draw_line(center+Vector2(-10,10),center+Vector2(-15,15),tint,3,true)
	elif index == 1:
		draw_polyline(PackedVector2Array([center+Vector2(-11,0),center+Vector2(0,-12),center+Vector2(11,0)]),tint,3,true)
		draw_line(center+Vector2(0,-10),center+Vector2(0,12),tint,3,true)
		draw_line(center+Vector2(-12,15),center+Vector2(12,15),tint,2,true)
	elif index == 2:
		for x in [-9,4]:
			draw_polyline(PackedVector2Array([center+Vector2(x-4,-11),center+Vector2(x+7,0),center+Vector2(x-4,11)]),tint,3,true)
	elif index == 3:
		draw_line(center+Vector2(-16,7),center+Vector2(16,7),tint,2,true)
		draw_polyline(PackedVector2Array([center+Vector2(-9,-7),center+Vector2(0,3),center+Vector2(9,-7)]),tint,3,true)
		draw_arc(center+Vector2(0,17),8,PI,TAU,16,tint,2,true)
	else:
		draw_line(center-Vector2(6,0),center+Vector2(6,0),tint,1)
		draw_line(center-Vector2(0,6),center+Vector2(0,6),tint,1)

func _draw() -> void:
	var p: CharacterBody2D = world.player
	var mage: bool = p.appearance.class_index==2
	draw_style_box(panel,Rect2(0,0,WIDTH,97))
	bar(Rect2(12,7,204,15),p.health,100,Color("963f4f"),"HP  %d / 100" % p.health)
	bar(Rect2(228,7,204,15),p.mana,p.max_mana,Color("355f9d"),"MP  %d / %d" % [p.mana,p.max_mana])
	bar(Rect2(444,7,204,15),p.stamina,p.max_stamina,Color("607f43"),"STAMINA  %d / %d" % [p.stamina,p.max_stamina])
	var attack := attack_status()
	for i in 8:
		var at := Vector2(20+i*78,26)
		var center := at+Vector2(27,24)
		var gem_active: bool=i in [4,5] and p.equipment.has_equipped(p.appearance.class_index,i+1)
		var tint := GOLD if i<4 or gem_active else Color("59625f")
		var cost: float = [p.attack_stamina_cost,0,p.dash_stamina_cost,p.burrow_stamina_cost,0,0,0,0][i]
		var exhausted: bool = i<4 and not p.can_pay_stamina(cost)
		if mage and i==0:
			exhausted = p.mana < p.combat.COSTS[mini(p.combat.combo_index,2)]
		draw_rect(Rect2(at,Vector2(55,49)),Color("1b282b") if i<4 else Color("101b20"))
		draw_rect(Rect2(at,Vector2(55,49)),Color("be655a") if exhausted else tint*Color(1,1,1,0.5),false,1)
		icon(i,center,tint if not exhausted else Color("86534b"))
		if i==0:
			cooldown(center,attack.remaining,attack.duration)
			if attack.hit>0:
				draw_circle(at+Vector2(51,9),10,Color("695137"))
				text(at+Vector2(47,13),str(attack.hit),13,Color.WHITE)
			if attack.queued:
				text(at+Vector2(2,10),"NEXT",8,Color("f6dd91"))
		elif i==1:
			text(at+Vector2(44,12),"2" if p.is_on_floor() else ("1" if p.air_jump else "0"),11)
		elif i==2:
			cooldown(center,p.dash_cooldown,p.dash_recharge*(0.75 if p.has_passive("echo") else 1.0))
		elif i==3:
			cooldown(center,p.burrow_cooldown,p.burrow_recharge)
			if p.burrowed:
				text(at+Vector2(2,14),"DRAIN",9,Color("a6cc80"))
		elif i in [4,5] and p.equipment.has_equipped(p.appearance.class_index,i+1):
			cooldown(center,p.gem_cooldowns[i-4],p.GEM_RECHARGE[i-4])
			if p.mana<p.GEM_COSTS[i-4]: text(at+Vector2(3,14),"LOW MP",8,Color("be655a"))
		text(at+Vector2(3,46),KEYS[i],9,Color("efede4") if i<4 or gem_active else Color("697675"))
		if i>=4:
			var caption: String="EMPTY" if world.character_level>=ABILITY_LEVELS[i-4] else "LV %d" % ABILITY_LEVELS[i-4]
			if i in [4,5] and p.equipment.has_equipped(p.appearance.class_index,i+1): caption="NOVA" if i==4 else "RENEW"
			text(at+Vector2(7,11),caption,9,tint)
	bar(Rect2(12,88,636,5),world.experience,world.experience_needed,Color("ad8a46"),"")
	text(Vector2(14,85),"LV %d   •   XP %d / %d" % [world.character_level,world.experience,world.experience_needed],9,GOLD)
	text(Vector2(370,85),"Q • " + preload("res://scripts/class_roster.gd").style_name(p.appearance.class_index,p.combat) + "  |  1–4 Abilities",9,Color("a6b5aa"))
