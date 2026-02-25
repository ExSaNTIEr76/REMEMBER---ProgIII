extends StateBase

func start():
	controlled_node.animation_player.play("AttackDown")

func on_physics_process(_delta):
	var player = controlled_node.player
	if not player:
		return

	var to_player = (player.global_position - controlled_node.global_position)
	if to_player.length() > 200:
		state_machine.change_to("EnemyStateIdle")
		return

	controlled_node.move_direction = to_player.normalized()
	controlled_node.velocity = controlled_node.move_direction * controlled_node.speed
	controlled_node.move_and_slide()
	
	# Detectar colisión directa con el jugador
	var collision_count = controlled_node.get_slide_collision_count()
	for i in collision_count:
		var collision = controlled_node.get_slide_collision(i)
		if collision.get_collider() is Player:
			state_machine.change_to("EnemyStateCrashed")
			return
