extends Node2D

const ATLAS = preload("res://assets/characters/warden.png")
const COMBAT = preload("res://assets/characters/warden-combat.png")
const ACTIONS = preload("res://assets/characters/warden-actions.png")
var slash_time := -1.0
var slash_frame := -1
const OPPOSITE = preload("res://assets/characters/warden-run-opposite.png")
const NEWRUN = preload("res://assets/characters/warden-run.png")
var run_frame := -1

const ROW_TOP := [0,275,522,770]
const ROW_BOTTOM := [272,521,766,1024]
# Registration is authored to the belt/root, not to cape-dependent bounding boxes.
const ROOT_X := [210,216,212,218,210,202,204,211,220,208,217,212,210,222,222,214]
const GROUND_Y := [260,260,260,260,515,515,515,515,753,753,757,757,1007,1007,1007,1007]
var actor: CharacterBody2D
var frame := 0
var run_clock := 0.0
var moving_before := false
var startup := 0.0
var settle := 0.0
var emerge := 0.0
var land := 0.0
var last_step := -1
var pose := "Idle"
var paint_alpha := 1.0
var body_offset := Vector2.ZERO

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/pixel_cutout.gdshader")
	material = mat
	actor.feedback.connect(on_feedback)
	var trails := preload("res://scripts/warden_attack_trails.gd").new()
	trails.actor = actor
	add_child(trails)

func on_feedback(kind: String, _at: Vector2) -> void:
	if kind == "emerge": emerge = 0.2
	if kind == "land": land = 0.1

func start_slash() -> bool:
	return actor.combat.start()

func _process(dt: float) -> void:
	visible = actor.appearance.class_index == 0 and not actor.modular_equipment
	if not visible:
		slash_time = -1
		return
	run_frame = -1
	slash_frame = -1
	slash_time = actor.combat.time if actor.combat.active else -1.0
	if actor.combat.active: slash_frame = actor.combat.art_frame()
	emerge = maxf(0,emerge-dt)
	land = maxf(0,land-dt)
	startup = maxf(0,startup-dt)
	settle = maxf(0,settle-dt)
	body_offset = Vector2.ZERO
	paint_alpha = 1
	if actor.burrowed:
		var u: float = clampf(actor.burrow_time / actor.warden_burrow_entry,0,1)
		body_offset.y = -44
		pose = "Gauntlet entry" if u < 1 else "Tunneling"
		if u < 0.4:
			frame = 12
		elif u < 0.72:
			frame = 13
		else:
			frame = 14
			body_offset.y += smoothstep(0.72,1.0,u)*24
			paint_alpha = 1-smoothstep(0.8,1.0,u)
	elif slash_frame >= 0:
		pose = actor.combat.NAMES[actor.combat.weapon] + " attack"
	elif emerge > 0:
		frame = 15
		pose = "Burst out"
	elif actor.dash_time > 0:
		frame = 1
		pose = "Dash"
	elif actor.standing_shape.size.y < 30:
		frame = 8
		pose = "Slide"
	elif not actor.is_on_floor():
		frame = 9 if actor.is_on_wall() else (10 if actor.velocity.y < 0 else 11)
		pose = "Wall grip" if frame == 9 else ("Rise" if frame == 10 else "Fall")
	else:
		var moving := absf(actor.velocity.x) > 12
		if moving and not moving_before:
			startup = 0.09
			run_clock = 0
			last_step = -1
		if not moving and moving_before:
			settle = 0.08
		moving_before = moving
		if moving:
			var rate: float = actor.warden_run_fps * clampf(absf(actor.velocity.x)/actor.warden_run_speed,0.35,1.15)
			run_clock += dt * rate
			if startup <= 0: run_frame = int(run_clock) % 4
			frame = 1 if startup > 0 else 2 + int(run_clock) % 6
			pose = "Push off" if startup > 0 else "Heavy run"
			var step := int(run_clock)/2
			if startup <= 0 and step != last_step:
				last_step = step
				actor.feedback.emit("heavy_step",actor.position+Vector2(0,19))
		else:
			frame = 1 if settle > 0 else 0
			pose = "Settle" if settle > 0 else "Idle"
		if land > 0:
			body_offset.y = sin(land/0.1*PI)*1.2
	queue_redraw()

func _draw() -> void:
	if actor.burrowed:
		var surface := Vector2(0,-25)
		for i in 5:
			var shift := sin(actor.burrow_time*15+i)*3
			draw_rect(Rect2(surface+Vector2(-17+i*8,-absf(shift)),Vector2(5,3)),Color("a18765"))
	if paint_alpha <= 0:
		return
	if slash_frame >= 0:
		if actor.combat.mode == actor.combat.Mode.AIR:
			var air: Node = actor.combat.air
			if actor.combat.weapon in [1,3] and air.stage == 3 and not air.impacted:
				draw_missile()
				return
			if actor.combat.weapon == 0 and air.stage == 3:
				if air.time >= 0.18 and air.time < 0.24: return
				if air.time < 0.30:
					# Unarmed raised-gauntlet pose during the throw: no second held blade.
					draw_set_transform(Vector2(0,19),0,Vector2(actor.facing,1))
					draw_texture_rect_region(ATLAS,Rect2(Vector2(-214,-237)*0.29,Vector2(384,254)*0.29),Rect2(1152,770,384,254))
					draw_set_transform(Vector2.ZERO)
					return
				if air.time >= 0.30:
					draw_set_transform(Vector2(0,19),0,Vector2(actor.facing,1))
					draw_texture_rect_region(ATLAS,Rect2(Vector2(-210,-260)*0.29,Vector2(384,272)*0.29),Rect2(0,0,384,272))
					draw_set_transform(Vector2.ZERO)
					return
		if actor.combat.mode == actor.combat.Mode.REGULAR:
			draw_combo()
			return
		var col := slash_frame % 4
		var row := slash_frame / 4
		var top: int = [0,230,498,738][row]
		# Spear poses have different top extents; the shared row included hammer boots.
		if row == 3: top = [807,743,762,808][col]
		var bottom: int = [230,498,766,1024][row]
		var source := Rect2(col*384,top,384,bottom-top)
		var anchor := Vector2([155,168,178,166][col],bottom-top-5)
		if row == 0:
			var left: int = [0,384,800,1180][col]
			source = Rect2(left,0,[384,416,380,356][col],230)
			anchor = Vector2([155,160,155,151][col],229)
		# The next row spear tip intrudes into this cell; exclude it without shifting the pose.
		if row == 2 and col == 1: source.size.y = 240
		var destination := Rect2(-anchor*0.29,source.size*0.29)
		var angle := 0.0
		if actor.combat.mode == actor.combat.Mode.BURROW and actor.combat.weapon == 2 and actor.combat.time >= 0.09 and actor.combat.time < 0.34:
			angle = (actor.combat.time-0.09)/0.25*TAU*actor.facing
		# Rotate the entire intact sprite about the torso for the somersault.
		draw_set_transform(Vector2(0,-10),angle,Vector2(actor.facing,1))
		destination.position.y += 29
		draw_combat_region(destination,source)
		if row == 3 and col in [1,2]:
			# Preserve the raised spear tip above the safe body crop, away from the boot pixels.
			var tip_source := Rect2(650,737,118,6) if col == 1 else Rect2(1000,753,152,9)
			var tip_at := (tip_source.position-Vector2(col*384+anchor.x,bottom-5))*0.29+Vector2(0,29)
			draw_texture_rect_region(COMBAT,Rect2(tip_at,tip_source.size*0.29),tip_source)
		draw_set_transform(Vector2.ZERO)
		return
	if run_frame >= 0:
		# New warden-run.png: 2x2 grid of 627px cells, anchored on the stable helmet x
		# and each frame's own foot-bottom so the planted foot stays on the floor.
		const RUN_QUAD := [Vector2(0,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]
		const RUN_GROUND := [601.0,606.0,573.0,575.0]
		const RUN_HELM := 402.0
		const RUN_CELL := 627.0
		const RUN_FACTOR := 0.125
		var q: Vector2 = RUN_QUAD[run_frame]
		var source := Rect2(q.x*RUN_CELL,q.y*RUN_CELL,RUN_CELL,RUN_CELL)
		var anchor := Vector2(RUN_HELM,RUN_GROUND[run_frame])
		draw_set_transform(Vector2(0,19),0,Vector2(actor.facing,1))
		draw_texture_rect_region(NEWRUN,Rect2(-anchor*RUN_FACTOR,source.size*RUN_FACTOR),source)
		draw_set_transform(Vector2.ZERO)
		return
	var row := frame/4
	var col := frame%4
	var source := Rect2(col*384,ROW_TOP[row],384,ROW_BOTTOM[row]-ROW_TOP[row])
	var factor := 0.29
	var destination := Rect2(Vector2(-ROOT_X[frame]*factor,(ROW_TOP[row]-GROUND_Y[frame])*factor),source.size*factor)
	draw_set_transform(Vector2(0,19)+body_offset,0,Vector2(actor.facing,1))
	draw_texture_rect_region(ATLAS,destination,source,Color(1,1,1,paint_alpha))
	draw_set_transform(Vector2.ZERO)

# All four weapons use connected-component repacked atlases: each pose isolated onto
# a uniform per-weapon grid (no neighbour bleed), read COLUMN-major — column = combo
# hit, row = swing phase (0 windup .. 5 recover), constant feet anchor per weapon.
const CLEAN_COMBO := [preload("res://assets/characters/warden-sword-clean.png"),preload("res://assets/characters/warden-axe-clean.png"),preload("res://assets/characters/warden-hammer-clean.png"),preload("res://assets/characters/warden-spear-clean.png")]
const CLEAN_CELL := [Vector2(444,227),Vector2(442,243),Vector2(416,247),Vector2(472,249)]
const CLEAN_ANCHOR := [Vector2(175,219),Vector2(221,231),Vector2(168,235),Vector2(161,241)]
# Sword/hammer sheets stack a swing down each column (slash in the middle rows);
# axe/spear pair a windup row with a slash row, so they read left-to-right instead.
const CLEAN_COLMAJOR := [true,false,true,false]

func draw_combo() -> void:
	var weapon: int = actor.combat.weapon
	var hit: int = clampi(actor.combat.combo_index-1,0,2)
	var phase: int = actor.combat.combo_phase()
	var gcol: int
	var grow: int
	if CLEAN_COLMAJOR[weapon]:
		gcol = hit
		grow = phase
	else:
		var cell := hit*6+phase
		grow = cell/3
		gcol = cell%3
	var size: Vector2 = CLEAN_CELL[weapon]
	var source := Rect2(gcol*size.x,grow*size.y,size.x,size.y)
	draw_set_transform(Vector2(0,19),0,Vector2(actor.facing,1))
	draw_texture_rect_region(CLEAN_COMBO[weapon],Rect2(-CLEAN_ANCHOR[weapon]*0.34,size*0.34),source)
	draw_set_transform(Vector2.ZERO)

func draw_missile() -> void:
	# Rotate a single intact horizontal dive pose; never articulate its limbs.
	draw_set_transform(Vector2.ZERO,atan2(0.8,0.6)*actor.facing,Vector2(actor.facing,1))
	var source := Rect2(768,770,384,254)
	var destination := Rect2(Vector2(-222,-237)*0.29+Vector2(0,19),source.size*0.29)
	draw_texture_rect_region(ATLAS,destination,source)
	# Shaft begins inside the forward gauntlet, so it travels with the grip.
	draw_line(Vector2(27,-4),Vector2(74,-4),Color("9b7450"),3)
	if actor.combat.weapon == 3:
		draw_colored_polygon(PackedVector2Array([Vector2(69,-8),Vector2(87,-4),Vector2(69,0)]),Color("dce9ee"))
	else:
		draw_colored_polygon(PackedVector2Array([Vector2(67,-14),Vector2(80,-10),Vector2(83,1),Vector2(72,8),Vector2(68,0)]),Color("c5d6df"))
	for i in 3:
		draw_line(Vector2(-52,-13+i*9),Vector2(-26,-13+i*9),Color(1,0.12,0.2,0.5),1)
	draw_set_transform(Vector2.ZERO)

func draw_combat_region(destination: Rect2, source: Rect2) -> void:
	# The raised spear tip overlaps the lower-right corner of the hammer cell.
	# Split the sample without moving or cropping the hammer's feet on the left.
	if source.position == Vector2(768,498):
		var scale_factor := destination.size/source.size
		var left := Rect2(source.position,Vector2(232,source.size.y))
		var right := Rect2(Vector2(1000,498),Vector2(152,253))
		draw_texture_rect_region(COMBAT,Rect2(destination.position,left.size*scale_factor),left)
		draw_texture_rect_region(COMBAT,Rect2(destination.position+Vector2(232,0)*scale_factor,right.size*scale_factor),right)
	else:
		draw_texture_rect_region(COMBAT,destination,source)
