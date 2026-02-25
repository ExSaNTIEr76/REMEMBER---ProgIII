@icon("res://addons/proyect_icons/elsen_state_proyect_icon.png")

class_name ElsenStateIdle    extends ElsenStateBase


func start():
	var anim_name := animations.idle + elsen.last_direction_name
	elsen.play_animation( anim_name )

	# 💡 Saltar a un punto aleatorio de la animación para desincronizar parpadeo
	if elsen.animation_player.has_animation( anim_name ):
		var anim_length := elsen.animation_player.get_animation( anim_name ).length
		var random_offset := randf_range( 0.0, anim_length )
		elsen.animation_player.seek( random_offset, true )

func on_physics_process( _delta ):
	if not elsen.is_static:
		state_machine.change_to( states.Walking )
