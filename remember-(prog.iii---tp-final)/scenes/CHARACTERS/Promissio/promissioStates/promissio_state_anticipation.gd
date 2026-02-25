@icon("res://addons/proyect_icons/promissio_state_proyect_icon.png")

class_name PromissioStateAnticipation     extends PromissioStateBase

func start():
		# 💥 Reposicionar antes de lanzar el ataque
	promissio.snap_to_attack_position(promissio.previous_direction)
	# Elegimos la animación en base al último input (definilo desde el player o pásalo por variable)
	if promissio.attack_type == "A":
		promissio.animation_player.play( animations.Smear_Anticipation_A + promissio.previous_direction )
	else:
		promissio.animation_player.play( animations.Smear_Anticipation_B + promissio.previous_direction )

	promissio.antici_consec_timer.start()

	# Esperamos que se complete
	await promissio.antici_consec_timer.timeout
	state_machine.change_to( states.Attacking )
