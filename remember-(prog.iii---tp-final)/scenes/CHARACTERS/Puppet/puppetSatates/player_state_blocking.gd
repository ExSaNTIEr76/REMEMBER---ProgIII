@icon("res://addons/proyect_icons/puppet_state_proyect_icon.png")

class_name PlayerStateBlocking    extends PlayerStateBase

var exiting := false


func start():
	for state in [
		states.Idle, states.Walking, states.Running,
		states.AttackA, states.AttackB, states.Saving,
		states.Interact
	]:
		StateUnlockManager.lock_temporarily(player.character_id, state)

	exiting = false
	player.velocity = Vector2.ZERO

	player.shield_area.reset_guard()

	player.play_animation( player.animations.blocking + player.previous_direction )
	player.puppet_footstep.play( "nothing" )

	#await player.puppet_animations.animation_finished

	player.shield_area.monitoring = true
	player.shield_area.monitorable = true

	if is_instance_valid( player.promissio ):
		player.promissio.entering_block_fresh = true
		player.promissio.state_machine.change_to( player.promissio.states.Blocking )


func on_physics_process( _delta ):
	player.velocity = Vector2.ZERO
	player.move_and_slide()

	if not player.wants_to_guard and not exiting:
		exiting = true
		exit_blocking()


func exit_blocking():
	player.play_animation(
		player.animations.unblocking + player.previous_direction
	)

	await player.puppet_animations.animation_finished

	for state in [
		states.Idle, states.Walking, states.Running,
		states.AttackA, states.AttackB, states.Saving,
		states.Interact
	]:
		StateUnlockManager.unlock_temporarily(player.character_id, state)

	state_machine.change_to( player.states.Idle )


func force_exit():
	if exiting:
		return

	exiting = true
	player.wants_to_guard = false

	# ⚠️ FÍSICA → DEFERRED
	player.shield_area.set_deferred( "monitoring", false )
	player.shield_area.set_deferred( "monitorable", false )

	# Esperamos 1 frame para salir del flush de física
	await get_tree().process_frame

	exit_blocking()


func end():
	exiting = false
