@icon("res://addons/proyect_icons/puppet_state_proyect_icon.png")

class_name PlayerStateSaving    extends PlayerStateBase

func start():
	update_saving_animation()


func on_physics_process( _delta: float ) -> void:
	update_saving_animation()


func update_saving_animation():
	var box_state = GlobalConditions.floating_box_state
	var direction := player.previous_direction.to_lower()
	
	match box_state:
		0:
			pass
		1:
			await CinematicManager._wait( 0.1 )
			player.play_animation( player.animations.open_box + direction )
			await player.puppet_animations.animation_finished
		2:
			player.play_animation(player.animations.close_box + direction )
			await player.puppet_animations.animation_finished
			await CinematicManager._wait( 0.1 )
			state_machine.change_to( player.states.Idle )
