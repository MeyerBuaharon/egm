extends Node2D
const Sweep = preload("res://scripts/thorn_projectile.gd")
var actor: CharacterBody2D
var velocity := Vector2(500,0)
var damage := 8
var kind := "dart"
var element := -1
var status := ""
var finisher := false
var life := 1.4
var spin := 0.0
func _ready() -> void: add_to_group("sandbox_effects")
func _physics_process(dt: float) -> void:
	life-=dt
	if life<=0 or not is_instance_valid(actor):
		queue_free()
		return
	var next := position+velocity*dt
	var wall := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(position,next,1,[actor.get_rid()]))
	var end: Vector2=wall.position if not wall.is_empty() else next
	var nearest: Node2D
	var distance := INF
	for enemy in actor.world.combat_targets:
		if enemy.health<=0: continue
		var contact: Variant=Sweep.segment_contact(position,end,enemy.hit_rect().grow(5))
		if contact!=null and position.distance_squared_to(contact)<distance:
			distance=position.distance_squared_to(contact)
			nearest=enemy
	if is_instance_valid(nearest):
		nearest.regular_hit(damage)
		if not status.is_empty(): nearest.apply_ailment(status,4.0,2)
		if element>=0 and finisher: nearest.apply_element(element,signf(velocity.x))
		actor.world.flash_effect(nearest.position,kind,28)
		queue_free()
	elif not wall.is_empty(): queue_free()
	position=end
	spin+=dt*16
	queue_redraw()
func _draw() -> void:
	var color: Color=actor.world.item_color() if is_instance_valid(actor) else Color.WHITE
	if kind=="star":
		draw_set_transform(Vector2.ZERO,spin)
		var points := PackedVector2Array()
		for i in 8: points.append(Vector2.from_angle(i*PI/4)*(12 if i%2==0 else 3))
		draw_colored_polygon(points,Color("bacdd9"))
		draw_circle(Vector2.ZERO,2,Color("54406d"))
	elif kind in ["fire","ice","wind"]:
		draw_line(Vector2(-signf(velocity.x)*26,0),Vector2.ZERO,Color(color,0.3),8,true)
		draw_circle(Vector2.ZERO,7,color)
		draw_arc(Vector2.ZERO,10,spin,spin+PI,12,Color.WHITE,2,true)
	else:
		draw_set_transform(Vector2.ZERO,velocity.angle())
		draw_line(Vector2(-13,0),Vector2(8,0),color,3,true)
		draw_colored_polygon(PackedVector2Array([Vector2(13,0),Vector2(4,-4),Vector2(4,4)]),color.lightened(0.35))
