@icon("res://addons/proyect_icons/promissio_state_proyect_icon.png")

class_name PromissioStateBlocking  extends PromissioStateBase

var guard_active := false
var playing_perfect_guard := false


func start():
	guard_active = false
	playing_perfect_guard = false

	if promissio.pending_perfect_guard:
		promissio.pending_perfect_guard = false
	else:
		promissio.animation_player.play(promissio.animations.Shield_summoning)
		await promissio.animation_player.animation_finished

	if not promissio.player.wants_to_guard:
		state_machine.change_to(promissio.states.Idle)
		return

	promissio.animation_player.play(promissio.animations.Shield_idle)
	await promissio.animation_player.animation_finished
	guard_active = true



func on_process(_delta):
	if not guard_active:
		return

	if not promissio.player.wants_to_guard:
		guard_active = false
		promissio.animation_player.play(promissio.animations.Shield_vanishing)
		await promissio.animation_player.animation_finished
		promissio.snap_to_guard_position()
		state_machine.change_to(promissio.states.Idle)


func trigger_perfect_guard():
	if playing_perfect_guard:
		return

	playing_perfect_guard = true
	guard_active = false
	_play_perfect_guard()

func _play_perfect_guard() -> void:
	print("🔥 PERFECT GUARD CONFIRMADO")
	promissio.animation_player.play(promissio.animations.Shield_perfect_guard)
	#await promissio.animation_player.animation_finished



func end():
	guard_active = false
