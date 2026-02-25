#common_ghost_state_cooldown.gd:

extends EnemyStateBase

@onready var cooldown_sound_1: AudioStreamPlayer2D = %CooldownSound_1

@export var cooldown_duration := 2.0

func start():
	controlled_node.speed = 50.0  # 🌙 En enfriamiento o recuperación
	controlled_node.attack_area.monitoring = false
	controlled_node.velocity = Vector2.ZERO
	controlled_node.cooldown_timer.start(cooldown_duration)
	controlled_node.enemy_animations.play(animations.cooldown)
	controlled_node.is_committed_to_charge = false


func on_physics_process(_delta):
	if not controlled_node.cooldown_timer.time_left:
		state_machine.change_to(states.Idle)
