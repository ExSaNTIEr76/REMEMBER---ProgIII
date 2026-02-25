#common_ghost_state_idle.gd:

extends EnemyStateBase

var can_trigger_charge := false

func start():
	can_trigger_charge = false
	controlled_node.attack_area.monitoring = true
	controlled_node.idle_timer.start(0.8)
	controlled_node.enemy_animations.play(animations.idle)

func on_physics_process(_delta):
	if controlled_node.cooldown_active or not controlled_node.idle_timer.is_stopped():
		return

	# 🔒 Si todavía no tenemos player asignado, no hacemos nada
	if controlled_node.player == null:
		return

	var to_player = controlled_node.player.global_position - controlled_node.global_position
	var direction = to_player.normalized() + Vector2(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
	controlled_node.velocity = direction.normalized() * (controlled_node.speed * 0.3)

	if controlled_node.has_seen_player_recently:
		state_machine.change_to(enemy.states.Charging)
