extends CharacterBody2D

signal feedback(kind: String, at: Vector2)

@export var run_speed := 340.0
@export var acceleration := 2400.0
@export var air_acceleration := 1500.0
@export var gravity := 1900.0
@export var jump_speed := 640.0
@export var dash_speed := 680.0
@export var dash_duration := 0.16
@export var dash_recharge := 0.4
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_direction := 1.0
var health := 100
var hurt_time := 0.0
var invulnerable: bool:
	get: return dash_time > 0.0
@export var dig_speed := 420.0
@export var coyote_duration := 0.11
@export var buffer_duration := 0.13
@export_group("Warden")
@export var warden_run_speed := 180.0
@export var warden_acceleration := 900.0
@export var warden_braking := 1800.0
@export var warden_run_fps := 8.0
@export var warden_burrow_entry := 0.27
@export var warden_dig_speed := 260.0
@export_group("Mage")
@export var mage_glide_speed := 220.0
@export var mage_acceleration := 650.0
@export var mage_braking := 850.0
var burrow_exit_requested := false
var burrow_impact_sent := false

@export_group("Resources")
@export var stamina_enabled := false
@export var max_stamina := 100.0
@export var max_mana := 100.0
@export var mana_regen := 8.0
var mana := 100.0
@export var attack_stamina_cost := 12.0
@export var dash_stamina_cost := 20.0
@export var burrow_stamina_cost := 10.0
@export var burrow_stamina_drain := 14.0
@export var stamina_regen := 18.0
@export var burrow_recharge := 2.0
var stamina := 100.0
var stamina_regen_wait := 0.0
var burrow_cooldown := 0.0
var dropped_platform: PhysicsBody2D
var drop_timer := 0.0
var drop_requires_release := false

var modular_equipment := false
var equipment = preload("res://scripts/character_equipment.gd").new()

var combat: Node
var appearance: Node2D

var facing := 1.0
var air_jump := true
var coyote := 0.0
var jump_buffer := 0.0
var wall_lock := 0.0
var burrowed := false
var burrow_time := 0.0
var combo := 0
var state := "Ready"
var squash := Vector2.ONE
var trail: Array[Vector2] = []
var standing_shape: RectangleShape2D
var collider: CollisionShape2D
var world: Node2D
const FLOOR_Y := 700.0
const HALF_HEIGHT := 19.0

func _ready() -> void:
	z_index = 1
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 7.0
	standing_shape = RectangleShape2D.new()
	standing_shape.size = Vector2(26, 38)
	collider = CollisionShape2D.new()
	collider.shape = standing_shape
	add_child(collider)
	combat = preload("res://scripts/warden_combat.gd").new()
	combat.actor = self
	add_child(combat)
	appearance = preload("res://scripts/character_visual.gd").new()
	appearance.actor = self
	add_child(appearance)

func reset() -> void:
	clear_platform_drop()
	drop_requires_release = false
	if is_instance_valid(appearance):
		appearance.get_child(0).slash_time = -1
	if is_instance_valid(combat): combat.cancel()
	position = Vector2(130, FLOOR_Y - HALF_HEIGHT - 1)
	velocity = Vector2.ZERO
	burrowed = false
	burrow_exit_requested = false
	burrow_impact_sent = false
	collision_mask = 1
	air_jump = true
	combo = 0
	jump_buffer = 0
	coyote = 0
	wall_lock = 0
	dash_time = 0
	dash_cooldown = 0
	health = 100
	hurt_time = 0
	stamina = max_stamina
	mana = max_mana
	stamina_regen_wait = 0
	burrow_cooldown = 0
	trail.clear()
	set_low(false)

func set_low(low: bool) -> void:
	standing_shape.size.y = 20.0 if low else 38.0
	collider.position.y = 9.0 if low else 0.0

func can_stand() -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(25, 37)
	query.shape = shape
	query.transform = Transform2D(0, global_position)
	query.collision_mask = 1
	query.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(query):
		if not hit.collider.has_meta("one_way_platform"):
			return false
	return true

func clear_platform_drop() -> void:
	if is_instance_valid(dropped_platform):
		remove_collision_exception_with(dropped_platform)
	dropped_platform = null
	drop_timer = 0
	floor_snap_length = 7.0

func try_platform_drop() -> bool:
	if not is_on_floor() or burrowed:
		return false
	for i in get_slide_collision_count():
		var contact := get_slide_collision(i)
		var body := contact.get_collider() as PhysicsBody2D
		if body == null or not body.has_meta("one_way_platform") or contact.get_normal().y > -0.7:
			continue
		clear_platform_drop()
		dropped_platform = body
		add_collision_exception_with(body)
		drop_timer = 0.45
		drop_requires_release = true
		floor_snap_length = 0
		jump_buffer = 0
		coyote = 0
		position.y += 3
		velocity.y = 90
		return true
	return false

func launch(speed: float, kind: String) -> void:
	velocity.y = -speed
	jump_buffer = 0
	coyote = 0
	set_low(false)
	squash = Vector2(0.75, 1.3)
	feedback.emit(kind, position + Vector2(0, HALF_HEIGHT))

func bounce() -> void:
	combo += 1
	air_jump = true
	launch(jump_speed + minf(combo * 35.0, 150.0), "bounce")

func exit_burrow() -> void:
	if appearance.class_index==2 and not combat.active and combat.start():
		return
	var emerge_rect := Rect2(Vector2(position.x - 13, FLOOR_Y - 40), Vector2(26, 38))
	for block in world.blocks:
		if block.intersects(emerge_rect):
			state = "Exit blocked — move sideways"
			return
	burrowed = false
	begin_burrow_cooldown()
	collision_mask = 1
	position.y = FLOOR_Y - HALF_HEIGHT - 2
	air_jump = true
	launch(760.0, "emerge")

func take_damage(amount: int) -> bool:
	if invulnerable or hurt_time > 0 or amount <= 0: return false
	health = maxi(0,health-amount)
	hurt_time = 0.5
	feedback.emit("hurt",position)
	if health == 0: reset()
	return true

func start_dash() -> bool:
	if burrowed or dash_time > 0 or dash_cooldown > 0: return false
	if not spend_stamina(dash_stamina_cost): return false
	combat.cancel()
	var axis := Input.get_axis("left","right")
	dash_direction = axis if axis != 0 else facing
	facing = dash_direction
	dash_time = dash_duration
	dash_cooldown = dash_recharge
	jump_buffer = 0
	set_low(false)
	feedback.emit("dash",position)
	return true

func can_pay_stamina(amount: float) -> bool:
	return not stamina_enabled or stamina >= amount

func spend_mana(amount: float) -> bool:
	if amount < 0 or mana < amount:
		return false
	mana -= amount
	return true

func spend_stamina(amount: float) -> bool:
	if not can_pay_stamina(amount):
		state = "Not enough stamina"
		return false
	if stamina_enabled:
		stamina = maxf(0,stamina-amount)
		stamina_regen_wait = 0.9
	return true

func begin_burrow_cooldown() -> void:
	if stamina_enabled:
		burrow_cooldown = burrow_recharge

func tick_resources(dt: float) -> void:
	if not stamina_enabled:
		return
	mana = minf(max_mana,mana+mana_regen*dt)
	burrow_cooldown = maxf(0,burrow_cooldown-dt)
	stamina_regen_wait = maxf(0,stamina_regen_wait-dt)
	if burrowed:
		stamina = maxf(0,stamina-burrow_stamina_drain*dt)
		stamina_regen_wait = 0.9
		if stamina <= 0:
			burrow_exit_requested = true
	elif stamina_regen_wait <= 0 and not combat.active and dash_time <= 0:
		stamina = minf(max_stamina,stamina+stamina_regen*dt)

func tick_dash(dt: float) -> void:
	velocity = Vector2(dash_direction*dash_speed,0)
	move_and_slide()
	dash_time = maxf(0,dash_time-dt)
	if is_on_wall(): dash_time = 0
	if dash_time <= 0:
		var cruise_speed := mage_glide_speed if appearance.class_index == 2 else (warden_run_speed if appearance.class_index == 0 else run_speed)
		velocity.x = dash_direction*cruise_speed
	state = "Dash · invulnerable"
	trail.push_front(position)
	if trail.size()>10: trail.pop_back()
	queue_redraw()

func _physics_process(dt: float) -> void:
	if Input.is_action_just_pressed("reset"):
		reset()
	tick_resources(dt)
	if not Input.is_action_pressed("dig"):
		drop_requires_release = false
	if drop_timer > 0:
		drop_timer -= dt
		if not is_instance_valid(dropped_platform) or drop_timer <= 0:
			clear_platform_drop()
		elif position.y-HALF_HEIGHT > dropped_platform.global_position.y+12:
			clear_platform_drop()
	dash_cooldown = maxf(0,dash_cooldown-dt)
	hurt_time = maxf(0,hurt_time-dt)
	if Input.is_action_just_pressed("dash"): start_dash()
	if dash_time > 0:
		tick_dash(dt)
		return
	if combat.active:
		combat.tick(dt)
		return
	combat.idle_tick(dt)
	if Input.is_action_pressed("dig") and Input.is_action_just_pressed("jump") and try_platform_drop():
		move_and_slide()
		state = "Drop through"
		queue_redraw()
		return
	var axis := Input.get_axis("left", "right")
	if axis != 0:
		facing = axis
	jump_buffer = maxf(0, jump_buffer - dt)
	wall_lock = maxf(0, wall_lock - dt)
	squash = squash.lerp(Vector2.ONE, 1.0 - exp(-18 * dt))
	if Input.is_action_just_pressed("jump"):
		jump_buffer = buffer_duration
	if burrowed:
		burrow_time += dt
		var warden: bool = appearance.class_index == 0
		var entering: bool = warden and burrow_time < warden_burrow_entry
		if Input.is_action_just_released("dig") or jump_buffer > 0:
			burrow_exit_requested = true
		if warden and not burrow_impact_sent and burrow_time >= warden_burrow_entry * 0.42:
			burrow_impact_sent = true
			feedback.emit("burrow_impact", Vector2(position.x, FLOOR_Y))
		var underground_speed := warden_dig_speed if warden else dig_speed
		velocity.x = 0.0 if entering else move_toward(velocity.x,axis*underground_speed,acceleration*dt)
		position.x = clampf(position.x + velocity.x * dt, 55, 1225)
		position.y = FLOOR_Y + 25
		state = "Underground"
		if not entering and (burrow_exit_requested or not Input.is_action_pressed("dig") or jump_buffer > 0):
			exit_burrow()
		queue_redraw()
		return
	var grounded := is_on_floor()
	if grounded:
		coyote = coyote_duration
		air_jump = true
		combo = 0
	else:
		coyote = maxf(0, coyote - dt)
	if grounded and position.y > FLOOR_Y - 25 and Input.is_action_pressed("dig") and not drop_requires_release and burrow_cooldown <= 0 and can_pay_stamina(burrow_stamina_cost):
		spend_stamina(burrow_stamina_cost)
		burrowed = true
		burrow_time = 0
		burrow_exit_requested = false
		burrow_impact_sent = false
		collision_mask = 0
		set_low(false)
		feedback.emit("dig", position + Vector2(0, HALF_HEIGHT))
		return
	if can_stand(): set_low(false)
	else: set_low(true)
	if wall_lock <= 0:
		var warden: bool = appearance.class_index == 0
		var mage: bool = appearance.class_index == 2
		var top_speed := mage_glide_speed if mage else (warden_run_speed if warden else run_speed)
		var target := axis * top_speed
		var ground_accel := warden_acceleration if warden else acceleration
		if warden and axis == 0:
			ground_accel = warden_braking
		if mage:
			ground_accel = mage_braking if axis == 0 else mage_acceleration
		var accel := ground_accel if grounded else air_acceleration
		# Preserve excess momentum in the air when steering in its direction.
		if not grounded and axis != 0 and signf(velocity.x) == axis and absf(velocity.x) > top_speed:
			accel = 220
		velocity.x = move_toward(velocity.x, target, accel * dt)
	velocity.y = minf(velocity.y + gravity * dt, 1000)
	var wall_sliding := not grounded and is_on_wall() and axis != 0 and axis == -get_wall_normal().x
	if wall_sliding and velocity.y > 0:
		velocity.y = minf(velocity.y, 150)
	if jump_buffer > 0 and can_stand():
		if not grounded and is_on_wall():
			velocity.x = get_wall_normal().x * 440
			wall_lock = 0.16
			air_jump = true
			launch(jump_speed, "wall")
		elif coyote > 0:
			launch(jump_speed, "jump")
		elif air_jump:
			air_jump = false
			launch(jump_speed * 0.9, "air")
	if Input.is_action_just_released("jump") and velocity.y < -240:
		velocity.y = -240
	var previous_bottom := position.y + HALF_HEIGHT
	var falling_speed := velocity.y
	move_and_slide()
	if not grounded and is_on_floor():
		squash = Vector2(1.25, 0.78)
		if falling_speed > 240:
			feedback.emit("land", position + Vector2(0, HALF_HEIGHT))
	if velocity.y > 0:
		for enemy in world.targets:
			if absf(position.x - enemy.x) < 31 and previous_bottom <= enemy.y - 15 and position.y + HALF_HEIGHT >= enemy.y - 15:
				position.y = enemy.y - 15 - HALF_HEIGHT
				bounce()
				break
	if position.y > 900:
		reset()
	state = "Wall slide" if wall_sliding else ("Glide" if appearance.class_index == 2 and grounded and absf(velocity.x)>20 else ("Run" if grounded and absf(velocity.x) > 20 else ("Hover" if appearance.class_index == 2 and grounded else ("Grounded" if grounded else ("Rise" if velocity.y < 0 else "Fall")))))
	trail.push_front(position)
	if trail.size() > 10:
		trail.pop_back()
	queue_redraw()

func _draw() -> void:
	if dash_time > 0:
		for i in mini(trail.size(),6):
			var at := trail[i]-position
			draw_line(at+Vector2(-facing*18,-10),at+Vector2(facing*12,-10),Color(0.6,0.95,1,0.65-float(i)*0.08),2)
	if burrowed:
		var at := Vector2(0, -54)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-9, -8), at + Vector2(9, -8), at + Vector2(0, 2)]), Color("75edca"))
		draw_arc(Vector2.ZERO, 17, 0, TAU, 20, Color("75edca"), 2)
		return
	for i in range(trail.size()):
		if absf(velocity.x) > 380:
			draw_circle(trail[i] - position, 10 - i * 0.7, Color(0.35, 0.9, 0.76, 0.12 * (1.0 - i / 10.0)))
	if air_jump:
		draw_circle(Vector2(0, -46), 3, Color("eef6eb"))
