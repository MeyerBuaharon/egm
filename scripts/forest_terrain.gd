extends Node2D

const TEXTURE = preload("res://assets/levels/forest-kit/terrain.png")
const ART_SCALE := 0.4
const SOURCE_Y := 215.0
const SURFACE_Y := 250.0
var width := 300.0
var one_way := false

func _ready() -> void:
	var body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width,8 if one_way else 80)
	collision.shape = shape
	collision.position = Vector2(width * 0.5,shape.size.y * 0.5)
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 2.0
	if one_way:
		body.set_meta("one_way_platform",true)
	body.add_child(collision)
	add_child(body)

func _draw() -> void:
	# Caps and repeated middle share the same texel scale on every platform.
	var cap := 160.0 * ART_SCALE
	var top := (SOURCE_Y - SURFACE_Y) * ART_SCALE
	draw_texture_rect_region(TEXTURE,Rect2(0,top,cap,136),Rect2(20,SOURCE_Y,160,340))
	var x := cap
	while x < width - cap:
		var span := minf(512 * ART_SCALE,width - cap - x)
		draw_texture_rect_region(TEXTURE,Rect2(x,top,span,136),Rect2(400,SOURCE_Y,span / ART_SCALE,340))
		x += span
	draw_texture_rect_region(TEXTURE,Rect2(width-cap,top,cap,136),Rect2(1992,SOURCE_Y,160,340))
