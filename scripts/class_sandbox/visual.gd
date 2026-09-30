extends Node2D
const TEXTURES := {
	"roots":preload("res://assets/characters/class-sandbox/wildborn-roots.png"),
	"mage":preload("res://assets/characters/class-sandbox/hexbinder.png"),
	"feral_attack":preload("res://assets/characters/class-sandbox/feral-attacks.png"),
	"warden":preload("res://assets/characters/class-sandbox/warden.png"),
	"wildborn":preload("res://assets/characters/class-sandbox/wildborn.png"),
	"briar":preload("res://assets/characters/class-sandbox/wildborn-briar.png"),
	"feral":preload("res://assets/characters/class-sandbox/wildborn-feral.png"),
	"strider":preload("res://assets/characters/class-sandbox/strider-attacks.png")
}
var actor: CharacterBody2D
var data: Dictionary={}
var key := "warden"
var pose_index := 0
var phase := 0.0
var current_pose: Dictionary={}
var draw_offset := Vector2.ZERO
func _ready() -> void:
	for pair in [["roots","wildborn-roots"],["mage","hexbinder"],["feral_attack","feral-attacks"],["warden","warden"],["wildborn","wildborn"],["briar","wildborn-briar"],["feral","wildborn-feral"],["strider","strider-attacks"]]:
		data[pair[0]]=JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/class-sandbox/%s.json" % pair[1]))
	var shader := ShaderMaterial.new()
	shader.shader=preload("res://shaders/pixel_cutout.gdshader")
	material=shader
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
func _process(dt: float) -> void:
	position=actor.position
	var prior_phase := phase
	var job: int=actor.world.locked_job
	var slot: int=actor.world.locked_slot
	var moving: bool=actor.is_on_floor() and absf(actor.velocity.x)>15 and not actor.combat.active
	visible=actor.world.in_run and (job in [0,2,3] or (job==1 and slot>0 and not moving))
	actor.appearance.visible=not visible and actor.world.in_run
	if not visible: return
	key="warden" if job==0 else ("strider" if job==1 else ("briar" if slot==1 else ("feral" if slot==3 else "wildborn")))
	if job==3 and slot==2: key="roots"
	pose_index=0
	if moving:
		phase=fposmod(phase+dt*absf(actor.velocity.x)/(130.0 if job==3 else 100.0),1)
		pose_index=1+int(phase*4)
	elif actor.combat.active:
		var u: float=actor.combat.time/maxf(actor.combat.combo_duration(),0.1)
		pose_index=5+(0 if u<0.35 else (1 if u<0.7 else 2))
		if job==1: pose_index=(slot-1)*3+(pose_index-5)
	elif job==1: pose_index=(slot-1)*3+2
	elif not actor.is_on_floor(): pose_index=4
	else: phase=0
	if job==3 and slot==3 and actor.combat.active and actor.combat.mode!=actor.combat.Mode.BURROW:
		key="feral_attack"
		pose_index=clampi(actor.combat.combo_index-1,0,2)
	if job==2:
		phase=prior_phase
		key="mage"
		pose_index=0
		if actor.combat.active:
			var u: float=actor.combat.time/maxf(actor.combat.combo_duration(),0.1)
			pose_index=8 if actor.combat.mode==actor.combat.Mode.BURROW else (3 if u<0.35 else 4+slot)
		elif absf(actor.velocity.x)>15:
			phase=fposmod(phase+dt*1.8,1)
			pose_index=1+int(phase*2)
		else: phase=0
	current_pose=data[key].poses[pose_index]
	draw_offset=Vector2(0,19+(35 if actor.burrowed else 0))
	if job==2: draw_offset.y-=8+sin(actor.world.elapsed*3)*1.5
	modulate.a=0.15 if actor.burrowed else 1.0
	queue_redraw()
func hand_position() -> Vector2:
	if current_pose.is_empty(): return Vector2(8,-25)
	return (Vector2(current_pose.hand[0],current_pose.hand[1])-Vector2(current_pose.root[0],current_pose.root[1]))*float(data[key].scale)+draw_offset
func _draw() -> void:
	if not visible or current_pose.is_empty(): return
	var texture: Texture2D=TEXTURES[key]
	var anchor := Vector2(current_pose.root[0],current_pose.root[1])
	var vertices := PackedVector2Array()
	var uv := PackedVector2Array()
	for pair in current_pose.polygon:
		var point := Vector2(pair[0],pair[1])
		vertices.append((point-anchor)*float(data[key].scale))
		uv.append(point/texture.get_size())
	draw_set_transform(draw_offset,0,Vector2(actor.facing,1))
	draw_colored_polygon(vertices,Color.WHITE,uv,texture)
	draw_set_transform(Vector2.ZERO)
