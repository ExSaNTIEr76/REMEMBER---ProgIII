class_name ShieldArea    extends Area2D

@export var perfect_guard_window := 0.05

@export var max_hits := 3

var player: Player
var guard_start_time := 0.0
var remaining_hits := 0


func _ready():
	player = get_parent() as Player
	monitoring = false
	monitorable = false


func try_block( attack_data: DamageData ) -> bool:
	if not player or not player.wants_to_guard:
		return false

	remaining_hits -= 1

	var now := Time.get_ticks_msec() / 1000.0
	var delta := now - guard_start_time

	# 🛡️ ESTE golpe SIEMPRE se bloquea
	if delta <= perfect_guard_window:
		_perfect_guard( attack_data )
	else:
		_normal_guard( attack_data )

	# 💥 Si era el último hit, rompemos DESPUÉS
	if remaining_hits <= 0:
		_break_guard()

	return true # ✅ ESTE GOLPE FUE BLOQUEADO


func _normal_guard( _attack_data ):
	AudioManager.play_sfx_path( "res://audio/SFX/Promissio SFX/impact/Sfx_Guard.ogg", 1.0, -3.0 )
	player.invulnerable = true
	player.grant_invulnerability( 0.15 )

	if is_instance_valid(player.promissio):
		player.shield_effects.play( "normal_guard" )


func _perfect_guard( attack_data: DamageData ):
	AudioManager.play_sfx_path("res://audio/SFX/Promissio SFX/impact/Sfx_Perfect_Guard.ogg", 1.0, -5.0 )

	if is_instance_valid( player.promissio ):
		remaining_hits += 1
		PlayerManager.modify_stat( "CP", 5 )
		player.promissio.pending_perfect_guard = true
		player.shield_effects.play( "perfect_guard" )
		player.puppet_effects.play( "Player_Perfect_Guard" )

	# 🧠 STUN AL ENEMIGO
	if attack_data and attack_data.source:
		if attack_data.source.has_method( "on_perfect_guarded" ):
			attack_data.source.on_perfect_guarded()

	player.invulnerable = true
	player.grant_invulnerability( 0.15 )

	Engine.time_scale = 0.15
	await get_tree().create_timer( 0.06, true, false, true ).timeout
	Engine.time_scale = 1.0


func _break_guard():
	AudioManager.play_sfx_path( "res://audio/SFX/Promissio SFX/impact/Sfx_Guard_Break.ogg", 1.0, -6.0 )
	player.invulnerable = true
	player.grant_invulnerability( 0.15 )

	player.wants_to_guard = false

	if player.has_method( "force_exit_blocking" ):
		player.force_exit_blocking()


	if is_instance_valid( player.promissio ):
		player.shield_effects.play( "guard_break" )
		player.promissio.state_machine.change_to( player.promissio.states.Shield_breaking )
	player.velocity = Vector2.ZERO
	_try_play_shield_break_sfx()
	player.state_machine.call_deferred( "change_to", player.states.Idle )


func _end_invulnerability():
	await get_tree().create_timer( 0.15 ).timeout
	player.invulnerable = false


func reset_guard():
	remaining_hits = max_hits
	guard_start_time = Time.get_ticks_msec() / 1000.0


func _try_play_shield_break_sfx():
	# Probabilidad de reproducir el sonido (0.0 = nunca, 1.0 = siempre)
	var chance := randf()
	if chance < 0.85: # ~0.80% de probabilidad
		# Elegimos un número aleatorio entre 1 y 3
		var sfx_path := "res://audio/SFX/Puppet SFX/talk/Sfx_Ciro 'What' 1.ogg"
		AudioManager.play_voice_path( sfx_path, 1.0, 0.0 )
