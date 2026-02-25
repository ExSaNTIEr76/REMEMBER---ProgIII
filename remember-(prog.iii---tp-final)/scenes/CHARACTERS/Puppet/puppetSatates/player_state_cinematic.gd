@icon("res://addons/proyect_icons/puppet_state_proyect_icon.png")

class_name PlayerStateCinematic    extends PlayerStateBase

func start():
	print("🎬 Player entró en Cinematic")
	player.disable()
	player.puppet_footstep.play( "nothing" )
	player.velocity = Vector2.ZERO

	# Reiniciamos animación activa (para evitar mezcla con Idle)
	if player.puppet_animations.is_playing():
		player.puppet_animations.stop()
	player.current_animation = ""

	# 🔒 Bloqueamos estados que interfieren
	for state in [
		states.Idle, states.Walking, states.Running,
		states.AttackA, states.AttackB, states.Blocking,
		states.Hurt
	]:
		StateUnlockManager.lock_temporarily(player.character_id, state)


func end():
	print("🏃 Player salió de Cinematic")
	player.restore_movement()
	player.play_animation(player.animations.idle + player.previous_direction)


func on_physics_process(_delta: float) -> void:
	# Prevenimos movimiento por input
	player.velocity = Vector2.ZERO
	player.move_and_slide()
