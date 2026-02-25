#common_ghost_state_hurt.gd:

extends EnemyStateBase

@onready var hurt_sounds: Array[AudioStreamPlayer2D] = [%HurtSound_1, %HurtSound_2]


func start():
	controlled_node.velocity = Vector2.ZERO
	controlled_node.enemy_animations.play(animations.hurt)
	play_random_2d(hurt_sounds, 0.15)

	# Esperamos que termine la animación
	await controlled_node.enemy_animations.animation_finished

	# Volvemos a Idle
	state_machine.change_to(states.Idle)


func play_random_2d(players: Array[AudioStreamPlayer2D], chance := 1.0):
	if randf() > chance:
		return
	if players.is_empty():
		return

	var p: AudioStreamPlayer2D = players.pick_random()
	if p.playing:
		return

	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()
	#USO: play_random_2d(hurt_sounds, 0.15)
