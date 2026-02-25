@icon("res://addons/proyect_icons/promissio_state_proyect_icon.png")

class_name PromissioStateRecovery     extends PromissioStateBase

func start():
	# Elegimos la animación en base al último input (definilo desde el player o pásalo por variable)
	if promissio.attack_type == "A":
		promissio.animation_player.play( animations.Smear_Recovery_A + promissio.previous_direction )
	else:
		promissio.animation_player.play( animations.Smear_Recovery_B + promissio.previous_direction )

	# 🔒 Iniciar el timer que bloquea nuevos ataques
	promissio.recovery_timer.start()

	# Esperamos que se complete
	await promissio.recovery_timer.timeout

	# Volver a Idle cuando termine el recovery
	state_machine.change_to( states.Idle )
