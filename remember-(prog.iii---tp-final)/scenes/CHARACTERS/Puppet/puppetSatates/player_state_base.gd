class_name PlayerStateBase    extends StateBase

var player: Player:
	set(value): controlled_node = value
	get: return controlled_node

var states: PlayerStateNames = PlayerStateNames.new()
var animations: PlayerAnimations = PlayerAnimations.new()

func on_physics_process(_delta: float) -> void:
	if not player.input_enabled:
		player.velocity = Vector2.ZERO
		player.move_and_slide()
