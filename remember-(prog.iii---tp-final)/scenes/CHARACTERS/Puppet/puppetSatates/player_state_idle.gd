@icon("res://addons/proyect_icons/puppet_state_proyect_icon.png")

class_name PlayerStateIdle    extends PlayerStateBase

func start():
	var locked_enemy = PlayerManager.locked_enemy

	if locked_enemy and is_instance_valid( locked_enemy ):
		var to_enemy = locked_enemy.global_position - player.global_position
		var facing = to_enemy.normalized()
		player.set_facing_direction( facing )

	# ✅ Validación de fallback si previous_direction no es válida
	if not [ "Up", "Down", "Left", "Right", "DownRight", "DownLeft", "UpRight", "UpLeft" ].has( player.previous_direction ):
		player.previous_direction = "Down"

	player.play_animation( player.animations.idle + player.previous_direction )


func on_physics_process( _delta ):
	player.move_direction = player.get_filtered_move_input()
	player.velocity = Vector2.ZERO
	player.move_and_slide()


func on_input( _event ):
	# Si se presiona cualquier tecla de movimiento, cambia al estado Walking
	if Input.is_action_pressed( "ui_left" ) or Input.is_action_pressed( "ui_right" ) or Input.is_action_pressed( "ui_up" ) or Input.is_action_pressed( "ui_down" ): 
			# Si además se mantiene "ui_run", cambiar a Running
			if Input.is_action_pressed( "ui_run" ):
				state_machine.change_to( player.states.Running )
			else:
				state_machine.change_to( player.states.Walking )
