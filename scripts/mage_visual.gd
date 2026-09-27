extends Node2D

const SHEET = preload("res://assets/characters/fullbody/mage-hover.png")
const CAST_SHEETS = [preload("res://assets/characters/fullbody/mage-fire.png"),preload("res://assets/characters/fullbody/mage-ice.png"),preload("res://assets/characters/fullbody/mage-wind.png"),preload("res://assets/characters/fullbody/mage-earth.png")]
const CAST_X := [0,442,852,1254]
const CAST_Y := [[0,434,850,1254],[0,424,827,1254],[0,441,855,1254],[0,429,839,1254]]
const CAST_FEET := [[425,843,1240],[415,820,1235],[435,852,1240],[423,831,1239]]
const CAST_SCALE := [[0.222,0.227,0.233],[0.228,0.231,0.225],[0.222,0.233,0.251],[0.230,0.227,0.230]]
const CAST_ROOTS := [[290,640,1055,280,640,1072,276,645,1047],[270,630,1018,270,628,1018,270,630,1018],[275,635,1025,276,635,1025,275,635,1025],[300,640,1006,291,640,1006,290,645,1010]]
const HOVER_ROOTS := [345.0,900.0,352.0,922.0]
const HOVER_FEET := [616.0,602.0,1224.0,1236.0]
const HOVER_SCALE := 0.15
# Source-space anchors on the intact painted frames: head and two hands.
const HOVER_HEAD := [Vector2(368,89),Vector2(936,110),Vector2(367,704),Vector2(934,711)]
const HOVER_HANDS := [[Vector2(278,294),Vector2(432,296)],[Vector2(798,278),Vector2(973,313)],[Vector2(238,898),Vector2(492,746)],[Vector2(953,764),Vector2(1003,904)]]
const CAST_HEAD := [
	[Vector2(300,63),Vector2(649,64),Vector2(1056,67),Vector2(284,490),Vector2(638,490),Vector2(1073,493),Vector2(274,894),Vector2(644,895),Vector2(1053,896)],
	[Vector2(271,61),Vector2(627,62),Vector2(1020,61),Vector2(270,472),Vector2(628,472),Vector2(1020,472),Vector2(268,879),Vector2(626,882),Vector2(1020,880)],
	[Vector2(283,69),Vector2(650,70),Vector2(1027,70),Vector2(270,510),Vector2(635,510),Vector2(1026,510),Vector2(271,921),Vector2(630,934),Vector2(1027,920)],
	[Vector2(309,71),Vector2(650,73),Vector2(1018,72),Vector2(297,477),Vector2(654,476),Vector2(1018,477),Vector2(297,892),Vector2(650,899),Vector2(1020,892)]
]
const CAST_HANDS := [
	[[Vector2(200,86),Vector2(368,205)],[Vector2(549,197),Vector2(763,91)],[Vector2(1029,141),Vector2(1119,212)],[Vector2(242,538),Vector2(282,606)],[Vector2(523,612),Vector2(778,501)],[Vector2(916,587),Vector2(1138,627)],[Vector2(261,945),Vector2(316,955)],[Vector2(694,930),Vector2(756,923)],[Vector2(970,1059),Vector2(1123,1057)]],
	[[Vector2(265,124),Vector2(327,78)],[Vector2(596,128),Vector2(763,80)],[Vector2(934,208),Vector2(1071,212)],[Vector2(244,529),Vector2(283,532)],[Vector2(478,490),Vector2(768,490)],[Vector2(934,623),Vector2(1071,623)],[Vector2(263,935),Vector2(348,849)],[Vector2(704,898),Vector2(751,896)],[Vector2(933,1039),Vector2(1072,1033)]],
	[[Vector2(200,68),Vector2(373,189)],[Vector2(531,202),Vector2(743,86)],[Vector2(922,225),Vector2(1153,82)],[Vector2(290,645),Vector2(369,608)],[Vector2(533,646),Vector2(714,469)],[Vector2(1049,607),Vector2(1099,654)],[Vector2(180,1045),Vector2(363,1047)],[Vector2(573,875),Vector2(704,875)],[Vector2(981,997),Vector2(1120,989)]],
	[[Vector2(239,112),Vector2(382,186)],[Vector2(674,172),Vector2(760,91)],[Vector2(984,130),Vector2(1072,195)],[Vector2(144,507),Vector2(411,504)],[Vector2(650,519),Vector2(704,536)],[Vector2(932,620),Vector2(1075,623)],[Vector2(216,844),Vector2(369,847)],[Vector2(669,1003),Vector2(737,1013)],[Vector2(932,1029),Vector2(1075,1035)]]
]
var equipment_material: ShaderMaterial
var hood: Sprite2D
var actor: CharacterBody2D
var clock := 0.0

func _ready() -> void:
	equipment_material = ShaderMaterial.new()
	equipment_material.shader = preload("res://shaders/mage_equipment.gdshader")
	material = equipment_material
	hood = Sprite2D.new()
	hood.texture = preload("res://scripts/modular_character.gd").item_icon(2,0)
	var hood_material := ShaderMaterial.new()
	hood_material.shader = preload("res://shaders/mage_hood.gdshader")
	hood.material = hood_material
	add_child(hood)
	var spells := preload("res://scripts/mage_spell_visual.gd").new()
	spells.actor = actor
	add_child(spells)

func _process(dt: float) -> void:
	clock += dt
	visible = actor.appearance.class_index==2
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var element: int = actor.combat.element if "element" in actor.combat else 0
	var pose := 1 if absf(actor.velocity.x)>25 else 0
	if not actor.is_on_floor(): pose = 2
	var cell := SHEET.get_size()/2
	var region := Rect2(Vector2(pose%2,int(pose/2.0))*cell,cell)
	var lift := -12+sin(clock*2.4)*1.4
	var alpha := 1.0
	if actor.burrowed:
		alpha = 1-clampf(actor.burrow_time/0.25,0,1)
		lift += 30
	var tint: Color = preload("res://scripts/mage_combat.gd").TINTS[element]
	if actor.burrowed:
		var ground := Vector2(0,actor.FLOOR_Y-actor.position.y)
		var charge: float = actor.combat.time/actor.combat.combo_duration() if actor.combat.active else 0.0
		for layer in 2:
			var points := PackedVector2Array()
			for i in 49:
				var angle := TAU*i/48.0
				points.append(ground+Vector2(cos(angle)*(22+layer*10+charge*30),sin(angle)*(4+layer*2)))
			draw_polyline(points,Color(tint,0.65),2,true)
	if actor.is_on_floor() and not actor.burrowed:
		var ring := PackedVector2Array()
		for i in 33:
			var angle := TAU*i/32.0
			ring.append(Vector2(cos(angle)*18,19+sin(angle)*3))
		draw_polyline(ring,Color(tint,0.45),1.5,true)
	var lean := 0.0
	if actor.combat.active and "aerial" in actor.combat and actor.combat.aerial:
		lean = actor.facing*sin(actor.combat.time/actor.combat.combo_duration()*PI)*(-0.14 if actor.combat.combo_index<3 else 0.22)
	draw_set_transform(Vector2(0,19+lift),lean,Vector2(actor.facing,1))
	var head_anchor: Vector2 = HOVER_HEAD[pose]
	var hand_anchors: Array = HOVER_HANDS[pose]
	var source_scale := HOVER_SCALE
	var source_feet: float = HOVER_FEET[pose]
	var source_root: float = HOVER_ROOTS[pose]
	var at := Vector2(-(HOVER_ROOTS[pose]-region.position.x)*HOVER_SCALE,-(HOVER_FEET[pose]-region.position.y)*HOVER_SCALE)
	if actor.combat.active and "element" in actor.combat:
		var row: int = clampi(actor.combat.combo_index,1,3)-1
		var col: int = actor.combat.animation_frame()
		var texture: Texture2D = CAST_SHEETS[element]
		region = Rect2(CAST_X[col],CAST_Y[element][row],CAST_X[col+1]-CAST_X[col],CAST_Y[element][row+1]-CAST_Y[element][row])
		head_anchor = CAST_HEAD[element][row*3+col]
		hand_anchors = CAST_HANDS[element][row*3+col]
		source_scale = CAST_SCALE[element][row]
		source_feet = CAST_FEET[element][row]
		source_root = CAST_ROOTS[element][row*3+col]
		var scale_factor: float = source_scale
		at = Vector2(-(CAST_ROOTS[element][row*3+col]-region.position.x),-(CAST_FEET[element][row]-region.position.y))*scale_factor
		if element==3 and row==2 and col==0:
			# Include raised hands above the row gutter, excluding the previous
			# frame's boots. Every vertex uses one unchanged full-body transform.
			var points := PackedVector2Array([Vector2(0,810),Vector2(226,810),Vector2(226,836),Vector2(301,836),Vector2(301,810),Vector2(442,810),Vector2(442,1254),Vector2(0,1254)])
			var vertices := PackedVector2Array()
			var uv := PackedVector2Array()
			for point in points:
				vertices.append(at+(point-region.position)*scale_factor)
				uv.append(point/texture.get_size())
			draw_colored_polygon(vertices,Color(1,1,1,alpha),uv,texture)
		else:
			draw_texture_rect_region(texture,Rect2(at,region.size*scale_factor),region,Color(1,1,1,alpha))
	else:
		draw_texture_rect_region(SHEET,Rect2(at,region.size*HOVER_SCALE),region,Color(1,1,1,alpha))
	update_equipment(head_anchor,hand_anchors,source_scale,source_feet,source_root,lift,lean,alpha)
	draw_set_transform(Vector2.ZERO)

func update_equipment(head_at: Vector2, hand_at: Array, source_scale: float, feet_y: float, root_x: float, lift: float, lean: float, alpha: float) -> void:
	var gear: RefCounted = actor.equipment
	equipment_material.set_shader_parameter("wear_robes",gear.has_equipped(2,1))
	equipment_material.set_shader_parameter("wear_gloves",gear.has_equipped(2,2))
	equipment_material.set_shader_parameter("wear_boots",gear.has_equipped(2,3))
	equipment_material.set_shader_parameter("head_at",head_at)
	equipment_material.set_shader_parameter("hand_a",hand_at[0])
	equipment_material.set_shader_parameter("hand_b",hand_at[1])
	equipment_material.set_shader_parameter("pixel_scale",source_scale)
	equipment_material.set_shader_parameter("feet_y",feet_y)
	hood.visible = gear.has_equipped(2,0) and visible and alpha>0.01
	var head_local := (head_at-Vector2(root_x,feet_y))*source_scale
	head_local += Vector2(-3,0)
	var body_transform := Transform2D(lean,Vector2(actor.facing,1),0,Vector2(0,19+lift))
	hood.position = body_transform*head_local
	hood.rotation = lean
	hood.scale = Vector2(actor.facing*23.0/hood.texture.get_width(),26.0/hood.texture.get_height())
	hood.modulate.a = alpha
