#common_ghost_state_onrushing.gd:

extends EnemyStateBase

var is_charging := false
var player_positions := []
var prediction_frames := 20  # 🔁 Cuántas posiciones vamos a observar antes de cargar

func start():
	controlled_node.attack_area.monitoring = false
	controlled_node.enemy_animations.play(animations.onrushing)
	controlled_node.onrushing_timer.start()
	_charge_at_predicted_position()

	# ✅ Conectamos la detección de la hitbox
	var hitbox = controlled_node.get_node("Hitbox")
	if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.connect(_on_hitbox_area_entered)


func _find_player_direction_with_raycast() -> Vector2:
	var raycast = controlled_node.get_node("PlayerDetector")
	var angle_step := deg_to_rad(10)
	var best_direction := Vector2.ZERO

	for i in range(36):
		var angle = i * angle_step
		var direction = Vector2.RIGHT.rotated(angle)
		raycast.set_target_position(direction.normalized() * 100)
		raycast.force_raycast_update()

		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider and collider.name == "Hurtbox":
				# 👟 Detectamos posición más baja del Hurtbox
				var shape_node = collider.get_node_or_null("CollisionShape2D")
				if shape_node and shape_node.shape is RectangleShape2D:
					var rect_size = shape_node.shape.size
					var bottom_center = shape_node.global_position + Vector2(0, rect_size.y * 0.25)
					best_direction = (bottom_center - controlled_node.global_position).normalized()
				else:
					# Fallback si no hay shape (raro pero posible)
					best_direction = (collider.global_position - controlled_node.global_position).normalized()
				break

	return best_direction


func _charge_at_predicted_position():
	is_charging = true
	controlled_node.speed = 120.0

	var aimed_direction = _find_player_direction_with_raycast()

	if aimed_direction != Vector2.ZERO:
		# 🎯 Raycast encontró al player
		controlled_node.velocity = aimed_direction.normalized() * controlled_node.speed
	else:
		# 🤔 Predicción inteligente solo si el player se mueve
		var player_velocity = controlled_node.player.velocity
		var prediction_offset := Vector2.ZERO

		if player_velocity.length() > 10.0:
			prediction_offset = player_velocity.normalized() * 80.0

		var predicted_position = controlled_node.player.get_hurtbox_position() + prediction_offset
		var charge_direction = (predicted_position - controlled_node.global_position).normalized()

		# 💫 Suavizado con ruido mínimo
		charge_direction = (charge_direction + Vector2(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05))).normalized()
		controlled_node.velocity = charge_direction * controlled_node.speed


func on_physics_process(_delta):
	if not is_charging:
		return
	controlled_node.move_and_slide()

	# Timer fallback
	if not controlled_node.onrushing_timer.time_left:
		_transition_to_cooldown()


func _record_player_position():
	player_positions.append(controlled_node.player.get_hurtbox_position())

	if player_positions.size() >= prediction_frames:
		var last_pos = player_positions[-1]
		var charge_direction = (last_pos - controlled_node.global_position).normalized()
		charge_direction += Vector2(randf_range(-0.05, 0.05), randf_range(-0.05, 0.05))
		charge_direction = charge_direction.normalized()

		controlled_node.speed = 120.0
		controlled_node.velocity = charge_direction * controlled_node.speed
		is_charging = true


func _on_hitbox_area_entered(area: Area2D):
	if area.name == "Hurtbox" and area.get_parent() is Player:
		# 🛑 PERFECT GUARD CANCELA CRASHING
		if controlled_node.stunned_by_perfect_guard:
			return
		if state_machine.current_state.name == "EnemyStateOnrushing":
			is_charging = false
			controlled_node.velocity = Vector2.ZERO
			state_machine.change_to(states.Crashing)
		if area.name == "Hurtbox" and area.get_parent() is Player:
			if enemy.stats.CURRENT_HP <= 0:
				state_machine.change_to(states.Dead)
				return  # 👻 Ya está muerto, no ataca más


func _transition_to_cooldown():
	is_charging = false
	controlled_node.velocity = Vector2.ZERO
	state_machine.change_to(states.Cooldown)


func exit():
	var hitbox = controlled_node.get_node("Hitbox")
	if hitbox.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox.area_entered.disconnect(_on_hitbox_area_entered)
