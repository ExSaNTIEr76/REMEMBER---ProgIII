@icon("res://addons/proyect_icons/promissio_state_proyect_icon.png")

class_name PromissioStateIdle    extends PromissioStateBase

var float_speed := 60.0
var smoothness := 6.0
var float_amplitude := 5.0
var float_frequency := 2.0
var desired_position := Vector2.ZERO

func start():
	controlled_node.animation_player.play(animations.Idle)

	# Reinicia el temporizador de inactividad
	if controlled_node.has_node("VanishTimer"):
		controlled_node.get_node("VanishTimer").call_deferred("start")

func on_physics_process(delta):
	if not controlled_node.player:
		return

	var facing = controlled_node.player.move_direction
	if facing == Vector2.ZERO:
		match controlled_node.player.previous_direction:
			"Up": facing = Vector2.UP
			"Down": facing = Vector2.DOWN
			"Left": facing = Vector2.LEFT
			"Right": facing = Vector2.RIGHT
			_: facing = Vector2.LEFT

	var offset: Vector2 = -facing.normalized() * 16
	offset += Vector2(0, -12)
	desired_position = controlled_node.player.global_position + offset

	var direction = (desired_position - controlled_node.global_position)
	controlled_node.global_position += direction * delta * smoothness

	var oscillation = sin(Time.get_ticks_msec() / 1000.0 * float_frequency) * float_amplitude
	controlled_node.global_position.y += oscillation * delta
