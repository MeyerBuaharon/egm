extends Node

const NAMES := ["Sword", "Axe", "Hammer", "Spear"]
enum Mode { REGULAR, RUNNING, BURROW, AIR }
var air: Node

func _ready() -> void:
	air = preload("res://scripts/warden_air_combat.gd").new()
	air.combat = self
	add_child(air)
@export var running_threshold := 120.0
@export var combo_grace := 0.35
var mode := Mode.REGULAR
var combo_index := 0
var combo_window := 0.0
var queued := false

@export var stun_duration := 1.2
@export var bury_duration := 2.0
@export var thrust_speed := 520.0
@export var launch_speed := 650.0
var actor: CharacterBody2D
var weapon := 0
var selected := 0
var active := false
var time := 0.0
var from_burrow := false
var moving := false
var direction := 1.0
var landed := false
var recovery := 0.0
var hits: Array[Node] = []

func start() -> bool:
	if actor.dash_time > 0: return false
	if active and mode == Mode.AIR: return air.queue_next()
	if not active and not actor.burrowed and not actor.is_on_floor(): return air.start()
	if active:
		# One buffered press per swing, consumed at recovery; never restart mid-hit.
		if time < 0.12 or queued or (mode == Mode.REGULAR and combo_index == 3): return false
		if not actor.can_pay_stamina(actor.attack_stamina_cost): return false
		queued = true
		return true
	from_burrow = actor.burrowed
	if from_burrow:
		var rect := Rect2(actor.position.x-13,actor.FLOOR_Y-40,26,38)
		for block in actor.world.blocks:
			if block.intersects(rect):
				actor.state = "Attack exit blocked"
				return false
	elif not actor.is_on_floor() or not actor.can_stand():
		return false
	if not actor.spend_stamina(actor.attack_stamina_cost): return false
	var axis := Input.get_axis("left","right")
	direction = signf(actor.velocity.x) if absf(actor.velocity.x)>20 else (axis if axis != 0 else actor.facing)
	var follow_up := combo_window > 0 and selected == weapon
	mode = Mode.BURROW if from_burrow else (Mode.REGULAR if follow_up or absf(actor.velocity.x) < running_threshold else Mode.RUNNING)
	combo_index = (combo_index+1 if follow_up else 1) if mode == Mode.REGULAR else 0
	combo_window = 0
	queued = false
	moving = mode != Mode.REGULAR
	weapon = selected
	active = true
	time = 0
	landed = false
	recovery = 0
	hits.clear()
	if from_burrow:
		actor.burrowed = false
		actor.begin_burrow_cooldown()
		actor.burrow_exit_requested = false
		actor.collision_mask = 1
		actor.position.y = actor.FLOOR_Y-actor.HALF_HEIGHT-2
		actor.air_jump = true
		actor.feedback.emit("emerge",actor.position)
	actor.facing = direction
	actor.jump_buffer = 0
	actor.wall_lock = 0
	actor.set_low(false)
	actor.velocity.x = 0
	actor.velocity.y = minf(actor.velocity.y,0) if not from_burrow else 0
	if weapon in [1,3] and from_burrow: actor.velocity.y = -launch_speed
	if weapon == 2 and mode != Mode.REGULAR:
		actor.velocity.y = -launch_speed if from_burrow else -300.0
		actor.velocity.x = direction*130 if moving else 0
	return true

func cancel() -> void:
	if is_instance_valid(air): air.clear()
	active = false
	time = 0
	hits.clear()
	combo_index = 0
	combo_window = 0
	queued = false

func idle_tick(dt: float) -> void:
	combo_window = maxf(0,combo_window-dt)
	if combo_window == 0: combo_index = 0

func finish() -> void:
	active = false
	var continue_chain := queued
	queued = false
	combo_window = combo_grace if mode != Mode.REGULAR or combo_index < 3 else 0.0
	var air_follow_up := mode == Mode.BURROW and weapon in [1,3] and not actor.is_on_floor()
	if continue_chain and combo_window > 0 and (actor.is_on_floor() or air_follow_up): start()

func tick(dt: float) -> void:
	if mode == Mode.AIR:
		air.tick(dt)
		return
	time += dt
	actor.facing = direction
	actor.jump_buffer = 0
	actor.coyote = 0
	if mode == Mode.REGULAR:
		tick_regular(dt)
		return
	var old: Vector2 = actor.position
	if weapon == 0:
		actor.velocity.x = direction*thrust_speed if moving and time >= 0.10 and time < 0.25 else 0.0
	elif weapon in [1,3]:
		actor.velocity.x = direction*70 if moving and not from_burrow and time < 0.25 else 0.0
	elif weapon == 2 and time >= (0.34 if from_burrow else 0.20) and not landed:
		actor.velocity.x = direction*80 if moving else 0.0
		actor.velocity.y = 950
	actor.velocity.y = minf(actor.velocity.y+actor.gravity*dt,1100)
	actor.move_and_slide()
	var box := Rect2(actor.position+Vector2(-20,-55),Vector2(40,76))
	if weapon == 0:
		var tip: Vector2 = actor.position+Vector2(direction*65,-15)
		box = Rect2(old+Vector2(0,-38),Vector2(1,45)).expand(tip).grow(8)
	elif weapon in [1,3]:
		box = Rect2(actor.position+Vector2(-40,-85),Vector2(80,110))
	else:
		box = Rect2(actor.position+Vector2(-44,-15),Vector2(88,60))
	if (weapon == 0 and time >= 0.10 and time < 0.32) or (weapon in [1,3] and time < 0.4) or (weapon == 2 and time >= (0.34 if from_burrow else 0.20) and not landed):
		strike(box)
	if weapon == 2:
		if not landed and time >= (0.34 if from_burrow else 0.20) and actor.is_on_floor():
			landed = true
			actor.velocity.x = 0
			strike(Rect2(actor.position+Vector2(-80,-25),Vector2(160,70)))
			actor.feedback.emit("hammer_slam",actor.position+Vector2(0,19))
		if landed:
			recovery += dt
			if recovery > 0.28: finish()
		elif time > 2.0: finish()
	elif mode == Mode.BURROW and weapon in [1,3] and time >= 0.25:
		# Release the rising strike while airborne so J can chain into air hit one.
		finish()
	elif time > 0.75:
		finish()
	actor.state = ["Thrust · stun","Rising axe · knock-up","Somersault · slam","Rising spear · knock-up"][weapon]
	if actor.position.y > 900: actor.reset()
	actor.queue_redraw()

const COMBO_DURATIONS := [[0.55,0.60,0.72],[0.62,0.65,0.82],[0.72,0.78,0.92],[0.48,0.65,0.62]]
const COMBO_NAMES := [["Forehand cut","Rising backhand","Overhead cleave"],["Broad chop","Low reverse sweep","Overhead cleave"],["Cross-body blow","Shoulder smash","Overhead crush"],["Extended thrust","Diagonal sweep","Butt-end strike"]]
func combo_duration() -> float:
	return COMBO_DURATIONS[weapon][clampi(combo_index-1,0,2)]

func combo_phase() -> int:
	var u := time / combo_duration()
	for i in 6:
		if u < [0.16,0.34,0.44,0.56,0.80,1.0][i]: return i
	return 5

func tick_regular(dt: float) -> void:
	actor.velocity.x = 0
	actor.velocity.y = minf(actor.velocity.y+actor.gravity*dt,1100)
	actor.move_and_slide()
	var duration := combo_duration()
	if time >= duration*0.44 and time < duration*0.68:
		var reach: float = [[68,62,60],[66,72,62],[65,70,72],[92,78,55]][weapon][combo_index-1]
		var top: float = [[-40,-80,-78],[-38,-18,-78],[-40,-58,-70],[-38,-80,-40]][weapon][combo_index-1]
		var left := -reach if direction < 0 else 0.0
		strike(Rect2(actor.position+Vector2(left,top),Vector2(reach,22-top)))
	actor.state = "%d/3 %s" % [combo_index,COMBO_NAMES[weapon][combo_index-1]]
	if time >= duration: finish()
	actor.queue_redraw()

func strike(box: Rect2) -> void:
	for enemy in actor.world.combat_targets:
		if enemy in hits or not box.intersects(enemy.hit_rect()): continue
		# Do not hit through solid scenery; the supporting platform is below target center.
		var ray := PhysicsRayQueryParameters2D.create(actor.position,enemy.position,1,[actor.get_rid()])
		if not actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty(): continue
		hits.append(enemy)
		if mode == Mode.REGULAR:
			enemy.regular_hit()
			actor.feedback.emit("regular_hit",enemy.position)
		else:
			enemy.receive(weapon,direction,stun_duration,bury_duration)
			actor.feedback.emit("combat_hit",enemy.position)

func art_frame() -> int:
	if mode == Mode.AIR: return air.art_frame()
	if mode == Mode.REGULAR:
		return (combo_index-1)*6+combo_phase()
	if weapon == 2:
		return 11 if landed else (8 if time < 0.09 else (9 if time < 0.34 else 10))
	var phase := 0 if time < 0.10 else (1 if time < 0.25 else (2 if time < 0.43 else 3))
	return weapon*4+phase
