#common_ghost_state_stunned.gd:

extends EnemyStateBase

@onready var stun_sounds: Array[AudioStreamPlayer2D] = [%HurtSound_1, %HurtSound_2]

@export var stun_time := 0.2

@export var recoil_distance := 45.0
@export var recoil_time := 0.35

func start():
	controlled_node.velocity = Vector2.ZERO
	controlled_node.vibrate_briefly()
	controlled_node.stunned_by_perfect_guard = false
	controlled_node.enemy_animations.play(animations.hurt)
	enemy.enemy_effects.play(animations.stunned_flash)
	play_random_2d(stun_sounds, 0.50)

	if controlled_node.player:
		var recoil_dir = (controlled_node.global_position - controlled_node.player.global_position).normalized()
		var target_pos = controlled_node.global_position + recoil_dir * recoil_distance

		var tween = controlled_node.create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(
			controlled_node,
			"global_position",
			target_pos,
			recoil_time
		)

	await get_tree().create_timer(stun_time).timeout
	state_machine.change_to(states.Cooldown)


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
