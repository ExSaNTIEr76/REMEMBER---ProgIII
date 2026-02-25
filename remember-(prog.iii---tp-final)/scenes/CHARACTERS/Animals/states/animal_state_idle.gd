class_name AnimalStateIdle    extends AnimalStateBase


func start():
	var anim_name := animations.idle + animal.last_direction_name
	animal.play_animation( anim_name )

	# 💡 Saltar a un punto aleatorio de la animación para desincronizar parpadeo
	if animal.animation_player.has_animation( anim_name ):
		var anim_length := animal.animation_player.get_animation( anim_name ).length
		var random_offset := randf_range( 0.0, anim_length )
		animal.animation_player.seek( random_offset, true )


func on_physics_process( _delta ):
	if not animal.is_static:
		state_machine.change_to( states.Walking )
