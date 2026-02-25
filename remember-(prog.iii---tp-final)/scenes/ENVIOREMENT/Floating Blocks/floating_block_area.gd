class_name FloatingBlockArea    extends Area2D

var player_in_area: bool = false
@export var one_time: bool = true
var triggered: bool = false

var parent_block: FloatingBlock = null


func _ready():
	connect("body_entered", _on_body_entered)
	connect("body_exited", _on_body_exited)

func _on_body_entered(body: Node) -> void:
	if triggered:
		return

	if body.name == "Player" or body.is_in_group( "players" ):  # seguridad por si acaso
		action()

func _on_body_exited(body: Node):
	if body.is_in_group("players"):
		player_in_area = false

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_interact") and player_in_area:
		var parent = get_parent()
		if parent and parent.has_method("action"):
			parent.action()

func action():
	if triggered and one_time:
		return

	var parent = get_parent()
	if parent and parent is FloatingBlock:
		var player = get_tree().get_first_node_in_group("players") as Player
		if player:
			player.state_machine.change_to(player.states.Interact)
			await get_tree().process_frame  # Esperamos 1 frame para que el cambio de estado ocurra
			if player.state_machine.current_state.has_method("using_block"):
				player.state_machine.current_state.using_block()

		# Alternamos entre estados del bloque
		parent.advance_state()

		var puzzle := parent.get_parent() as SimpleBlocksPuzzle
		if puzzle:
			puzzle.register_block_press(parent.block_number)

	triggered = true


func reset_trigger():
	triggered = false
