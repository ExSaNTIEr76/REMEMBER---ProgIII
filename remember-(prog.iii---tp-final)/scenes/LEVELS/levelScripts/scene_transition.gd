# scene_transition.gd
extends CanvasLayer

@onready var animation_player: AnimationPlayer = $Control/AnimationPlayer
@onready var cinematic_animations: AnimationPlayer = $Control/CinematicAnimations
@onready var screen_animations: AnimationPlayer = $Control/ScreenAnimations


## 💡 Transición genérica por zona, menú o propósito
func fade_out( tag := "default" ) -> bool:
	var animation_name = tag + "_fade_out"
	if animation_player.has_animation( animation_name ):
		animation_player.play( animation_name )
		await animation_player.animation_finished
	else:
		print( "⚠️ No existe fade_out para:", tag )
		return false
	return true

func fade_in( tag := "default" ) -> bool:
	var animation_name = tag + "_fade_in"
	if animation_player.has_animation( animation_name ):
		animation_player.play( animation_name )
		await animation_player.animation_finished  # opcional
	else:
		print( "⚠️ No existe fade_in para:", tag )
		return false
	return true

# --------------------------------------------------------------------------------------------------

func fade_in_black() -> bool:
	animation_player.play( "black_fade_in" )
	await animation_player.animation_finished
	return true


func fade_in_black_noawait() -> bool:
	animation_player.play( "black_fade_in" )
	return true


func fade_out_black() -> bool:
	animation_player.play( "black_fade_out" )
	await animation_player.animation_finished
	return true

# --------------------------------------------------------------------------------------------------

func black_screen_on() -> bool:
	animation_player.play( "black_screen_on" )
	await animation_player.animation_finished
	return true

# --------------------------------------------------------------------------------------------------

func cinematic_fade_in_simple() -> bool:
	await get_tree().create_timer(0.2).timeout
	cinematic_animations.play( "cinematic_bars_fade_in" )
	return true


func cinematic_fade_in() -> bool:
	animation_player.play( "black_fade_out" )
	await animation_player.animation_finished
	await get_tree().create_timer(0.2).timeout
	animation_player.play( "black_fade_in" )
	cinematic_animations.play( "cinematic_bars_fade_in" )
	return true


func cinematic_fade_out() -> bool:
	animation_player.play( "black_fade_out" )
	await animation_player.animation_finished
	await get_tree().create_timer(0.2).timeout
	animation_player.play( "black_fade_in" )
	cinematic_animations.play( "cinematic_bars_fade_out" )
	return true

# --------------------------------------------------------------------------------------------------

func bars_fade_in() -> bool:
	cinematic_animations.play( "cinematic_bars_fade_in" )
	return true


func bars_fade_out() -> bool:
	cinematic_animations.play( "cinematic_bars_fade_out" )
	await get_tree().create_timer(0.2).timeout
	return true

# --------------------------------------------------------------------------------------------------

func white_flash() -> bool:
	screen_animations.play( "white_flash" )
	return true


func black_flash() -> bool:
	screen_animations.play( "black_flash" )
	return true
