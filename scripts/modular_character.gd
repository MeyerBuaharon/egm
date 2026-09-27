extends Node2D

const MAGE = preload("res://assets/characters/modular/mage-parts.png")
const WARDEN = preload("res://assets/characters/modular/warden-parts.png")
# Tight source regions; each part is painted separately and never contains gear
# belonging to a different slot. Limbs share the existing movement rig's joints.
const MAGE_REGIONS := [Rect2(60,45,232,245),Rect2(371,43,213,248),Rect2(700,109,190,173),Rect2(1030,45,120,256),Rect2(126,332,91,260),Rect2(420,376,113,213),Rect2(718,330,143,269),Rect2(1048,330,98,268),Rect2(70,700,208,158),Rect2(365,649,234,246),Rect2(675,609,217,307),Rect2(965,617,267,280),Rect2(82,921,169,296),Rect2(418,930,126,267),Rect2(700,954,203,248),Rect2(1038,928,119,287)]
const WARDEN_REGIONS := [Rect2(75,35,218,272),Rect2(370,29,224,278),Rect2(685,143,212,154),Rect2(1040,28,140,270),Rect2(110,330,106,264),Rect2(411,357,146,222),Rect2(714,325,162,264),Rect2(1045,331,116,250),Rect2(45,683,246,167),Rect2(360,638,225,265),Rect2(677,622,225,290),Rect2(978,621,241,272),Rect2(76,912,199,166),Rect2(391,921,193,296),Rect2(685,957,247,236),Rect2(1040,925,151,176)]
const ICON_PARTS := [9,10,13,14]
var actor: CharacterBody2D
var base_transform := Transform2D.IDENTITY
var hands := [Vector2.ZERO,Vector2.ZERO]
var elbows := [Vector2.ZERO,Vector2.ZERO]
var blade_angle := 0.0
var spell_visual: Node2D
var trails: Node2D

static func item_icon(class_id: int, slot: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = MAGE if class_id==2 else WARDEN
	texture.region = (MAGE_REGIONS if class_id==2 else WARDEN_REGIONS)[ICON_PARTS[slot]]
	return texture

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	spell_visual = preload("res://scripts/mage_spell_visual.gd").new()
	spell_visual.actor = actor
	add_child(spell_visual)
	trails = preload("res://scripts/warden_attack_trails.gd").new()
	trails.actor = actor
	add_child(trails)

func _process(_dt: float) -> void:
	visible = actor.modular_equipment and actor.appearance.class_index==0
	trails.visible = actor.appearance.class_index==0
	queue_redraw()

func part(index: int, at: Vector2, size: Vector2, angle: float, tint: Color) -> void:
	var mage: bool = actor.appearance.class_index==2
	var texture: Texture2D = MAGE if mage else WARDEN
	var region: Rect2 = (MAGE_REGIONS if mage else WARDEN_REGIONS)[index]
	draw_set_transform_matrix(base_transform*Transform2D(angle,at))
	draw_texture_rect_region(texture,Rect2(-size*0.5,size),region,tint)

func segment(index: int, a: Vector2, b: Vector2, width: float, tint: Color) -> void:
	part(index,(a+b)*0.5,Vector2(width,a.distance_to(b)+3),(b-a).angle()-PI/2,tint)

func pose_hands() -> void:
	var rig: Node2D = actor.appearance
	hands.assign(rig.hands)
	blade_angle = rig.weapon_transform.get_rotation()
	if rig.class_index==2:
		hands = [rig.chest+Vector2(-8,25),rig.chest+Vector2(10,24)]
	var c: Node = actor.combat
	if c.active and not actor.burrowed:
		if rig.class_index==2:
			var frame: int = c.animation_frame()
			var stage: int = clampi(c.combo_index,1,3)-1
			# Three authored hand targets per move: anticipation, release, recovery.
			var near := [Vector2(4,6),Vector2(26,1),Vector2(14,11)]
			var far := [Vector2(-10,13),Vector2(-5,13),Vector2(-10,16)]
			match c.element:
				0:
					if stage==1: near = [Vector2(-9,2),Vector2(24,9),Vector2(17,15)]
					if stage==2:
						near = [Vector2(8,6),Vector2(26,-2),Vector2(13,10)]
						far = [Vector2(3,8),Vector2(22,4),Vector2(3,13)]
				1:
					near = [Vector2(6,-7),Vector2(26,-6),Vector2(14,7)]
					if stage>0:
						far = [Vector2(12,9),Vector2(-21,0) if stage==1 else Vector2(23,4),Vector2(-8,15)]
				2:
					if stage==1: near = [Vector2(12,22),Vector2(17,-18),Vector2(22,-2)]
					if stage==2:
						near = [Vector2(14,22),Vector2(13,-22),Vector2(20,-8)]
						far = [Vector2(-12,20),Vector2(-13,-21),Vector2(-19,-5)]
				3:
					if stage==1:
						near = [Vector2(22,15),Vector2(9,4),Vector2(13,12)]
						far = [Vector2(-22,15),Vector2(1,7),Vector2(-10,13)]
					if stage==2:
						near = [Vector2(13,-18),Vector2(20,20),Vector2(14,10)]
						far = [Vector2(-10,-15),Vector2(6,23),Vector2(-6,13)]
			hands = [rig.chest+far[frame],rig.chest+near[frame]]
		else:
			var phase := clampf(c.time/maxf(c.combo_duration(),0.1),0,1) if c.mode==c.Mode.REGULAR else clampf(c.time/0.45,0,1)
			blade_angle = lerpf(-0.2,1.8,smoothstep(0.12,0.65,phase))
			hands[1] = rig.chest+Vector2(13+sin(phase*PI)*10,lerpf(-17,17,phase))
			hands[0] = hands[1]+Vector2(-5,6) if c.weapon in [1,2] else rig.chest+Vector2(-8,14)
	for i in 2:
		var shoulder: Vector2 = rig.chest+Vector2(-5 if i==0 else 5,0)
		# Targets stay reachable, preventing disjointed elbows or long rubber arms.
		hands[i] = shoulder+(hands[i]-shoulder).limit_length(25)
		elbows[i] = rig.joint(shoulder,hands[i],13,13,1 if i==1 else -1)

func arm(i: int, tint: Color, robes: bool, gloves: bool) -> void:
	var rig: Node2D = actor.appearance
	var shoulder: Vector2 = rig.chest+Vector2(-5 if i==0 else 5,0)
	var width := 7.0 if rig.class_index==2 else 9.0
	segment(12 if robes else 3,shoulder,elbows[i],width+(2 if robes else 0),tint)
	segment(15 if robes else 4,elbows[i],hands[i],width-1,tint)
	var angle: float = (hands[i]-elbows[i]).angle()-PI/2
	var hand_center: Vector2 = hands[i]+(hands[i]-elbows[i]).normalized()*2
	part(13 if gloves else 5,hand_center,Vector2(8,11) if gloves else Vector2(5.5,8),angle,tint)

func _draw() -> void:
	if not visible: return
	var rig: Node2D = actor.appearance
	var mage: bool = rig.class_index==2
	var gear: RefCounted = actor.equipment
	var robes: bool = gear.has_equipped(rig.class_index,1)
	var gloves: bool = gear.has_equipped(rig.class_index,2)
	var boots: bool = gear.has_equipped(rig.class_index,3)
	var helmet: bool = gear.has_equipped(rig.class_index,0)
	var color: Color = actor.combat.TINTS[actor.combat.element] if mage else Color("c69b62")
	if actor.burrowed or mage:
		var center := Vector2(0,actor.FLOOR_Y-actor.position.y) if actor.burrowed else Vector2(0,19)
		var ring := PackedVector2Array()
		for i in 33:
			var angle := TAU*i/32.0
			ring.append(center+Vector2(cos(angle)*22,sin(angle)*4))
		draw_polyline(ring,Color(color,0.55),1.5,true)
	if rig.render_alpha<0.01: return
	pose_hands()
	base_transform = Transform2D(rig.body_turn*actor.facing,Vector2(actor.facing,1),0,Vector2(0,19)+rig.lift)
	var tint := Color(1,1,1,rig.render_alpha)
	var dark := Color(0.73,0.77,0.83,rig.render_alpha)
	for i in 2:
		var shade := dark if i==0 else tint
		segment(6,rig.hip+Vector2(-3 if i==0 else 3,2),rig.knees[i],10 if mage else 12,shade)
		segment(7,rig.knees[i],rig.feet[i]+Vector2(0,-3),7 if mage else 9,shade)
		part(14 if boots else 8,rig.feet[i]+Vector2(2,-5 if boots else -2),Vector2(14,15) if boots else Vector2(12,7),rig.foot_angles[i],shade)
	part(2,rig.hip+Vector2(0,3),Vector2(21,13),0,tint)
	arm(0,dark,robes,gloves)
	var torso_angle: float = (rig.chest-rig.hip).angle()+PI/2
	part(1,(rig.chest+rig.hip)*0.5+Vector2(0,-2),Vector2(23 if mage else 28,29),torso_angle,tint)
	if robes:
		part(11,rig.hip+Vector2(-2,13 if mage else 9),Vector2(34,33 if mage else 26),sin(rig.clock*4)*0.025-rig.run_blend*0.07,tint)
		part(10,(rig.chest+rig.hip)*0.5+Vector2(0,-2),Vector2(26 if mage else 31,31),torso_angle,tint)
	part(0,rig.head+Vector2(0,-4),Vector2(16,20),torso_angle*0.4,tint)
	if helmet:
		part(9,rig.head+Vector2(-1,-5),Vector2(20,23),torso_angle*0.4,tint)
	if not mage and not actor.burrowed:
		draw_weapon(tint)
	arm(1,tint,robes,gloves)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	if mage and actor.combat.active and actor.combat.animation_frame()==0 and not actor.burrowed:
		var palm: Vector2 = base_transform*hands[1]
		draw_circle(palm,4,Color(color,0.3))
		draw_circle(palm,1.5,Color(color,0.9))

func draw_weapon(tint: Color) -> void:
	var c: Node = actor.combat
	var at: Vector2 = hands[1]
	var angle := blade_angle
	if c.active and c.mode==c.Mode.AIR and c.weapon==0 and c.air.stage==3 and c.air.time>=0.18 and not c.air.teleported:
		at = base_transform.affine_inverse()*(c.air.sword_at-actor.position)
		angle = PI/2
	draw_set_transform_matrix(base_transform*Transform2D(angle,at))
	var metal := Color("a8bfca")*tint
	var gold := Color("d0a555")*tint
	draw_line(Vector2(0,8),Vector2(0,-8),Color("5e4331")*tint,3,true)
	match c.weapon:
		0:
			draw_colored_polygon(PackedVector2Array([Vector2(-3,-8),Vector2(-3,-32),Vector2(0,-39),Vector2(3,-32),Vector2(3,-8)]),metal)
			draw_line(Vector2(0,-8),Vector2(0,-36),Color(1,1,1,tint.a),1,true)
			draw_line(Vector2(-7,-7),Vector2(7,-7),gold,3,true)
		1:
			draw_line(Vector2(0,8),Vector2(0,-35),gold,3,true)
			draw_colored_polygon(PackedVector2Array([Vector2(-2,-35),Vector2(14,-39),Vector2(18,-26),Vector2(-2,-22)]),metal)
		2:
			draw_line(Vector2(0,8),Vector2(0,-30),gold,3,true)
			draw_rect(Rect2(-12,-37,24,13),metal)
		3:
			draw_line(Vector2(0,16),Vector2(0,-40),gold,3,true)
			draw_colored_polygon(PackedVector2Array([Vector2(-5,-38),Vector2(0,-53),Vector2(5,-38)]),metal)
