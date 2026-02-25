@icon("res://addons/proyect_icons/promissio_state_proyect_icon.png")

class_name PromissioStateConsec     extends PromissioStateBase

func start():
		# 💥 Reposicionar antes de lanzar el ataque
	promissio.snap_to_attack_position(promissio.previous_direction)
	# Animación visual (por ahora reutilizamos la misma del ataque)
	if promissio.attack_type == "A":
		promissio.animation_player.play( promissio.animations.Smear_Consec_A + promissio.previous_direction )
	else:
		promissio.animation_player.play( promissio.animations.Smear_Consec_B + promissio.previous_direction )

	promissio.current_symbol.symbol_effects.play("CONSEC")
	promissio.antici_consec_timer.start()

	# Esperamos que se complete
	await promissio.antici_consec_timer.timeout
	state_machine.change_to( states.Attacking )
