extends RefCounted
# Rigid painted segments: UVs never deform. The two legs have separate,
# half-cycle-offset foot tracks; torso/skirt occlude both hip attachments.
const TEXTURES := [preload("res://assets/characters/roster/strider-run-v2.png"), preload("res://assets/characters/roster/wildborn-run-v2.png")]
const SCALE := [0.2, 0.19]
const HIPS := [Vector2(249,269), Vector2(250,278)]
const PART_TEXTURES := [preload("res://assets/characters/roster/strider-run-parts.png"), preload("res://assets/characters/roster/wildborn-run-parts.png")]
static var part_data: Array[Dictionary] = []
const BODIES := [
	[Vector2(25,30),Vector2(430,30),Vector2(430,280),Vector2(328,281),Vector2(313,252),Vector2(277,244),Vector2(269,262),Vector2(245,293),Vector2(211,323),Vector2(218,281),Vector2(184,300),Vector2(174,278),Vector2(153,274),Vector2(132,291),Vector2(93,282),Vector2(25,240)],
	[Vector2(10,25),Vector2(435,25),Vector2(435,290),Vector2(354,290),Vector2(311,275),Vector2(281,283),Vector2(287,311),Vector2(264,302),Vector2(250,334),Vector2(229,317),Vector2(209,340),Vector2(204,311),Vector2(168,326),Vector2(184,299),Vector2(151,300),Vector2(164,282),Vector2(112,280),Vector2(10,292)]
]

const CYCLE_DISTANCE := [110.0,100.0]

static func foot(phase: float, index: int = 0) -> Vector2:
	var reach: float = CYCLE_DISTANCE[index] / 4.0
	var u := fposmod(phase, 1.0)
	if u < 0.5:
		return Vector2(lerpf(reach, -reach, u * 2), -6)
	var t := (u - 0.5) * 2
	return Vector2(lerpf(-reach, reach, smoothstep(0, 1, t)), -6 - sin(t * PI) * 19)

static func knee(hip: Vector2, ankle: Vector2, a: float, b: float) -> Vector2:
	var delta := ankle - hip
	var length := clampf(delta.length(), absf(a-b)+0.01, a+b-0.01)
	var direction := delta.normalized()
	var along := (a*a - b*b + length*length) / (2*length)
	var height := sqrt(maxf(0, a*a - along*along))
	return hip + direction * along + Vector2(direction.y, -direction.x) * height

static func paint(canvas: Node2D, index: int, polygon: Array, source: Vector2, target: Vector2, angle: float, facing: float, tint: Color) -> void:
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	for p: Vector2 in polygon:
		var v: Vector2 = (p - source).rotated(angle) * SCALE[index] + target
		vertices.append(Vector2(v.x * facing, v.y + 19))
		uvs.append(p / TEXTURES[index].get_size())
	canvas.draw_colored_polygon(vertices, tint, uvs, TEXTURES[index])

static func parts(index: int) -> Array:
	if part_data.is_empty():
		for name in ["strider", "wildborn"]:
			part_data.append(JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/roster/%s-run-parts.json" % name)))
	return part_data[index].parts

static func part_length(part: Dictionary) -> float:
	return Vector2(part.start[0],part.start[1]).distance_to(Vector2(part.end[0],part.end[1])) * part.scale

static func paint_part(canvas: Node2D, index: int, part: Dictionary, target: Vector2, angle: float, facing: float, tint: Color) -> void:
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var anchor := Vector2(part.start[0],part.start[1])
	for pair in part.polygon:
		var point := Vector2(pair[0],pair[1])
		var v: Vector2 = ((point-anchor)*part.scale).rotated(angle)+target
		vertices.append(Vector2(v.x*facing,v.y+19))
		uvs.append(point/PART_TEXTURES[index].get_size())
	canvas.draw_colored_polygon(vertices,tint,uvs,PART_TEXTURES[index])

static func source_angle(part: Dictionary) -> float:
	return (Vector2(part.end[0],part.end[1])-Vector2(part.start[0],part.start[1])).angle()

static func draw(canvas: Node2D, index: int, phase: float, facing: float) -> void:
	var hip := Vector2(0, -30 + cos(phase * TAU * 2) * 1.3)
	var segments := parts(index)
	var a := part_length(segments[0])
	var b := part_length(segments[1])
	for leg in [1,0]:
		var target := foot(phase + leg * 0.5,index)
		var joint := knee(hip, target, a, b)
		var tint := Color(0.66,0.70,0.76,1) if leg == 1 else Color.WHITE
		paint_part(canvas,index,segments[0],hip,(joint-hip).angle()-source_angle(segments[0]),facing,tint)
		paint_part(canvas,index,segments[1],joint,(target-joint).angle()-source_angle(segments[1]),facing,tint)
		paint_part(canvas,index,segments[2],target,0,facing,tint)
	paint(canvas,index,BODIES[index],HIPS[index],hip,sin(phase*TAU)*0.018,facing,Color.WHITE)
