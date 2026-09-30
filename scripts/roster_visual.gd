extends Node2D
const MOVEMENT := [preload("res://assets/characters/roster/strider-movement.png"),preload("res://assets/characters/roster/wildborn-movement.png")]
const COMBAT := [preload("res://assets/characters/roster/strider-combos.png"),preload("res://assets/characters/roster/wildborn-combos.png")]
const RUN := [[0,1,3,2],[0,1,2,3]]
const RUN_TEXTURES := [preload("res://assets/characters/roster/strider-run-v4.png"),preload("res://assets/characters/roster/wildborn-run-v4.png")]
const CYCLE_DISTANCE := [108.0,108.0]
var actor: CharacterBody2D
var frame := 0
var combat_frame := -1
var run_clock := 0.0
var run_frame := -1
var emerge := 0.0
var movement_data: Array[Dictionary]=[]
var combat_data: Array[Dictionary]=[]
var run_data: Array[Dictionary]=[]
var outfit: ShaderMaterial
func _ready() -> void:
	for name in ["strider","wildborn"]:
		run_data.append(JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/roster/%s-run-v4.json" % name)))
		movement_data.append(JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/roster/%s-movement.json" % name)))
		combat_data.append(JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/roster/%s-combos.json" % name)))
	outfit=ShaderMaterial.new()
	outfit.shader=preload("res://shaders/roster_equipment.gdshader")
	material=outfit
	actor.feedback.connect(func(kind: String,_at: Vector2):
		if kind=="emerge": emerge=0.22)
func _process(dt: float) -> void:
	visible=actor.modular_equipment and actor.appearance.class_index in [1,3]
	if not visible: return
	emerge=maxf(0,emerge-dt)
	frame=0
	combat_frame=-1
	run_frame=-1
	if actor.burrowed: frame=11
	elif actor.combat.active:
		if actor.combat.mode==actor.combat.Mode.BURROW: frame=15
		else:
			var u: float=actor.combat.time/actor.combat.combo_duration()
			var phase := 5
			for i in 6:
				if u<[0.12,0.25,0.36,0.52,0.72,1.0][i]:
					phase=i
					break
			combat_frame=(clampi(actor.combat.combo_index,1,3)-1)*6+phase
	elif emerge>0: frame=15
	elif actor.standing_shape.size.y<30: frame=10
	elif not actor.is_on_floor(): frame=9 if actor.is_on_wall() else (7 if actor.velocity.y<0 else 8)
	elif absf(actor.velocity.x)>15:
		run_clock=fposmod(run_clock+dt*absf(actor.velocity.x)/CYCLE_DISTANCE[0 if actor.appearance.class_index==1 else 1],1.0)
		run_frame=int(run_clock*4)
	else: run_clock=0
	queue_redraw()
func _draw() -> void:
	if not visible: return
	var class_id: int=actor.appearance.class_index
	var index := 0 if class_id==1 else 1
	var running := run_frame>=0 and combat_frame<0
	var data: Dictionary=run_data[index] if running else (combat_data[index] if combat_frame>=0 else movement_data[index])
	var pose_index: int=RUN[index][run_frame] if running else (combat_frame if combat_frame>=0 else frame)
	var pose: Dictionary=data.poses[pose_index]
	var texture: Texture2D=RUN_TEXTURES[index] if running else (COMBAT[index] if combat_frame>=0 else MOVEMENT[index])
	var factor: float=data.scale
	var anchor := Vector2(pose.root[0],pose.root[1])
	var head := Vector2(pose.head[0],pose.head[1])
	var offset := Vector2(0,19)
	var alpha := 1.0
	if actor.burrowed:
		var u: float=clampf(actor.burrow_time/0.25,0,1)
		offset.y+=u*30
		alpha=1-smoothstep(0.5,1.0,u)
		var ground := Vector2(0,actor.FLOOR_Y-actor.position.y)
		for i in 5: draw_circle(ground+Vector2((i-2)*8,sin(actor.burrow_time*17+i)*3),2,Color("b39d69"))
	preload("res://scripts/armor_palette.gd").apply_to(outfit,class_id,actor.equipment,actor.appearance_preset)
	outfit.set_shader_parameter("source_anchor",anchor)
	outfit.set_shader_parameter("head_at",head)
	outfit.set_shader_parameter("hand_a",Vector2(pose.hands[0][0],pose.hands[0][1]))
	outfit.set_shader_parameter("hand_b",Vector2(pose.hands[1][0],pose.hands[1][1]))
	outfit.set_shader_parameter("pixel_scale",factor)
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for pair in pose.polygon:
		var point := Vector2(pair[0],pair[1])
		vertices.append((point-anchor)*factor)
		uv.append(point/texture.get_size())
	draw_set_transform(offset,0,Vector2(actor.facing,1))
	draw_colored_polygon(vertices,Color(1,1,1,alpha),uv,texture)
	draw_set_transform(Vector2.ZERO)
