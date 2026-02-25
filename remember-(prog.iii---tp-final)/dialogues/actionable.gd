@icon("res://addons/proyect_icons/interactable_proyect_icon.png")

class_name Actionable    extends Area2D

@onready var collisions := get_children().filter(func(c): return c is CollisionShape2D)

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = ""

@export var auto_trigger: bool = false
@export var one_time: bool = true

@export var cinematic_name: String = ""

@export var cinematic_animation: String = ""

var triggered: bool = false


func _ready() -> void:
	# Si ya se registró la cinemática, desactivar permanentemente colisiones
	if cinematic_name != "" and GlobalCinematicsState.cinematics_triggered.has(cinematic_name):
		triggered = true
		_disable_collisions()
		set_deferred("monitoring", false) # no volver a detectar
	else:
		# Si se está en one_time, lo dejam listo para desactivar tras reproducirse
		_enable_collisions()

	if auto_trigger:
		connect("body_entered", Callable(self, "_on_body_entered"))

	# Enganche con el diálogo global
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_body_entered(body: Node) -> void:
	if triggered:
		return
	if body.is_in_group("players"):
		action()


func action() -> void:
	if triggered and one_time:
		return

	var player = PlayerManager.get_player()
	if not player:
		return

	# Inicia cinemática (bloquea movimiento + estados)
	CinematicManager.start_cinematic(player)

	# Activam animación cinemática
	if cinematic_animation != "":
		CinematicManager.play_cinematic(player, cinematic_animation)
	else:
		CinematicManager.cinematic_idle()

	# Dispara el diálogo
	if dialogue_resource:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
		triggered = true

		# Registra estado global
		if cinematic_name != "":
			GlobalCinematicsState.cinematics_triggered[cinematic_name] = true

		# Si es one-time → desactivar colisiones
		if one_time:
			call_deferred("_disable_collisions")

	if auto_trigger:
		call_deferred("set_monitoring", true)


func _on_dialogue_started(_res: DialogueResource) -> void:
	var player = PlayerManager.get_player()
	if player:
		CinematicManager.start_cinematic(player)


func _on_dialogue_ended(_res: DialogueResource) -> void:
	var player = PlayerManager.get_player()
	if player:
		CinematicManager.end_cinematic(player)



# ==============================
# 🔧 Helpers para colisiones
# ==============================


func _disable_collisions() -> void:
	for col in collisions:
		col.set_deferred("disabled", true)
	set_deferred("monitoring", false)


func _enable_collisions() -> void:
	for col in collisions:
		col.disabled = false
