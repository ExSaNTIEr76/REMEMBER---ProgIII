@icon("res://addons/proyect_icons/puppet_state_proyect_icon.png")

class_name PlayerStateWalking    extends PlayerStateBase

func start():
	player.play_animation( player.animations.walk + player.previous_direction )

func on_physics_process( _delta ):
	player.move_direction = player.get_filtered_move_input()

	if player.move_direction == Vector2.ZERO:
		state_machine.change_to( player.states.Stop )
		return

	if Input.is_action_pressed( "ui_run" ) and ! PlayerManager.is_ill:
		state_machine.change_to( player.states.Running )
		return
	else:
		state_machine.change_to( player.states.Walking )

	# Usar PlayerManager para consultar speed
	var speed = player.get_stat( "speed" )
	if speed == null:
		speed = 40.0  # fallback por si no existe
	player.velocity = player.move_direction * float( speed )
	player.move_and_slide()

	var new_direction = DirectionHelper.get_direction_name( player.move_direction )
	if new_direction != player.previous_direction:
		player.previous_direction = new_direction
		player.play_animation( player.animations.walk + new_direction )
