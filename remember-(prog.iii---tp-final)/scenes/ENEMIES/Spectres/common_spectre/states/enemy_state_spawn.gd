#common_ghost_state_spawn.gd

extends EnemyStateBase

@onready var spawn_sound: AudioStreamPlayer2D = %SpawnSound


func start():
	# 🚫 Desactivar colisiones de ataque/detección durante el spawn
	_play_spawn_sfx()
	controlled_node.attack_area.monitoring = false
	controlled_node.detection_area.monitoring = false
	
	# Reproducir animación de spawn
	controlled_node.enemy_animations.play(controlled_node.animations.spawn)
	controlled_node.enemy_effects.play(controlled_node.animations.spawn_flash)

	# Conectar al final de la animación
	controlled_node.enemy_animations.animation_finished.connect(_on_spawn_finished, CONNECT_ONE_SHOT)

func _on_spawn_finished(anim_name: String):
	if anim_name == controlled_node.animations.spawn:
		# ✅ Rehabilitamos colisiones
		controlled_node.attack_area.monitoring = true
		controlled_node.detection_area.monitoring = true

		# Pasar a Idle después del spawn
		state_machine.change_to(controlled_node.states.Idle)


func _play_spawn_sfx():
	if not spawn_sound:
		return

	if not spawn_sound.stream:
		return

	if spawn_sound.playing:
		return

	spawn_sound.pitch_scale = randf_range(0.95, 1.05)
	spawn_sound.play()
