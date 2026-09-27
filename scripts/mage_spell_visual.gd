extends Node2D

const SHEET = preload("res://assets/effects/mage-spells.png")
# Measured gutters in the painted sheet, rather than assuming a perfect grid.
const XS := [0,280,630,960,1254]
const YS := [0,313,600,925,1254]
var actor: CharacterBody2D

func _process(_dt: float) -> void:
	visible = actor.appearance.class_index==2
	queue_redraw()

func stamp(element: int, frame: int, center: Vector2, size: Vector2, facing: float, alpha: float) -> void:
	var region := Rect2(XS[frame],YS[element],XS[frame+1]-XS[frame],YS[element+1]-YS[element])
	draw_set_transform(center,0,Vector2(facing,1))
	draw_texture_rect_region(SHEET,Rect2(-size*0.5,size),region,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	if not visible or not ("effects" in actor.combat):
		return
	for effect in actor.combat.effects:
		var progress: float = clampf(1-effect.life/actor.combat.EFFECT_DURATION,0,1)
		var start := to_local(effect.from)
		var end := to_local(effect.to)
		var facing := signf(end.x-start.x)
		var element: int = effect.element
		var strength := 1.25 if effect.finisher else 0.85
		var alpha := 1.0-smoothstep(0.65,1.0,progress)
		# Traveling release keeps its launch direction even if the player turns.
		if element!=3 and progress<0.62 and not effect.get("eruption",false):
			var travel := minf(progress/0.42,1)
			var center := start.lerp(end,travel)
			var size := Vector2(115,70)*strength
			if element==2:
				size = Vector2(110,95)*strength
			stamp(element,0 if progress<0.13 else 1,center,size,facing,alpha)
		# Impacts attach to the positions actually hit, rather than maximum range.
		var impacts: Array = effect.impacts
		if impacts.is_empty() and element==3:
			impacts = [effect.to+Vector2(0,14)]
		for impact in impacts:
			if progress<0.12:
				continue
			var center := to_local(impact)
			var size := Vector2(100,100)*strength
			if effect.get("eruption",false):
				size = Vector2(270,170)
				center.y -= 42
			if element==2 and effect.finisher and not effect.get("eruption",false):
				size = Vector2(100,155)
				center.y -= 28
			elif element==3 and not effect.get("eruption",false):
				size = Vector2(105,85)*strength
				center.y += 5
			var frame := 2 if progress<0.65 else 3
			stamp(element,frame,center,size,facing,alpha)
