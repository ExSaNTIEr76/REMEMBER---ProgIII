@icon("res://addons/proyect_icons/puppet_state_proyect_icon.png")

class_name PlayerStateStop    extends PlayerStateBase

var has_played := false


func start():
	has_played = false

	var from_state := state_machine.previous_state
	var stop_anim_prefix := ""

	if from_state and from_state.name == player.states.Running:
		stop_anim_prefix = player.animations.stop_run
	else:
		stop_anim_prefix = player.animations.stop_walk

	var anim_name := stop_anim_prefix + player.previous_direction
	await player.play_animation( anim_name )


func on_physics_process( _delta ):
	player.velocity = Vector2.ZERO
	player.move_and_slide()

	if not player.puppet_animations.is_playing() and not has_played:
		has_played = true
		state_machine.change_to( player.states.Idle )


func on_input( _event ):
	if Input.is_action_pressed( "ui_left" ) or Input.is_action_pressed( "ui_right" ) or Input.is_action_pressed( "ui_up" ) or Input.is_action_pressed( "ui_down" ):
		state_machine.change_to( player.states.Walking )
