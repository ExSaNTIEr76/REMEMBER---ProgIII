@icon("res://addons/proyect_icons/promissio_state_proyect_icon.png")

class_name PromissioStateAttacking     extends PromissioStateBase

@onready var puppet_attack_sounds: Array[AudioStreamPlayer2D] = [%PuppetAttack_1, %PuppetAttack_2, %PuppetAttack_3]

func start():
	
	promissio.perform_attack( promissio.attack_type )

	# Temporizador y combo como base del estado
	promissio.attack_timer.start()
	promissio.combo_timer.start()

func on_process( _delta ):
	if not promissio.attack_timer.time_left:
		promissio.current_symbol.symbol_effects.play("ATTACK")
		promissio.state_machine.change_to( promissio.states.Recovery )

func on_input( event ):
	if event.is_action_pressed( "ui_attack_a" ) or event.is_action_pressed( "ui_attack_b" ):
		var input_type = "A" if event.is_action_pressed( "ui_attack_a" ) else "B"

		if promissio.combo_timer.time_left > 0.248:
			if input_type != promissio.attack_type:
				var success := promissio.player.continue_combo(input_type)

				if not success:
					return  # ⛔ combo cancelado totalmente

				play_random_2d(puppet_attack_sounds, 0.35)
				promissio.attack_type = input_type

				if promissio.current_symbol is cSymbolKnife:
					promissio.current_symbol.symbol_effects.play("CONSEC")
					promissio.state_machine.change_to(promissio.states.Consec)



func play_random_2d(players: Array[AudioStreamPlayer2D], chance := 1.0):
	if randf() > chance:
		return
	if players.is_empty():
		return

	var p: AudioStreamPlayer2D = players.pick_random()
	if p.playing:
		return

	p.play()
	#USO: play_random_2d(hurt_sounds, 0.15)


func exit():
	controlled_node.knife.visible = false
