#common_ghost_state_crashing.gd:

extends EnemyStateBase

@onready var laugh_sounds: Array[AudioStreamPlayer2D] = [%LaughSound_1, %LaughSound_2]


func start():
	play_random_2d(laugh_sounds, 0.45)
	controlled_node.speed = 50.0  # 🌙 En enfriamiento o recuperación
	controlled_node.attack_area.set_deferred("monitoring", false)
	controlled_node.enemy_animations.play(animations.crashing)

	# Duración real del estado (ya seteaste a 2.0 seg en el Timer del nodo)
	controlled_node.crashing_timer.start()

	if controlled_node.player:
		var recoil_dir = (controlled_node.global_position - controlled_node.player.global_position).normalized()
		var target_pos = controlled_node.global_position + recoil_dir * 60.0  # Más lejos = más volatilidad

		# Tween más largo y etéreo
		var tween = controlled_node.create_tween()
		tween.set_trans(Tween.TRANS_SINE)  # Menos bouncy, más fluido
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(controlled_node, "global_position", target_pos, 0.6)

		# Flash fantasmal
		var sprite = controlled_node.get_node("Sprite2D")
		var flash = controlled_node.create_tween()
		flash.set_trans(Tween.TRANS_SINE)
		flash.set_ease(Tween.EASE_IN_OUT)
		flash.tween_property(sprite, "modulate", Color(1, 1, 1, 0.2), 0.15)
		flash.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3)


func _on_Hitbox_area_entered(area):
	if area.name == "Hurtbox" and area.get_parent() is Player:
		if enemy.stats.CURRENT_HP <= 0:
			state_machine.change_to(states.Dead)
			return  # 👻 Ya está muerto, no ataca más
		print("¡Le pegué al player!")
		var dd: DamageData = DamageData.new()
		dd.attribute = DamageData.AttributeType.STRIKE
		dd.base_damage = 1
		area.get_parent().take_damage(1, dd)


func on_physics_process(_delta):
	if controlled_node.crashing_timer.time_left == 0:
		state_machine.change_to(states.Idle)


func play_random_2d(players: Array[AudioStreamPlayer2D], chance := 1.0):
	if randf() > chance:
		return
	if players.is_empty():
		return

	var p: AudioStreamPlayer2D = players.pick_random()
	if p.playing:
		return

	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()
