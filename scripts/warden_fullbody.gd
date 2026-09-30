extends Node2D
# Complete painted poses, registered to hips/soles. No body-part deformation.
const SHEET = preload("res://assets/characters/fullbody/warden-movement.png")
const SCALE := 0.28
const COMBOS = preload("res://assets/characters/fullbody/warden-combos.png")
const COMBO_HEADS := [Vector2(230,75),Vector2(656,75),Vector2(1108,81),Vector2(245,502),Vector2(637,510),Vector2(1106,500),Vector2(222,909),Vector2(674,927),Vector2(1103,912)]
const COMBO_HANDS := [Vector2(137,69),Vector2(800,126),Vector2(1135,245),Vector2(79,648),Vector2(757,455),Vector2(1008,623),Vector2(151,844),Vector2(739,1068),Vector2(1130,1065)]
const COMBO_FAR := [Vector2(309,160),Vector2(678,170),Vector2(1136,166),Vector2(299,585),Vector2(684,590),Vector2(1151,590),Vector2(272,988),Vector2(655,1040),Vector2(1126,985)]
const COMBO_ANGLES := [-0.6,1.6,2.0,2.7,0.7,0.25,-0.5,2.2,1.9]
const COMBO_ROOTS := [200,625,1068,205,626,1068,199,625,1067]
var combat_frame := -1
const REGIONS := [Rect2(0,0,313,332),Rect2(313,0,314,332),Rect2(627,0,313,332),Rect2(940,0,314,332),Rect2(0,332,313,300),Rect2(313,332,314,300),Rect2(627,332,313,300),Rect2(940,312,314,320),Rect2(0,632,313,284),Rect2(313,612,314,311),Rect2(627,632,344,291),Rect2(971,632,283,291),Rect2(0,916,313,338),Rect2(313,923,314,331),Rect2(627,923,313,331),Rect2(940,923,314,331)]
const ROOTS := [150,477,796,1098,173,482,790,1105,157,477,795,1110,160,474,790,1100]
const FEET := [325,326,326,325,625,625,625,627,905,920,919,924,1242,1241,1242,1242]
const HEADS := [Vector2(167,39),Vector2(522,60),Vector2(835,99),Vector2(1135,30),Vector2(216,367),Vector2(552,392),Vector2(842,363),Vector2(1138,344),Vector2(208,672),Vector2(474,676),Vector2(835,774),Vector2(1169,780),Vector2(190,982),Vector2(506,975),Vector2(814,974),Vector2(1107,1003)]
const HANDS := [Vector2(142,149),Vector2(573,128),Vector2(870,170),Vector2(1197,107),Vector2(260,443),Vector2(593,460),Vector2(895,439),Vector2(1211,373),Vector2(285,755),Vector2(588,646),Vector2(875,898),Vector2(1187,908),Vector2(141,932),Vector2(605,1024),Vector2(835,1094),Vector2(1169,938)]
const FAR_HANDS := [Vector2(211,178),Vector2(403,148),Vector2(718,191),Vector2(1016,145),Vector2(105,479),Vector2(410,488),Vector2(728,470),Vector2(1009,420),Vector2(56,736),Vector2(554,625),Vector2(676,813),Vector2(1040,811),Vector2(254,1091),Vector2(422,1037),Vector2(825,1092),Vector2(1030,1102)]
const BOOTS := [Vector2(185,298),Vector2(494,279),Vector2(760,285),Vector2(1107,247),Vector2(268,600),Vector2(478,580),Vector2(867,600),Vector2(1133,505),Vector2(208,842),Vector2(533,837),Vector2(940,891),Vector2(1055,895),Vector2(238,1210),Vector2(562,1225),Vector2(866,1220),Vector2(1138,1168)]
const RUN := [1,2,3,4,5,6]
var actor: CharacterBody2D
var frame := 0
var clock := 0.0
var run_clock := 0.0
var emerge := 0.0
var helmet: Sprite2D
var held: Node2D
var outfit: ShaderMaterial

func _ready() -> void:
	outfit = ShaderMaterial.new()
	outfit.shader = preload("res://shaders/mage_equipment.gdshader")
	outfit.set_shader_parameter("fabric_tint",Vector3(0.24,0.045,0.045))
	outfit.set_shader_parameter("glove_tint",Vector3(0.16,0.19,0.22))
	outfit.set_shader_parameter("boot_tint",Vector3(0.16,0.19,0.22))
	outfit.set_shader_parameter("hair_drop",10.0)
	outfit.set_shader_parameter("hair_radius",16.0)
	outfit.set_shader_parameter("hair_spread",0.18)
	outfit.set_shader_parameter("hair_blue_ratio",0.8)
	outfit.set_shader_parameter("exposed_skin_radius",24.0)
	material = outfit
	held = preload("res://scripts/warden_held_weapon.gd").new()
	held.z_index = -1
	add_child(held)
	helmet = Sprite2D.new()
	helmet.texture = preload("res://scripts/modular_character.gd").item_icon(0,0)
	add_child(helmet)
	var trails := preload("res://scripts/warden_attack_trails.gd").new()
	trails.actor = actor
	add_child(trails)
	actor.feedback.connect(func(kind: String, _at: Vector2):
		if kind=="emerge": emerge=0.2)

func _process(dt: float) -> void:
	visible = actor.warden_fullbody_enabled and actor.appearance.class_index==0
	if not visible: return
	clock += dt
	emerge = maxf(0,emerge-dt)
	frame = 0
	combat_frame = -1
	if actor.burrowed: frame = 11
	elif actor.combat.active:
		var c: Node = actor.combat
		var duration: float = c.combo_duration() if c.mode==c.Mode.REGULAR else 0.45
		var phase: float = c.time/maxf(duration,0.1)
		var stage: int = clampi(c.combo_index,1,3)-1
		if c.mode==c.Mode.AIR: stage=clampi(c.air.stage,1,3)-1
		elif c.mode==c.Mode.BURROW: stage=1
		combat_frame = stage*3+(0 if phase<0.34 else (1 if phase<0.68 else 2))
		frame = 12 if phase<0.34 else (13 if phase<0.68 else 14)
	elif emerge>0: frame=15
	elif actor.standing_shape.size.y<30: frame=10
	elif not actor.is_on_floor(): frame=9 if actor.is_on_wall() else (7 if actor.velocity.y<0 else 8)
	elif absf(actor.velocity.x)>12:
		run_clock += dt*actor.warden_run_fps*clampf(absf(actor.velocity.x)/actor.warden_run_speed,0.35,1.15)
		frame = RUN[int(run_clock)%RUN.size()]
	else: run_clock=0
	queue_redraw()

func _draw() -> void:
	if not visible: return
	var alpha := 1.0
	var offset := Vector2(0,19)
	if actor.burrowed:
		var progress: float = clampf(actor.burrow_time/actor.warden_burrow_entry,0,1)
		offset.y += progress*25
		alpha = 1-smoothstep(0.65,1.0,progress)
		# Keep the existing underground position marker readable.
		var ground := Vector2(0,actor.FLOOR_Y-actor.position.y)
		for i in 5: draw_circle(ground+Vector2((i-2)*8,sin(clock*14+i)*2),2,Color("b9a175"))
	var source: Rect2 = REGIONS[frame]
	var anchor := Vector2(ROOTS[frame],FEET[frame])
	var head: Vector2 = HEADS[frame]
	var hand: Vector2 = HANDS[frame]
	var far_hand: Vector2 = FAR_HANDS[frame]
	var boot: Vector2 = BOOTS[frame]
	var texture: Texture2D = SHEET
	var factor := SCALE
	if combat_frame>=0:
		var col := combat_frame%3
		var row := combat_frame/3
		texture = COMBOS
		factor = 0.23
		source = Rect2(col*418,row*418,418,418)
		anchor = Vector2(COMBO_ROOTS[combat_frame],[410,835,1241][row])
		head = COMBO_HEADS[combat_frame]
		hand = COMBO_HANDS[combat_frame]
		far_hand = COMBO_FAR[combat_frame]
		boot = Vector2(-10000,-10000)
		if combat_frame==6: source=Rect2(0,821,418,433)
	draw_set_transform(offset,0,Vector2(actor.facing,1))
	if combat_frame==6:
		var points := PackedVector2Array([Vector2(0,839),Vector2(105,839),Vector2(105,821),Vector2(180,821),Vector2(180,839),Vector2(418,839),Vector2(418,1254),Vector2(0,1254)])
		var vertices := PackedVector2Array()
		var uv := PackedVector2Array()
		for point in points:
			vertices.append((point-anchor)*factor)
			uv.append(point/texture.get_size())
		draw_colored_polygon(vertices,Color(1,1,1,alpha),uv,texture)
	elif frame==9:
		# Raised wall-grip hands extend above the gutter; exclude the prior boot.
		var points := PackedVector2Array([Vector2(313,632),Vector2(530,632),Vector2(530,612),Vector2(627,612),Vector2(627,923),Vector2(313,923)])
		var vertices := PackedVector2Array()
		var uv := PackedVector2Array()
		for point in points:
			vertices.append((point-anchor)*factor)
			uv.append(point/texture.get_size())
		draw_colored_polygon(vertices,Color(1,1,1,alpha),uv,texture)
	else:
		draw_texture_rect_region(texture,Rect2((source.position-anchor)*factor,source.size*factor),source,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)
	preload("res://scripts/character_presets.gd").apply_to(outfit,actor.appearance_preset)
	outfit.set_shader_parameter("head_at",head)
	outfit.set_shader_parameter("hand_a",hand)
	outfit.set_shader_parameter("hand_b",far_hand)
	outfit.set_shader_parameter("pixel_scale",factor)
	outfit.set_shader_parameter("feet_y",anchor.y)
	outfit.set_shader_parameter("raised_boot_at",boot)
	for slot in [["wear_robes",1],["wear_gloves",2],["wear_boots",3]]:
		outfit.set_shader_parameter(slot[0],actor.equipment.has_equipped(0,slot[1]))
	var body := Transform2D(0,Vector2(actor.facing,1),0,offset)
	helmet.visible = actor.equipment.has_equipped(0,0) and alpha>0.01
	helmet.position = body*((head-anchor)*factor+Vector2(-1,0))
	helmet.scale = Vector2(actor.facing*20.0/helmet.texture.get_width(),24.0/helmet.texture.get_height())
	helmet.modulate.a = alpha
	held.visible = not actor.burrowed
	held.weapon = actor.combat.weapon
	held.position = body*((hand-anchor)*factor)
	held.scale = Vector2(actor.facing,1)
	var angle := 1.1
	if frame in RUN: angle=0.9
	if frame==13: angle=1.65
	if frame==14: angle=2.1
	if combat_frame>=0: angle=COMBO_ANGLES[combat_frame]
	# Stow against the back while wall-gripping so both hands remain free.
	if frame==9:
		held.position = body*((head-anchor)*factor+Vector2(-12,23))
		angle=-0.3
	var c: Node = actor.combat
	if c.active and c.mode==c.Mode.AIR and c.weapon==0 and c.air.stage==3 and c.air.time>=0.18 and not c.air.teleported:
		held.visible = false # Air combat owns the thrown sword.
	held.rotation = angle*actor.facing
	held.queue_redraw()
