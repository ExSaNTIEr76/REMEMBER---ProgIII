@icon("res://addons/proyect_icons/puppet_state_proyect_icon.png")

class_name PlayerStateHurt    extends PlayerStateBase

@onready var hurt_sounds: Array[AudioStreamPlayer2D] = [%Hurt_1, %Hurt_2, %Hurt_3]


func start():
	# ❌ NO cinematic_idle
	player.velocity = Vector2.ZERO

	player.disable()

	for state in [
		states.Idle, states.Walking, states.Running,
		states.AttackA, states.AttackB, states.Blocking,
		states.Saving, states.Interact
	]:
		StateUnlockManager.lock_temporarily(player.character_id, state)

	player.puppet_footstep.play( "nothing" )
	play_random_2d( hurt_sounds, 0.85 )
	player.puppet_effects.play( "Player_Hit_Flash" )
	player.play_animation( player.animations.hurt + player.previous_direction )

	await player.puppet_animations.animation_finished

	# 🔓 LIMPIEZA TOTAL
	for state in [
		states.Idle, states.Walking, states.Running,
		states.AttackA, states.AttackB, states.Blocking,
		states.Saving, states.Interact
	]:
		StateUnlockManager.unlock_temporarily(player.character_id, state)

	player.enable()

	state_machine.call_deferred( "change_to", states.Idle )


func play_random_2d( players: Array[AudioStreamPlayer2D], chance := 1.0 ):
	if randf() > chance:
		return
	if players.is_empty():
		return

	var p: AudioStreamPlayer2D = players.pick_random()
	if p.playing:
		return

	p.play()
