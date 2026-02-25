@icon("res://addons/proyect_icons/interactable_note_proyect_icon.png")

class_name NoteActionable    extends Area2D

# ==============================
# 📘 NOTAS / IMÁGENES
# ==============================
@export var note_names: Array[String] = []

# ==============================
# 💬 DIÁLOGO (fusionado)
# ==============================
@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = ""

# 🎭 CINEMÁTICA
@export var cinematic_name: String = ""
@export var cinematic_animation: String = ""

# ==============================
# ⚙️ CONFIG
# ==============================
@export var auto_trigger := false
@export var one_time := true

@onready var collisions := get_children().filter(func(c): return c is CollisionShape2D)

var pending_dialogue := false
var triggered := false


# ==============================
# 🚀 READY
# ==============================
func _ready() -> void:
	# ✅ Si ya se activó globalmente, desactivar
	if cinematic_name != "" and GlobalCinematicsState.cinematics_triggered.has(cinematic_name):
		triggered = true
		_disable_collisions()
		set_deferred("monitoring", false)

	if auto_trigger:
		body_entered.connect(_on_body_entered)

	# 🔗 Eventos
	NotesManager.note_opened.connect(_on_note_opened)
	NotesManager.note_closed.connect(_on_note_closed)
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


# ==============================
# 🧲 DETECCIÓN
# ==============================
func _on_body_entered(body: Node) -> void:
	if triggered:
		return
	if body.is_in_group("players"):
		action()


# ==============================
# 🎬 ACCIÓN PRINCIPAL
# ==============================
func action() -> void:
	if triggered and one_time:
		return

	if note_names.is_empty():
		push_warning("⚠️ No se asignaron notas.")
		return

	var player = PlayerManager.get_player()
	if not player:
		return

	# 🚫 Bloqueo total
	CinematicManager.start_cinematic(player)

	# 🎭 Animación opcional
	if cinematic_animation != "":
		CinematicManager.play_cinematic(player, cinematic_animation)
	else:
		CinematicManager.cinematic_idle()

	# 📝 Mostrar nota
	NotesManager.show_note_once(note_names)

	# 💬 Marcar diálogo como pendiente
	if dialogue_resource:
		pending_dialogue = true

	triggered = true

	if cinematic_name != "":
		GlobalCinematicsState.cinematics_triggered[cinematic_name] = true

	if one_time:
		call_deferred("_disable_collisions")

	if auto_trigger:
		call_deferred("set_monitoring", false)


# ==============================
# 💬 DIÁLOGO → BLOQUEO
# ==============================
func _on_dialogue_started(_res: DialogueResource) -> void:
	var player = PlayerManager.get_player()
	if player:
		CinematicManager.start_cinematic(player)

func _on_dialogue_ended(_res: DialogueResource) -> void:
	# ❗ NO cerramos cinemática aquí
	# Esperamos a que se cierre la nota
	pass


# ==============================
# 📘 NOTA CERRADA → FIN
# ==============================
func _on_note_closed() -> void:
	var player = PlayerManager.get_player()
	if player:
		CinematicManager.end_cinematic(player)


func _on_note_opened() -> void:
	if not pending_dialogue:
		return

	pending_dialogue = false
	DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)


# ==============================
# 🔧 COLISIONES
# ==============================
func _disable_collisions() -> void:
	for col in collisions:
		col.set_deferred("disabled", true)
	set_deferred("monitoring", false)
