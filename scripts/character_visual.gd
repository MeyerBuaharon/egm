extends Node2D

const ATLAS = preload("res://assets/characters/classes.png")
const NAMES := ["Warden", "Strider", "Hexbinder", "Wildborn"]
const COLORS := [Color("e7a34c"), Color("e66561"), Color("bc92ef"), Color("b0d47b")]
const WEAPONS := ["Sword", "Hammer", "Staff", "Daggers"]
# Source joints in the consistent idle pose, not independently recentered frames.
const HEADS := [Vector2(125, 78), Vector2(125, 73), Vector2(120, 62), Vector2(137, 73)]
const HIPS := [Vector2(102, 165), Vector2(99, 163), Vector2(98, 159), Vector2(100, 159)]
const SHOULDERS := [Vector2(89, 111), Vector2(84, 108), Vector2(87, 108), Vector2(91, 110)]
var actor: CharacterBody2D
var class_index := 0
var heavy := false
var weapon_index := 0
var phase := 0.0
var run_blend := 0.0
var start_time := 0.0
var stop_time := 0.0
var was_running := false
var previous_velocity := 0.0
var foot_angles := [0.0, 0.0]
var clock := 0.0
var swing := 0.0
var pose := "Idle"
var action := ""
var action_time := 0.0
var action_duration := 0.0
var hip := Vector2(0, -26)
var chest := Vector2(0, -44)
var head := Vector2(3, -54)
var feet := [Vector2(-5, 0), Vector2(7, 0)]
var hands := [Vector2(-9, -30), Vector2(14, -29)]
var knees := [Vector2.ZERO, Vector2.ZERO]
var elbows := [Vector2.ZERO, Vector2.ZERO]
var weapon_transform := Transform2D.IDENTITY
var off_weapon_transform := Transform2D.IDENTITY
var stow := 0.0
var render_alpha := 1.0
var body_turn := 0.0
var lift := Vector2.ZERO
var grip_error := 0.0
var support_error := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var cutout_material := ShaderMaterial.new()
	cutout_material.shader = preload("res://shaders/pixel_cutout.gdshader")
	material = cutout_material
	actor.feedback.connect(on_action)
	var warden := preload("res://scripts/warden_visual.gd").new()
	warden.actor = actor
	add_child(warden)
	var mage := preload("res://scripts/mage_visual.gd").new()
	mage.actor = actor
	add_child(mage)
	var modular := preload("res://scripts/warden_fullbody.gd").new()
	modular.actor = actor
	add_child(modular)
	var roster := preload("res://scripts/roster_visual.gd").new()
	roster.actor=actor
	add_child(roster)

func on_action(kind: String, _at: Vector2) -> void:
	if kind in ["dig", "emerge", "bounce", "wall", "land"]:
		action = kind
		action_duration = 0.24 if kind == "dig" else (0.32 if kind == "emerge" else 0.18)
		action_time = action_duration

func _process(dt: float) -> void:
	clock += dt
	var on_ground: bool = actor.is_on_floor() and not actor.burrowed and actor.dash_time <= 0
	var moving: bool = on_ground and absf(actor.velocity.x) > 15
	if moving and not was_running:
		start_time = 0.18
		stop_time = 0
		if run_blend < 0.1:
			phase = 0.28 # rear-foot push-off, not a split-legged contact pose
	elif not moving and was_running and on_ground:
		stop_time = 0.15
	start_time = maxf(0,start_time-dt)
	stop_time = maxf(0,stop_time-dt)
	var target := clampf(absf(actor.velocity.x)/240.0,0,1) if moving else 0.0
	run_blend = move_toward(run_blend,target,dt*(8.0 if moving else 7.0))
	if moving or run_blend > 0.01:
		if class_index != 2:
			phase = fposmod(phase + maxf(absf(actor.velocity.x),80*run_blend) * dt / 84.0,1.0)
	was_running = moving
	previous_velocity = actor.velocity.x
	swing = maxf(swing - dt, 0)
	action_time = maxf(action_time - dt, 0)
	update_pose(dt)
	queue_redraw()

func gait_foot(t: float) -> Vector2:
	# Brief grounded drive, then heel recovery, knee lift and reaching contact.
	# Grounded travel still matches 84 px/cycle; the shorter contact avoids splits.
	const CONTACT := 0.38
	const REACH := 15.96
	if t < CONTACT:
		return Vector2(REACH-84*t,0)
	var u := (t-CONTACT)/(1-CONTACT)
	# Delay extension until the knee has passed the hip.
	var x := lerpf(-REACH,REACH,smoothstep(0.08,0.94,u))
	var y := -sin(u*PI)*16
	return Vector2(x,y)

func gait_ankle(t: float) -> float:
	if t < 0.25:
		return 0.0
	if t < 0.38:
		return (t-0.25)/0.13*0.5
	var u := (t-0.38)/0.62
	return lerpf(0.6,-0.2,smoothstep(0,0.85,u))*sin(u*PI)

func joint(a: Vector2, b: Vector2, first: float, second: float, bend: float) -> Vector2:
	var delta := b - a
	var distance := clampf(delta.length(), 0.01, first + second - 0.01)
	var along := (first * first - second * second + distance * distance) / (2 * distance)
	var height := sqrt(maxf(0, first * first - along * along))
	var direction := delta.normalized()
	return a + direction * along + Vector2(-direction.y, direction.x) * height * bend

func update_pose(dt: float) -> void:
	var running := actor.is_on_floor() and absf(actor.velocity.x) > 20
	var crouched: bool = actor.standing_shape.size.y < 30
	var wall := actor.is_on_wall() and not actor.is_on_floor()
	var blend := run_blend
	var drive := sin((1-start_time/0.18)*PI) if start_time > 0 else 0.0
	var settle := sin((1-stop_time/0.15)*PI) if stop_time > 0 else 0.0
	if class_index == 2:
		blend = 0
		drive = 0
		settle = 0
	var lean := lerpf(0,4.5 if not heavy else 3.5,blend) + drive*2 - settle*2
	var bounce := sin(phase*TAU*2-0.4)*1.2
	var hip_y := lerpf(-34.5,-31.5+bounce,blend) + drive*1.5 + settle*0.8
	if actor.modular_equipment:
		hip_y = lerpf(-40,-38+bounce*0.6,blend)+drive*0.7
		lean *= 0.55
	hip = Vector2(-drive*1.5,hip_y)
	chest = hip + Vector2(lean+sin(phase*TAU)*0.6*blend,-20 if actor.modular_equipment else -17)
	head = chest + Vector2(2,-12) if actor.modular_equipment else chest + Vector2(3,-9)
	var idle_feet := [Vector2(-5,0),Vector2(7,0)]
	for i in 2:
		var t := fposmod(phase+i*0.5,1.0)
		feet[i] = idle_feet[i].lerp(gait_foot(t),blend)
		foot_angles[i] = gait_ankle(t)*blend
	pose = "Push off" if start_time > 0 else ("Stop" if stop_time > 0 else ("Run" if blend > 0.05 else "Idle"))
	lift = Vector2.ZERO
	body_turn = 0
	render_alpha = 1
	if not actor.is_on_floor():
		pose = "Rise" if actor.velocity.y < 0 else "Fall"
		feet = [Vector2(-12, -8), Vector2(13, -14)] if actor.velocity.y < 0 else [Vector2(-10, -1), Vector2(12, -5)]
	if crouched:
		pose = "Slide"
		hip = Vector2(-8, -10)
		chest = Vector2(-17, -22)
		head = chest + Vector2(0, -11)
		feet = [Vector2(19, 0), Vector2(-2, -2)]
	if wall:
		pose = "Wall cling"
		hip = Vector2(0, -26)
		chest = Vector2(4, -43)
		head = Vector2(3, -52)
		feet = [Vector2(13, -8), Vector2(12, -22)]
	var digging: bool = actor.burrowed
	if class_index == 2 and not crouched and not wall:
		var glide := clampf(absf(actor.velocity.x)/actor.mage_glide_speed,0,1)
		lift.y = -12 + sin(clock*2.4)*1.4
		hip = Vector2(-glide*2,-32)
		chest = hip+Vector2(2+glide*4,-17)
		head = chest+Vector2(3,-9)
		feet = [Vector2(-4-glide*8,-3),Vector2(5-glide*6,-1)]
		foot_angles = [0.18+glide*0.2,0.1+glide*0.15]
		if actor.modular_equipment:
			hip = Vector2(-glide,-42)
			chest = hip+Vector2(glide*1.5,-20)
			head = chest+Vector2(2,-12)
			feet = [Vector2(-3-glide*5,-1),Vector2(5-glide*4,-1)]
			foot_angles = [0.06+glide*0.12,0.04+glide*0.1]
		pose = "Glide" if glide>0.08 else "Hover"
		if not actor.is_on_floor():
			pose = "Float rise" if actor.velocity.y<0 else "Float fall"
			feet = [Vector2(-5,-2),Vector2(5,-1)] if actor.modular_equipment else [Vector2(-7,-8),Vector2(4,-5)]
	if digging:
		pose = "Burrow"
		lift.y = -44 # compensate underground controller position; entry remains at surface
		var u := 1.0 - action_time / maxf(action_duration, 0.001) if action == "dig" else 1.0
		lift.y += u * 29
		render_alpha = 1 - smoothstep(0.45, 1.0, u)
		match class_index:
			0: # braced ground punch
				chest = Vector2(7, -31 + u * 8)
				head = chest + Vector2(4, -11)
			1: # streamlined diving roll
				body_turn = u * 1.45
				feet = [Vector2(-8, -16), Vector2(9, -18)]
			2: # rising rune dissolve
				lift.y += u * 10
				render_alpha = 1 - u
			3: # low alternating claw scoop
				chest = Vector2(12, -23)
				head = chest + Vector2(9, -9)
				feet = [Vector2(-15, 0), Vector2(9, 0)]
	if action == "emerge" and action_time > 0:
		pose = "Emerge"
		var u := 1 - action_time / action_duration
		match class_index:
			0: chest.x += (1-u)*6
			1: body_turn = -(1-u)*TAU
			2: render_alpha = 0.4 + u * 0.6
			3:
				feet = [Vector2(-16, -12), Vector2(15, -15)]
	var free_hands: bool = wall or digging or (action == "emerge" and action_time > 0.12)
	stow = move_toward(stow, 1 if free_hands else 0, dt * 12)
	var two_handed := heavy or weapon_index in [1, 2]
	var primary := chest + Vector2(14, 13)
	var angle := 0.35
	if two_handed:
		primary = chest + Vector2(10+sin(phase*TAU)*1.2*blend, 16+cos(phase*TAU*2)*1.2*blend)
		angle = 0.9 if weapon_index != 2 else 0.2
	else:
		var pump := sin(phase*TAU)
		var running_hand := chest + Vector2(7+ pump*8,13-absf(pump)*3)
		primary = primary.lerp(running_hand,blend)
		angle = lerp_angle(0.35, -1.9+pump*0.18 if weapon_index in [0,3] else 0.35,blend)
	if crouched:
		primary = chest + Vector2(15, 8)
		angle = 1.2
	if swing > 0:
		angle = lerpf(1.5, -1.6, swing / 0.28)
		primary = chest + Vector2(15, 6)
	weapon_transform = Transform2D(lerp_angle(angle, -0.65, stow), primary.lerp(chest + Vector2(-10, 5), stow))
	hands[1] = primary
	hands[0] = Transform2D(angle, primary) * Vector2(0, 9) if two_handed else chest + Vector2(lerpf(-8,3-sin(phase*TAU)*10,blend),lerpf(17,12-absf(sin(phase*TAU))*3,blend))
	if wall:
		hands = [Vector2(14, -52), Vector2(14, -38)]
	elif digging:
		var beat := sin(clock*28)
		match class_index:
			0: hands = [chest+Vector2(-6,12), Vector2(13, -4)]
			1: hands = [chest+Vector2(9,-6), chest+Vector2(15,-7)]
			2: hands = [chest+Vector2(-18,4), chest+Vector2(19,4)]
			3: hands = [Vector2(15,-3+beat*6), Vector2(24,-3-beat*6)]
	elif action == "emerge" and action_time > 0.12:
		hands = [chest+Vector2(-15,-3), chest+Vector2(8,-20)] if class_index == 0 else [chest+Vector2(-15,0), chest+Vector2(18,-8)]
	# While returning to the hand, let the arm follow the weapon's blended grip.
	if not free_hands:
		hands[1] = weapon_transform.origin
		if two_handed:
			hands[0] = weapon_transform * Vector2(0,9)
	for i in 2:
		var leg_length := 21.0 if actor.modular_equipment else 18.5
		knees[i] = joint(hip + Vector2(-2 if i == 0 else 2,0), feet[i], leg_length, leg_length, -1)
		elbows[i] = joint(chest + Vector2(-4 if i == 0 else 4,0), hands[i], 12.5, 12.5, 1)
	off_weapon_transform = Transform2D(-0.4, hands[0])
	grip_error = 0 if free_hands else hands[1].distance_to(weapon_transform.origin)
	support_error = hands[0].distance_to(weapon_transform * Vector2(0,9)) if two_handed and not free_hands else 0

# Texture-mapped rigid patches from the same idle artwork retain palette and proportions.
func patch(points: PackedVector2Array, source_pivot: Vector2, destination: Vector2, angle: float, tint: Color) -> void:
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in points:
		vertices.append(destination + ((point - source_pivot) * 0.26).rotated(angle))
		uv.append((point + Vector2(0, class_index * 256)) / Vector2(1536,1024))
	draw_colored_polygon(vertices, tint, uv, ATLAS)

func limb(source_a: Vector2, source_b: Vector2, a: Vector2, b: Vector2, width: float, tint: Color) -> void:
	var n := (source_b-source_a).normalized().orthogonal() * width
	var points := PackedVector2Array([source_a+n,source_b+n,source_b-n,source_a-n])
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	var local_n := (b-a).normalized().orthogonal()*width*0.26
	vertices.append_array(PackedVector2Array([a+local_n,b+local_n,b-local_n,a-local_n]))
	for point in points:
		uv.append((point+Vector2(0,class_index*256))/Vector2(1536,1024))
	var base: Color = Color("314127") if class_index == 3 else Color("34434c")
	draw_line(a,b,base*tint,width*0.35)
	draw_colored_polygon(vertices,tint,uv,ATLAS)

func _draw() -> void:
	if class_index in [0,2] or actor.modular_equipment:
		return
	var accent: Color = COLORS[class_index]
	if class_index == 2 and not actor.burrowed and actor.is_on_floor():
		var ring := PackedVector2Array()
		for i in 33:
			var angle := TAU*i/32.0
			ring.append(Vector2(cos(angle)*17,19+sin(angle)*3))
		draw_polyline(ring,Color(0.65,0.5,0.95,0.3),1,true)
		for i in 3:
			var t := fposmod(clock*0.5+i/3.0,1)
			draw_circle(Vector2(-10+i*10,15-t*18),1.2,Color(0.75,0.65,1,(1-t)*0.45))
	if actor.burrowed:
		draw_burrow(accent)
	if render_alpha < 0.01:
		return
	draw_set_transform(Vector2(0,19)+lift,body_turn*actor.facing,Vector2(actor.facing,1))
	var tint := Color(0.86,0.91,1,render_alpha) if heavy else Color(1,1,1,render_alpha)
	var dark := tint * Color(0.65,0.7,0.8,1)
	var source_hip: Vector2 = HIPS[class_index]
	# Legs move beneath one continuous upper-body painting: no detached neck/head.
	for i in 2:
		var shade := dark if i == 0 else tint
		var src_knee := Vector2(77,204) if i == 0 else Vector2(130,203)
		var src_foot := Vector2(59,242) if i == 0 else Vector2(149,242)
		limb(source_hip,src_knee,hip,knees[i],19,shade)
		limb(src_knee,src_foot,knees[i],feet[i],15,shade)
		var f := Vector2(58,249) if i == 0 else Vector2(150,249)
		if class_index == 3:
			for toe in 2:
				var at: Vector2 = feet[i]+Vector2(toe*2,-1)
				draw_colored_polygon(PackedVector2Array([at+Vector2(-2,-3),at+Vector2(5,0),at+Vector2(-2,0)]),Color("c4b67f")*shade)
		else:
			patch(PackedVector2Array([f+Vector2(-22,-22),f+Vector2(21,-22),f+Vector2(25,5),f+Vector2(-25,5)]),f,feet[i]+Vector2(0,-1.3),foot_angles[i],shade)
	if stow > 0.5:
		draw_weapon(weapon_transform,tint)
	arm(0,dark)
	var torso_angle := (chest-hip).angle()+PI/2
	var torso_points := PackedVector2Array([Vector2(80,40),Vector2(149,39),Vector2(158,87),Vector2(156,113),Vector2(137,137),Vector2(139,174),Vector2(116,183),Vector2(73,178),Vector2(73,141),Vector2(45,125),Vector2(47,91),Vector2(76,78)])
	if class_index == 3:
		torso_points = PackedVector2Array([Vector2(71,16),Vector2(144,22),Vector2(175,64),Vector2(169,97),Vector2(142,114),Vector2(134,140),Vector2(133,177),Vector2(74,176),Vector2(71,134),Vector2(45,125),Vector2(66,84)])
	# The entire face, neck, shoulders, and chest remain in their original registration.
	patch(torso_points,source_hip,hip,torso_angle,tint)
	if class_index in [0,1,2]:
		var fabric := Color("a64935") if class_index < 2 else Color("684797")
		fabric.a = render_alpha
		var neck := chest+Vector2(-2,-2)
		draw_colored_polygon(PackedVector2Array([neck,neck+Vector2(-11,1),neck+Vector2(-24,4+sin(clock*11)*2),neck+Vector2(-12,-2)]),fabric)
	if heavy:
		var shoulder := chest+Vector2(-4,0)
		draw_colored_polygon(PackedVector2Array([shoulder+Vector2(-7,-3),shoulder+Vector2(2,-5),shoulder+Vector2(7,-1),shoulder+Vector2(5,6),shoulder+Vector2(-6,5)]),Color("344454")*tint)
		draw_line(shoulder+Vector2(-6,-3),shoulder+Vector2(2,-5),Color("aa9360")*tint,1)
	if stow <= 0.5:
		draw_weapon(weapon_transform,tint)
	if weapon_index == 3 and stow < 0.5:
		draw_weapon(off_weapon_transform,tint)
	arm(1,tint)
	# Grips draw over handles, at exactly the rig's wrist endpoints.
	for hand in hands:
		draw_rect(Rect2(hand-Vector2(2,2),Vector2(4,4)),Color("82694e")*tint)
	if swing > 0 and stow < 0.1:
		draw_arc(hands[1],29,-1.8,0.5,12,Color(accent,swing/0.28),2)
	if action == "emerge" and action_time > 0 and class_index == 2:
		draw_arc(hip,25,clock*5,clock*5+TAU*0.8,20,Color(accent,action_time/action_duration),2)
	draw_set_transform(Vector2.ZERO)

func arm(i: int, tint: Color) -> void:
	var a := Vector2(76,111) if i == 0 else Vector2(136,113)
	var b := Vector2(62,143) if i == 0 else Vector2(153,143)
	var c := Vector2(61,169) if i == 0 else Vector2(165,166)
	limb(a,b,chest+Vector2(-4 if i == 0 else 4,0),elbows[i],14 if heavy else 11,tint)
	limb(b,c,elbows[i],hands[i],12 if heavy else 9,tint)

func draw_burrow(accent: Color) -> void:
	var center := Vector2(0,-25)
	match class_index:
		0:
			for i in 5:
				var x := -18+i*9
				draw_rect(Rect2(center+Vector2(x,-absf(sin(clock*14+i))*5),Vector2(5,3)),Color("b38a61"))
		1:
			draw_line(center+Vector2(-22,0),center+Vector2(20,0),accent,2)
			for i in 3:
				draw_line(center+Vector2(-20+i*10,-4),center+Vector2(-14+i*10,-4),Color(accent,0.5),1)
		2:
			for i in 4:
				var p := center+Vector2(cos(clock*4+i*PI/2)*16,sin(clock*4+i*PI/2)*4)
				draw_colored_polygon(PackedVector2Array([p+Vector2(0,-4),p+Vector2(3,0),p+Vector2(0,4),p+Vector2(-3,0)]),accent)
		3:
			for i in 3:
				draw_line(center+Vector2(-12+i*10,-4),center+Vector2(-6+i*10,3),accent,2)

func weapon_line(t: Transform2D,a: Vector2,b: Vector2,color: Color,width: float) -> void:
	draw_line(t*a,t*b,color,width)

func weapon_polygon(t: Transform2D, points: PackedVector2Array, color: Color) -> void:
	var transformed := PackedVector2Array()
	for point in points:
		transformed.append(t*point)
	draw_colored_polygon(transformed,color)

func draw_weapon(t: Transform2D,tint: Color) -> void:
	var metal := Color("92abb9")*tint
	var edge := Color("e1e8db")*tint
	var gold := Color("9f8052")*tint
	var accent: Color = COLORS[class_index]*tint
	weapon_line(t,Vector2(0,10),Vector2(0,-8),Color("222630")*tint,4)
	weapon_line(t,Vector2(0,8),Vector2(0,-6),Color("765445")*tint,2)
	match weapon_index:
		0:
			var length := 35.0 if heavy else 27.0
			var breadth := 3.5 if heavy else 2.5
			weapon_polygon(t,PackedVector2Array([Vector2(-breadth,-8),Vector2(-breadth,-length+6),Vector2(0,-length),Vector2(breadth,-length+6),Vector2(breadth,-8)]),metal)
			weapon_line(t,Vector2(0,-9),Vector2(0,-length+2),edge,1)
			weapon_polygon(t,PackedVector2Array([Vector2(-7,-9),Vector2(-3,-7),Vector2(3,-7),Vector2(7,-9),Vector2(6,-5),Vector2(-6,-5)]),gold)
			draw_circle(t*Vector2(0,10),2,gold)
		1:
			weapon_line(t,Vector2(0,12),Vector2(0,-26),Color("715845")*tint,3)
			weapon_polygon(t,PackedVector2Array([Vector2(-10,-31),Vector2(8,-31),Vector2(11,-28),Vector2(8,-21),Vector2(-10,-21),Vector2(-12,-24)]),Color("2c3a49")*tint)
			weapon_line(t,Vector2(-10,-31),Vector2(8,-31),metal,2)
			weapon_line(t,Vector2(-9,-30),Vector2(-9,-22),gold,2)
			weapon_line(t,Vector2(7,-30),Vector2(7,-22),gold,2)
		2:
			weapon_line(t,Vector2(0,20),Vector2(0,-28),Color("534637")*tint,3)
			weapon_line(t,Vector2(1,15),Vector2(1,-25),gold,1)
			weapon_polygon(t,PackedVector2Array([Vector2(0,-36),Vector2(5,-30),Vector2(0,-24),Vector2(-5,-30)]),gold)
			weapon_polygon(t,PackedVector2Array([Vector2(0,-34),Vector2(3,-30),Vector2(0,-27),Vector2(-3,-30)]),accent)
		3:
			weapon_polygon(t,PackedVector2Array([Vector2(-2,-6),Vector2(-2,-16),Vector2(2,-23),Vector2(3,-14),Vector2(2,-6)]),metal)
			weapon_line(t,Vector2(2,-8),Vector2(2,-20),edge,1)
			weapon_line(t,Vector2(-4,-5),Vector2(4,-5),gold,2)
