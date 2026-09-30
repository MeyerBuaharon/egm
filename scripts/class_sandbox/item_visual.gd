extends Node2D
const TEXTURE = preload("res://assets/characters/class-sandbox/items.png")
const XS := [0.0,340.0,678.0,1006.0,1334.0]
const YS := [0.0,350.0,605.0,882.0,1179.0]
var world: Node2D
static func region(job: int, slot: int) -> Rect2:
	return Rect2(XS[slot],YS[job],XS[slot+1]-XS[slot],YS[job+1]-YS[job])
static func icon(job: int, slot: int) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas=TEXTURE
	texture.region=region(job,slot)
	return texture
func _process(_dt: float) -> void: queue_redraw()
func _draw() -> void:
	if not world.in_run or world.player.burrowed: return
	var p: CharacterBody2D=world.player
	if world.locked_job==0:
		var hand: Vector2=world.female_visual.hand_position()
		var angle := -0.2
		if p.combat.active:
			var u: float=p.combat.time/maxf(0.1,p.combat.combo_duration())
			angle=lerpf(-1.4,2.1,smoothstep(0.1,0.7,u))
		elif absf(p.velocity.x)>15:
			hand=Vector2(-9,-31)
			angle=-0.6
		draw_set_transform(p.position+hand*Vector2(p.facing,1),angle*p.facing,Vector2(p.facing,1))
		var source := region(0,world.locked_slot)
		var grip: Vector2=[Vector2(181,280),Vector2(505,269),Vector2(830,264),Vector2(1153,266)][world.locked_slot]
		draw_texture_rect_region(TEXTURE,Rect2((source.position-grip)*0.14,source.size*0.14),source)
	elif world.locked_job==2:
		var source := region(2,world.locked_slot)
		draw_set_transform(p.position+Vector2(p.facing*26,-30+sin(world.elapsed*3)*2),0,Vector2(p.facing,1))
		draw_texture_rect_region(TEXTURE,Rect2(-16,-13,32,26),source)
	elif world.locked_job==3 and world.locked_slot==2:
		var hand: Vector2=world.female_visual.hand_position()*Vector2(p.facing,1)+p.position
		for strand in 2:
			var points := PackedVector2Array()
			for i in 12:
				points.append(hand+Vector2(p.facing*(i*2.2),i*1.1+sin(world.elapsed*4+i*0.5+strand)*5))
			draw_polyline(points,Color("796039") if strand==0 else Color("557642"),3,true)
	draw_set_transform(Vector2.ZERO)
