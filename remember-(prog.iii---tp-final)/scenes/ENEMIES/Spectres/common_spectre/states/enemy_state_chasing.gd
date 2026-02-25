#common_ghost_state_chasing.gd:

extends StateBase

var charge_cooldown := 3.0
var charge_timer := 0.0
var is_charging := false

func start():
	controlled_node.animation_player.play("AttackDown")
	charge_timer = charge_cooldown
	is_charging = false

func _charge_at_predicted_position():
	is_charging = true

	# Calculamos posición adelantada
	var player_velocity = controlled_node.player.velocity
	var prediction_offset = player_velocity.normalized() * 50.0 # 50 px adelantado

	var predicted_position = controlled_node.player.global_position + prediction_offset
	var charge_direction = (predicted_position - controlled_node.global_position).normalized()

	# Velocidad de embestida
	var charge_speed = controlled_node.speed * 3
	controlled_node.velocity = charge_direction * charge_speed

	# Cancelar la embestida luego de 0.5 segundos
	await get_tree().create_timer(0.5).timeout
	is_charging = false

func on_physics_process(delta):
	var player = controlled_node.player
	if not player:
		return

	var to_player = player.global_position - controlled_node.global_position

	# Volver al idle si se aleja demasiado
	if to_player.length() > 200:
		state_machine.change_to("EnemyStateIdle")
		return

	# Chequeamos colisión directa con el jugador
	var collision = controlled_node.move_and_collide(to_player.normalized() * controlled_node.speed * delta)
	if collision and collision.get_collider() is Player:
		state_machine.change_to("EnemyStateCrashing")
		return

	# Si no hay colisión, movimiento normal
	controlled_node.move_direction = to_player.normalized()
	controlled_node.velocity = controlled_node.move_direction * controlled_node.speed
	controlled_node.move_and_slide()

	# Embestida cada 3 segundos
	charge_timer -= delta
	if charge_timer <= 0:
		_charge_at_predicted_position()
		charge_timer = charge_cooldown
