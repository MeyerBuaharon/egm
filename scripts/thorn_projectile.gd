extends Node2D
var actor: CharacterBody2D
var velocity := Vector2(520,0)
var damage := 8
var life := 1.2
func _ready() -> void:
	add_to_group("map_combat_transients")
func _physics_process(dt: float) -> void:
	life-=dt
	if life<=0 or not is_instance_valid(actor):
		queue_free()
		return
	var next := position+velocity*dt
	var wall := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position,next,1,[actor.get_rid()]))
	var end: Vector2=wall.position if not wall.is_empty() else next
	# Swept segment collision avoids skipping narrow enemies at low frame rates.
	var nearest: Node2D
	var closest := INF
	for enemy in actor.world.combat_targets:
		if enemy.health<=0: continue
		var contact: Variant=segment_contact(position,end,enemy.hit_rect().grow(3))
		if contact!=null:
			var distance: float=position.distance_squared_to(contact)
			if distance<closest:
				closest=distance
				nearest=enemy
	if is_instance_valid(nearest):
		nearest.regular_hit(damage)
		actor.feedback.emit("regular_hit",nearest.position)
		queue_free()
	elif not wall.is_empty(): queue_free()
	position=end
	rotation=velocity.angle()
	queue_redraw()
func _draw() -> void:
	draw_line(Vector2(-24,0),Vector2(-4,0),Color(0.62,0.87,0.34,0.45),3,true)
	draw_colored_polygon(PackedVector2Array([Vector2(12,0),Vector2(-8,-4),Vector2(-3,0),Vector2(-8,4)]),Color("c3dd79"))
	draw_line(Vector2(-7,0),Vector2(10,0),Color("f1f1b6"),1,true)

static func segment_contact(from: Vector2, to: Vector2, box: Rect2) -> Variant:
	var near_t := 0.0
	var far_t := 1.0
	var delta := to-from
	for axis in 2:
		if absf(delta[axis])<0.00001:
			if from[axis]<box.position[axis] or from[axis]>box.end[axis]: return null
		else:
			var a := (box.position[axis]-from[axis])/delta[axis]
			var b := (box.end[axis]-from[axis])/delta[axis]
			near_t=maxf(near_t,minf(a,b))
			far_t=minf(far_t,maxf(a,b))
			if near_t>far_t: return null
	return from+delta*near_t
