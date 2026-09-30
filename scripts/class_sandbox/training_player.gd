extends "res://scripts/player.gd"
func refill() -> void:
	air_jump=true
	health=100
	mana=max_mana
	stamina=max_stamina
	dash_cooldown=0
	burrow_cooldown=0
	gem_cooldowns.assign([0.0,0.0])
func _physics_process(dt: float) -> void:
	refill()
	super._physics_process(dt)
	refill()
func tick_resources(_dt: float) -> void: refill()
func take_damage(_amount: int) -> bool: return false
func can_pay_stamina(_amount: float) -> bool: return true
func spend_stamina(_amount: float) -> bool: return true
func spend_mana(amount: float) -> bool: return amount>=0
func begin_burrow_cooldown() -> void: burrow_cooldown=0
func use_gem(index: int) -> bool:
	refill()
	# Renewal remains testable while invulnerable/full health.
	if index==1: health=75
	var used := super.use_gem(index)
	refill()
	return used
