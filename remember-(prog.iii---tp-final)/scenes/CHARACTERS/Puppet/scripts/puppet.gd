@icon("res://addons/proyect_icons/puppet_proyect_icon.png")

class_name Player    extends CharacterBody2D

@export var skin: String = PlayerManager.skin
@export var is_ill: bool = false

@export var character_id: String = "Player"

@onready var collisions := get_children().filter( func( c ): return c is CollisionShape2D )

@onready var player_sprite: Sprite2D = $PlayerSprite
@onready var puppet_animations: AnimationPlayer = $PuppetAnimations
@onready var puppet_footstep: AnimationPlayer = $PuppetFootstep

@onready var puppet_effects: AnimationPlayer = $PuppetEffects
@onready var actionable_finder: Area2D = $Direction/ActionableFinder
@onready var hurtbox: Area2D = $Hurtbox
@onready var damage_numbers_origin: Node2D = $DamageNumbersOrigin

@onready var shield: Sprite2D = $PlayerSprite/Shield
@onready var shield_effects: AnimationPlayer = $ShieldEffects
@onready var shield_area: Area2D = $ShieldArea

var guard_start_time := 0.0
var wants_to_guard := false
var invulnerable := false
var _invul_timer: SceneTreeTimer = null

@onready var state_machine: StateMachine = $"STATE MACHINE"

@onready var attack_a_timer: Timer = $AttackATimer
@onready var attack_b_timer: Timer = $AttackBTimer
@onready var hurt_recovery_timer: Timer = $HurtRecoveryTimer

var promissio: Promissio
@export var input_enabled: bool = true

var states: PlayerStateNames = PlayerStateNames.new()
var animations: PlayerAnimations = PlayerAnimations.new()

var initialized := false

var move_direction: Vector2 = Vector2.ZERO
var is_running: bool = false
var colliding: bool = false

var direction := DirectionHelper.get_direction_name( move_direction )
var previous_direction: String = "Down"
var current_animation: String = ""
var next_animation: String = ""
var wait_for_animation_end: bool = false

signal health_updated( current_health: float )
signal cp_updated( current_cp: float )
signal ep_updated( current_ep: float )


func get_hud():
	if Engine.has_singleton( "PlayerHUD" ):
		return Engine.get_singleton( "PlayerHUD" )
	return null


func _unhandled_input( event: InputEvent ) -> void:
	if not input_enabled:
		return

	if event.is_action_pressed( "ui_interact" ) and not event.is_echo():
		var actionables = actionable_finder.get_overlapping_areas()
		if actionables.size() > 0 and actionables[0].has_method( "action" ):
			actionables[0].action()
			return

	elif event.is_action_pressed( "ui_mark" ) and not event.is_echo():
		PlayerManager.toggle_target_lock()

	elif event.is_action_pressed( "ui_attack_a" ) and not event.is_echo():
		if is_instance_valid( promissio ):
			if PlayerManager.stats.CURRENT_CP != 0 and state_machine.current_state.name != states.AttackA:
				state_machine.change_to( states.AttackA )
			else:
				return

	elif event.is_action_pressed( "ui_attack_b" ) and not event.is_echo():
		if is_instance_valid( promissio ):
			if PlayerManager.stats.CURRENT_CP != 0 and state_machine.current_state.name != states.AttackB:
				state_machine.change_to( states.AttackB )
			else:
				return

	elif event.is_action_pressed( "ui_guard" ) and not event.is_echo():
		if is_instance_valid( promissio ):
			wants_to_guard = true
			if state_machine.current_state.name != states.Blocking:
				state_machine.change_to( states.Blocking )

	elif event.is_action_released( "ui_guard" ):
		wants_to_guard = false


func disable(): input_enabled = false
func enable(): input_enabled = true


func get_stat( key: String ):
	return PlayerManager.get_stat( key )


func _enter_tree():
	add_to_group( "players" )

	if Engine.has_singleton( "PlayerHUD" ):
		Engine.get_singleton( "PlayerHUD" ).connect_to_player( self )


func _ready():
	await get_tree().process_frame

	# Aplicar facing si hay queued
	await get_tree().create_timer( 0.1 ).timeout
	if PlayerManager.desired_facing_direction != Vector2.ZERO:
		set_facing_direction( PlayerManager.desired_facing_direction )
		PlayerManager.desired_facing_direction = Vector2.ZERO

	apply_skin()
	_update_spritesheet()


	for state in [
		states.Idle, states.Walking, states.Running,
		states.Stop, states.Interact, states.Cinematic,
		states.Saving, states.Hurt
	]:
		StateUnlockManager.learn_state(character_id, state)


	if not puppet_animations.is_connected( "animation_finished", Callable( self, "_on_animation_finished" )):
		puppet_animations.connect( "animation_finished", Callable (self, "_on_animation_finished" ))

	# encontrar promissio en escena
	await get_tree().process_frame
	for node in get_tree().get_nodes_in_group( "promissio" ):
		if node is Promissio:
			promissio = node
			break

	# ✅ Registro de regeneración de CP — usar getters de PlayerManager
	if CPRegenerator.is_registered( self ):
		CPRegenerator.unregister( self )
	CPRegenerator.register( self,
		PlayerManager.get_max_cp(),
		PlayerManager.get_current_cp(),
		PlayerManager.get_cp_regen_rate(),
		1.0,
		func( cp ): _on_cp_updated( cp )
	)

	# HUD: ahora autoload
	var hud = get_hud()
	if hud:
		# PlayerHud.init_bars acepta dict o resource (lo adaptamos abajo)
		hud.init_bars( PlayerManager.get_stats_snapshot() )

	hurt_recovery_timer.wait_time = 0.6
	hurt_recovery_timer.one_shot = true

	# emitir estado inicial para listeners
	emit_signal( "health_updated", PlayerManager.get_current_hp() )
	emit_signal( "cp_updated", PlayerManager.get_current_cp() )
	emit_signal( "ep_updated", PlayerManager.get_current_ep() )

	# Si venimos de load, mostrar HUD etc
	if ThothGameState.loading_from_save and hud:
		if hud.has_method( "show_temporarily" ):
			hud.show_temporarily(3.0)
		if hud.has_method( "wait_until_cp_full" ):
			hud.wait_until_cp_full()

	if Engine.has_singleton( "DialogueManager" ):
		var dm = Engine.get_singleton( "DialogueManager" )
		dm.dialogue_started.connect( _on_dialogue_started )
		dm.dialogue_ended.connect( _on_dialogue_ended )

	initialized = true
	call_deferred("_restore_persistent_state")


func _exit_tree():
	if CPRegenerator.is_registered( self ):
		CPRegenerator.unregister( self )



#region MOVEMENT AND DIALOGUE

func _on_dialogue_started( _resource: DialogueResource ) -> void:
	#print( "🛑 Diálogo iniciado. Bloqueando movimiento." )
	freeze_movement()


func _on_dialogue_ended(_resource: DialogueResource) -> void:
	#print("✅ Diálogo terminado. Restaurando movimiento.")
	restore_movement()

	# 🔁 Cuando termina el diálogo, volvemos del cinematic idle
	if Engine.has_singleton( "CinematicManager" ):
		var cm = Engine.get_singleton( "CinematicManager" )
		cm.end_cinematic_idle()


func can_enter_state(state_name: String) -> bool:
	return StateUnlockManager.is_unlocked(character_id, state_name)


func freeze_movement():
	state_machine.change_to( states.Idle )
	disable()
	for state in [
		states.Idle, states.Walking, states.Running,
		states.AttackA, states.AttackB, states.Blocking,
		states.Hurt
	]:
		StateUnlockManager.lock_temporarily(character_id, state)


func restore_movement():
	enable()
	if PlayerManager.is_ill:
		for state in [
			states.Idle, states.Walking, states.Hurt
		]:
			StateUnlockManager.unlock_temporarily(character_id, state)
	else:
		for state in [
			states.Idle, states.Walking, states.Running,
			states.AttackA, states.AttackB, states.Blocking,
			states.Hurt
		]:
			StateUnlockManager.unlock_temporarily(character_id, state)

	# 🔁 Restauramos Idle normal al salir
	play_animation(animations.idle + previous_direction)


func is_state_unlocked( state_name: String ) -> bool:
	return StateUnlockManager.is_unlocked( character_id, state_name )


func get_filtered_move_input( deadzone := 0.3 ) -> Vector2:
	var raw_input := Input.get_vector( "ui_left", "ui_right", "ui_up", "ui_down" )
	var filtered_x := raw_input.x if abs( raw_input.x ) >= deadzone else 0.0
	var filtered_y := raw_input.y if abs( raw_input.y ) >= deadzone else 0.0
	return Vector2( filtered_x, filtered_y ).normalized()


func set_facing_direction( _direction: Vector2 ) -> void:
	move_direction = _direction.normalized()

	# Aseguramos que si no hay dirección, se mantiene la anterior (no la sobrescribimos con "Idle")
	if move_direction == Vector2.ZERO:
		return

	var dir_name := DirectionHelper.get_direction_name( move_direction )
	previous_direction = dir_name
	print( "🎯 Dirección establecida:", dir_name )

	# 🔁 Reproducimos animación solo si estamos en Idle o Stop
	if state_machine.current_state.name in [ states.Idle, states.Stop ]:
		play_animation( animations.idle + previous_direction )


func _enable_collisions() -> void:
	for col in collisions:
		col.disabled = false


func _play_footstep():
	FootstepSoundManager.play_footstep( global_position )

#endregion


#region HABILITIES

@onready var visibility = $PlayerSprite/PlayerVision
@onready var vAnimation = $PlayerSprite/PlayerVision/vCampusAnimations

func show_light( force: bool = false ) -> void:
	visibility.show()
	vAnimation.play( "pLight_fade_In" )
	PlayerManager.light_persistent = true if force else PlayerManager.light_persistent

func hide_light( force: bool = false ) -> void:
	# ⚡ Ahora si es `force = true`, ignora la persistencia
	if PlayerManager.light_persistent and not force:
		print("⚡ Se intentó apagar la luz, pero está en modo persistente. Se mantiene encendida.")
		return

	vAnimation.play( "pLight_fade_Out" )
	await vAnimation.animation_finished
	visibility.hide()
	PlayerManager.light_persistent = false


func is_guarding() -> bool:
	return wants_to_guard and shield_area.monitoring


func force_exit_blocking():
	if state_machine.current_state.name == states.Blocking:
		var blocking_state := state_machine.current_state
		if blocking_state.has_method( "force_exit" ):
			blocking_state.force_exit()


func grant_invulnerability( time: float ) -> void:
	invulnerable = true

	if _invul_timer:
		_invul_timer.timeout.disconnect( _end_invulnerability )

	_invul_timer = get_tree().create_timer( time )
	_invul_timer.timeout.connect( _end_invulnerability )

func _end_invulnerability():
	invulnerable = false
	_invul_timer = null

#endregion


#region ATTACK/CP

func _on_ep_updated( ep: int ) -> void:
	var hud = get_hud()
	PlayerManager.stats.CURRENT_EP = ep
	ep_updated.emit( ep )
	if hud and hud.has_method( "wait_until_cp_full" ):
		hud.wait_until_cp_full()


func _on_cp_updated( cp: int ) -> void:
	# centralizamos en PlayerManager
	PlayerManager.set_current_cp( int( cp ))
	emit_signal( "cp_updated", PlayerManager.get_current_cp() )
	var hud = get_hud()
	if hud and hud.has_method( "wait_until_cp_full" ):
		hud.wait_until_cp_full()


func spend_cp( amount: int ) -> bool:
	if PlayerManager.get_current_cp() >= amount:
		PlayerManager.set_current_cp( PlayerManager.get_current_cp() - amount )
		emit_signal( "cp_updated", PlayerManager.get_current_cp() )
		CPRegenerator.update_current_cp( self, PlayerManager.get_current_cp() )
		CPRegenerator.reset_regen_delay( self, 1.0 )
		return true
	return false


func can_attack() -> bool:
	return not ( promissio and promissio.state_machine.current_state.name == "Recovery" )


func try_attack( attack_type: String ) -> void:
	if not can_attack():
		return

	var symbol_scene := promissio.concrete_symbol_a if attack_type == "A" else promissio.concrete_symbol_b
	if symbol_scene:
		var temp_symbol := symbol_scene.instantiate()
		var cp_cost: int = temp_symbol.cp_cost
		temp_symbol.queue_free()

		if spend_cp( cp_cost ):
			promissio.attack_type = attack_type
			promissio.previous_direction = previous_direction
			promissio.state_machine.change_to( promissio.states.Anticipation )
		else:
			print( "⚡ No hay suficiente CP para atacar." )

	if PlayerHUD and PlayerHUD.has_method( "show_temporarily" ):
		PlayerHUD.show_temporarily()

	if PlayerHUD and PlayerHUD.has_method( "wait_until_cp_full" ):
		PlayerHUD.wait_until_cp_full()


func continue_combo( attack_type: String ) -> bool:
	var symbol_scene := promissio.concrete_symbol_a if attack_type == "A" else promissio.concrete_symbol_b
	if not symbol_scene:
		return false

	var temp_symbol := symbol_scene.instantiate()
	var cp_cost: int = temp_symbol.cp_cost
	temp_symbol.queue_free()

	if not spend_cp(cp_cost):
		print( "⚡ No hay suficiente CP para continuar el combo." )
		return false

	play_animation(
		"Attack" + attack_type + "/Attack" + attack_type + "_" + previous_direction,
		false
	)

	if attack_type == "A":
		attack_a_timer.start()
	else:
		attack_b_timer.start()

	if PlayerHUD and PlayerHUD.has_method( "show_temporarily" ):
		PlayerHUD.show_temporarily()

	if PlayerHUD and PlayerHUD.has_method( "wait_until_cp_full" ):
		PlayerHUD.wait_until_cp_full()
	
	return true


#endregion


#region HURT

func get_hurtbox_position() -> Vector2:
	return $Hurtbox.global_position


func take_damage( amount: int, attack_data: DamageData = null ) -> void:
	if hurt_recovery_timer.time_left > 0:
		return

	if not attack_data:
		attack_data = DamageData.new()
		attack_data.attribute = DamageData.AttributeType.STRIKE
		attack_data.base_damage = amount

	print("🎵 ImpactSounds llamado con:", attack_data, attack_data.attribute)
	ImpactSounds.play_from_attack( attack_data, PlayerManager.get_stats_snapshot() )

	PlayerManager.set_current_hp( PlayerManager.get_current_hp() - amount )
	emit_signal( "health_updated", PlayerManager.get_current_hp() )
	show_hit_numbers( amount )
	hurt_recovery_timer.start()

	var hud = PlayerHUD

	if amount >= 20:
		var cam := get_viewport().get_camera_2d()
		if cam and cam.has_method( "shake" ):
			cam.shake(0.2, 4.0, amount)
	else:
		if hud and hud.has_method( "on_player_damaged" ):
			hud.on_player_damaged()


	if PlayerManager.get_current_hp() <= 0:
		PlayerManager.on_player_died()
		return
	else:
		state_machine.call_deferred( "change_to", states.Hurt )


	if hud and hud.has_method( "on_player_damaged" ):
		hud.on_player_damaged()


func show_hit_numbers( damage: int ) -> void:
	DamageNumbers.display_number( damage, damage_numbers_origin.global_position, true )


func _on_status_changed():
	if PlayerManager.stats.CURRENT_ALTERED_STATE == DamageData.StatusEffect.MIGRAINE:
		PlayerManager.set_ill_state(true)

		for state in [states.Running, states.AttackA, states.AttackB]:
			StateUnlockManager.lock_temporarily(character_id, state)
	else:
		PlayerManager.set_ill_state(false)

		for state in [states.Running, states.AttackA, states.AttackB]:
			StateUnlockManager.unlock_temporarily(character_id, state)


func _restore_persistent_state():
	set_ill_state(PlayerManager.is_ill)

#endregion


#region ANIMATIONS

func play_animation( anim_name: String, wait: bool = false ):
	if anim_name == current_animation:
		return

	if wait and puppet_animations.is_playing():
		next_animation = anim_name
		wait_for_animation_end = true
	else:
		puppet_animations.play( anim_name )
		current_animation = anim_name
		wait_for_animation_end = false
		next_animation = ""


func _on_animation_finished( _anim_name: String ) -> void:
	if wait_for_animation_end and next_animation != "":
		puppet_animations.play( next_animation )
		current_animation = next_animation
		wait_for_animation_end = false
		next_animation = ""


func _update_spritesheet():
	var base_path := "res://scenes/CHARACTERS/Puppet/sprites/"

	# Detecta si el player está en modo Ill:
	var prefix := "Ciro_ill_" if is_ill else "Ciro_"

	# Construye el nombre del archivo correcto:
	var texture_path := base_path + prefix + skin + "_spritesheet.png"

	var tex := load( texture_path )
	if tex:
		var sprite := player_sprite
		sprite.texture = tex
	else:
		push_error( "❌ Spritesheet no encontrada: " + texture_path )


func apply_skin():
	var base_path := "res://scenes/CHARACTERS/Puppet/sprites/"
	var prefix := "Ciro_ill_" if is_ill else "Ciro_"
	var tex := load( base_path + prefix + skin + "_spritesheet.png" )

	if tex:
		var sprite := player_sprite
		sprite.texture = tex
	else:
		push_error( "❌ Spritesheet no encontrada para skin: " + skin )


func apply_ill_state():
	apply_skin()


func set_ill_state(value: bool):
	is_ill = value
	apply_skin()

	if value:
		for state in [states.Running, states.AttackA, states.AttackB]:
			StateUnlockManager.lock_temporarily(character_id, state)
	else:
		for state in [states.Running, states.AttackA, states.AttackB]:
			StateUnlockManager.unlock_temporarily(character_id, state)


#endregion
