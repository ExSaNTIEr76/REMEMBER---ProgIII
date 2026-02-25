#common_ghost_state_dead.gd:

extends EnemyStateBase

@onready var death_sounds: Array[AudioStreamPlayer2D] = [%DeathSound_1, %DeathSound_2]


func start():
	controlled_node.velocity = Vector2.ZERO
	controlled_node.vibrate_briefly()

	var player := _play_random_sfx_detached()

	controlled_node.enemy_animations.play(animations.dead)

	await get_tree().create_timer(0.8).timeout
	controlled_node.queue_free()

	if player:
		await player.finished
		player.queue_free()



func _play_random_sfx_detached() -> AudioStreamPlayer2D:
	if death_sounds.is_empty():
		return null

	var p: AudioStreamPlayer2D = death_sounds.pick_random()
	if not p:
		return null

	p.get_parent().remove_child(p)
	get_tree().current_scene.add_child(p)

	p.global_position = controlled_node.global_position
	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()

	return p
