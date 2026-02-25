@icon("res://addons/proyect_icons/puppet_state_proyect_icon.png")

class_name PlayerStateRunning    extends PlayerStateBase

func start():
	player.puppet_footstep.play( "footstep_run" )
	player.play_animation( player.animations.run + player.previous_direction )

func on_physics_process( _delta ):
	player.move_direction = player.get_filtered_move_input()

	if player.move_direction == Vector2.ZERO:
		player.puppet_footstep.play( "nothing" )
		state_machine.change_to( player.states.Stop )
		return

	if not Input.is_action_pressed( "ui_run" ):
		player.puppet_footstep.play( "nothing" )
		state_machine.change_to( player.states.Walking )
		return

	player.velocity = player.move_direction * ( player.get_stat( "speed" ) * player.get_stat( "running_speed_multiplier" ) )
	player.move_and_slide()

	var new_direction = DirectionHelper.get_direction_name( player.move_direction )

	if new_direction != player.previous_direction:
		player.previous_direction = new_direction
		player.play_animation( player.animations.run + new_direction )
