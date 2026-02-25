@icon("res://addons/proyect_icons/promissio_state_proyect_icon.png")

class_name PromissioStateShieldBreaking    extends PromissioStateBase

func start():
	promissio.snap_to_guard_position()

	promissio.animation_player.play(
		promissio.animations.Shield_breaking
	)

	await promissio.animation_player.animation_finished

	state_machine.change_to(promissio.states.Idle)
