#common_ghost_state_charging.gd:

extends EnemyStateBase

@onready var competence_sound: AudioStreamPlayer2D = %CompetenceSound

@export var attack_chance := 1.0  # 70% de las veces embiste


func start():
	# 🔒 Una vez que empieza a cargar, no hay vuelta atrás
	controlled_node.velocity = Vector2.ZERO
	controlled_node.is_committed_to_charge = true
	controlled_node.attack_area.set_deferred("monitoring", false)
	controlled_node.enemy_animations.play(animations.charging)
	competence_sound.play()
	controlled_node.enemy_effects.play(animations.cp_flash)

	#controlled_node.begin_flash_charge()
	controlled_node.charging_timer.start(1.0)

	await get_tree().create_timer(0.6).timeout
	controlled_node.vibrate_briefly()

	await controlled_node.charging_timer.timeout

	if enemy.stats.CURRENT_HP <= 0:
		state_machine.change_to(states.Dead)
		return  # 👻 Ya está muerto, no ataca más

	if randf() <= attack_chance:
		# Guardar dirección calculada UNA vez
		var player_velocity = controlled_node.player.velocity
		var prediction_offset = player_velocity.normalized() * 50.0
		var predicted_position = controlled_node.player.global_position + prediction_offset
		var dir = (predicted_position - controlled_node.global_position).normalized()
		dir += Vector2(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2))
		controlled_node.charge_direction = dir.normalized()
		controlled_node.is_committed_to_charge = true
		state_machine.change_to(states.Onrushing)
	else:
		controlled_node.start_cooldown(1.5)
		state_machine.change_to(states.Idle)
