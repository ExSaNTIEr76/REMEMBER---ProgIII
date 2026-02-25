class_name ChestArea    extends Area2D

var player_in_area: bool = false
@onready var parent_chest := get_parent() # normalmente el TreasureChest

func _ready() -> void:
	# asegúrate de que el área esté monitorizando
	monitoring = true
	monitorable = true
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("players"):
		player_in_area = true
		# útil para debug
		# print("Player entered chest area:", parent_chest.name)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("players"):
		player_in_area = false

# El Player llama a action() directamente
func action() -> void:
	if parent_chest and parent_chest.has_method("action"):
		parent_chest.action()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_interact") and player_in_area:
		var parent = get_parent()
		if parent and parent.has_method("action"):
			parent.action()
