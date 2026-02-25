@icon("res://addons/proyect_icons/puppet_state_proyect_icon.png")

class_name PlayerStateInteract    extends PlayerStateBase


func using_block():
	var direction := player.previous_direction.to_lower()
	
	player.puppet_footstep.play( "nothing" )
	player.play_animation( player.animations.open_box + direction )
	await player.puppet_animations.animation_finished
	player.play_animation( player.animations.close_box + direction )
	await player.puppet_animations.animation_finished
	state_machine.change_to( player.states.Idle )
