@icon("res://addons/proyect_icons/puppet_state_proyect_icon.png")

class_name PlayerStateAttackB    extends PlayerStateBase


func start():
	if not is_instance_valid( player.promissio ):
		print( "⚠️ Promissio no está disponible para atacar." )
		state_machine.change_to( player.states.Idle )
		return

	# Ajustar dirección hacia enemy marcado
	var locked_enemy = PlayerManager.locked_enemy
	if locked_enemy and is_instance_valid( locked_enemy ):
		var to_enemy = locked_enemy.global_position - player.global_position
		var facing = to_enemy.normalized()
		player.set_facing_direction( facing )

	var current_state = player.promissio.state_machine.current_state

	if current_state and current_state.name == player.promissio.states.Sleeping:
		player.promissio.animation_player.play( "Idle" )
		player.puppet_footstep.play( "nothing" )
		await get_tree().create_timer( 0.001 ).timeout
		var symbol_scene = player.promissio.concrete_symbol_b
		if symbol_scene:
			var temp_symbol = symbol_scene.instantiate()
			var cp_cost: int = temp_symbol.cp_cost
			temp_symbol.queue_free()

			# ahora usamos PlayerManager.get_current_cp()
			if PlayerManager.get_current_cp() >= cp_cost:
				player.try_attack( "B" )
				player.velocity = Vector2.ZERO
				player.play_animation( player.animations.attackB + player.previous_direction, false )
				player.attack_b_timer.start()
			else:
				print( "❌ No hay CP suficiente para Attack B" )
				state_machine.change_to( player.states.Idle )


	if current_state and current_state.name == player.promissio.states.Idle:
		player.promissio.animation_player.play( "Idle" )
		player.puppet_footstep.play( "nothing" )
		var symbol_scene = player.promissio.concrete_symbol_b
		if symbol_scene:
			var temp_symbol = symbol_scene.instantiate()
			var cp_cost: int = temp_symbol.cp_cost
			temp_symbol.queue_free()

			# ahora usamos PlayerManager.get_current_cp()
			if PlayerManager.get_current_cp() >= cp_cost:
				player.try_attack( "B" )
				player.velocity = Vector2.ZERO
				player.play_animation( player.animations.attackB + player.previous_direction, false )
				player.attack_b_timer.start()
			else:
				print( "❌ No hay CP suficiente para Attack B" )
				state_machine.change_to( player.states.Idle )


func can_attack() -> bool:
	if player.promissio:
		var current_state = player.promissio.state_machine.current_state
		if current_state and current_state.name == player.promissio.states.Recovery:
			return false
	return true


func on_physics_process( _delta ):
	player.move_direction = player.get_filtered_move_input()
	player.velocity = Vector2.ZERO


func on_process( _delta ):
	if player.attack_b_timer.time_left == 0:
		state_machine.change_to( player.states.Idle )
