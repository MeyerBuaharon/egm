extends Node2D

# Standing combos already contain authored red trails. Specials use the same
# crimson / pink / white palette, without inheriting the atlas cutout shader.
var actor: CharacterBody2D

func _process(_dt: float) -> void:
	queue_redraw()

func _draw() -> void:
	var combat: Node = actor.combat
	if not combat.active or actor.burrowed:
		return
	draw_set_transform(Vector2.ZERO,0,Vector2(combat.direction,1))
	var time: float = combat.time
	if combat.mode==combat.Mode.REGULAR:
		if actor.modular_equipment:
			var phase: float = time/combat.combo_duration()
			if phase>=0.2 and phase<=0.8:
				draw_sweep((phase-0.2)/0.6,combat.combo_index==2,48)
		return
	if combat.mode == combat.Mode.AIR:
		var air: Node = combat.air
		if combat.weapon == 0 and air.stage == 3:
			return # The thrown sword and delayed cut are drawn by air combat.
		if combat.weapon == 2 or air.stage == 3:
			if air.impacted:
				draw_impact(air.recovery / 0.20)
			else:
				draw_dive(combat.weapon == 2)
			return
		if not air.waiting and time >= 0.10 and time < 0.30:
			draw_sweep((time-0.10)/0.20,air.stage == 2,64)
	elif combat.weapon == 2:
		var drop_at := 0.34 if combat.from_burrow else 0.20
		if combat.landed:
			draw_impact(combat.recovery / 0.28)
		elif time >= drop_at:
			draw_dive(true)
		elif time >= 0.09:
			draw_sweep((time-0.09)/(drop_at-0.09),false,62)
	elif time >= 0.10 and time < 0.40:
		var progress := (time-0.10)/0.30
		if combat.weapon == 0:
			draw_thrust(progress)
		else:
			draw_sweep(progress,true,64 if combat.weapon == 3 else 52)

func draw_sweep(progress: float, rising: bool, radius: float) -> void:
	var head := lerpf(-0.2,-1.9,progress) if rising else lerpf(-1.9,0.55,progress)
	var tail := head + (1.5 if rising else -1.5)
	var opacity := 1.0-smoothstep(0.55,1.0,progress)
	for layer in 3:
		var points := PackedVector2Array()
		var width: float = [13.0,7.0,2.0][layer]
		for i in 21:
			var u := float(i)/20
			var angle := lerpf(tail,head,u)
			points.append(Vector2(4,-19)+Vector2(cos(angle),sin(angle))*radius)
		for i in range(20,-1,-1):
			var u := float(i)/20
			var angle := lerpf(tail,head,u)
			var taper := sin(u*PI)*width
			points.append(Vector2(4,-19)+Vector2(cos(angle),sin(angle))*(radius-taper))
		draw_colored_polygon(points,trail_color(layer,opacity))

func draw_thrust(progress: float) -> void:
	var tip := Vector2(lerpf(46,84,progress),-15)
	for layer in 3:
		var width: float = [9.0,5.0,1.5][layer]
		var points := PackedVector2Array([tip+Vector2(-52,-width),tip+Vector2(10,0),tip+Vector2(-52,width),tip+Vector2(-35,0)])
		draw_colored_polygon(points,trail_color(layer,1.0-smoothstep(0.5,1.0,progress)))

func draw_dive(vertical: bool) -> void:
	var direction := Vector2.DOWN if vertical else Vector2(0.6,0.8)
	var side := direction.orthogonal()
	var tip := direction*(38 if vertical else 84)
	for layer in 3:
		var width: float = [12.0,6.0,2.0][layer]
		var points := PackedVector2Array([tip-direction*80+side*width,tip,tip-direction*80-side*width,tip-direction*60])
		draw_colored_polygon(points,trail_color(layer,0.85))

func draw_impact(progress: float) -> void:
	var radius := lerpf(18,86,clampf(progress,0,1))
	for layer in 3:
		draw_arc(Vector2(0,18),radius-layer*2,PI,TAU,32,trail_color(layer,1.0-clampf(progress,0,1)),5.0-layer*2)

func trail_color(layer: int, opacity: float) -> Color:
	var color: Color = [Color("ff183a"),Color("ff7180"),Color("fff0ed")][layer]
	color.a = opacity
	return color
