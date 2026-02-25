@icon("res://addons/proyect_icons/interactable_proyect_icon.png")
extends Node2D

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = ""
@export var cinematic_triggered: bool = false

func _ready() -> void:
	if cinematic_triggered:
		return

	await get_tree().process_frame  # Dejá que el nodo termine de inicializar

	# Nos conectamos a la señal del DialogueManager
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	# Iniciamos el diálogo
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)


func _on_dialogue_ended(_data = null) -> void:
	cinematic_triggered = true
	DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)
	cinematicEnded()


func cinematicEnded():
	print("🎬 Cinemática finalizada. Podés activar scripts, cámaras, enemigos, etc.")
