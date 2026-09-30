extends "res://scripts/mage_combat.gd"
func cast() -> void:
	var origin: Vector2=actor.position+Vector2(direction*28,-28)
	if element==3:
		var reach := 100.0+combo_index*45
		for enemy in actor.world.combat_targets:
			var delta: Vector2=enemy.position-origin
			if enemy.health>0 and delta.x*direction>=0 and absf(delta.x)<reach and absf(delta.y)<80:
				var ray := actor.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(origin,enemy.position,1,[actor.get_rid()]))
				if not ray.is_empty(): continue
				enemy.regular_hit([8,10,14][combo_index-1])
				if combo_index==3: enemy.apply_element(3,direction)
		actor.world.flash_effect(origin,"earth",reach,direction)
		return
	var count := 1 if combo_index==1 else (3 if element==1 else 2)
	if combo_index==3: count=1
	for i in count:
		var shot := preload("res://scripts/class_sandbox/projectile.gd").new()
		shot.actor=actor
		shot.position=origin
		shot.velocity=Vector2(direction*(650 if element==2 else 470),0).rotated((i-(count-1)*0.5)*0.2)
		shot.element=element
		shot.finisher=combo_index==3
		shot.damage=15 if combo_index==3 else 7
		shot.kind=["fire","ice","wind"][element]
		actor.world.add_child(shot)
	if aerial and element==2: actor.velocity.y=-160
