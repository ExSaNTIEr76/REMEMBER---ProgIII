#NotesManager.gd (escena autoload):

extends CanvasLayer

signal note_opened
signal note_closed

@onready var notes: AnimatedSprite2D = $Control/Notes
@onready var notes_effects: AnimationPlayer = $NotesEffects

var player: Node = null

var current_index := 0
var note_queue: Array[String] = []
var note_visible := false
var read_once := false

# 📘 Notas leídas para el Diario
var read_notes: = {} # Set en GDScript (Dictionary usado como set)

func _ready():
	await _wait_for_player()
	hide()
	set_process_unhandled_input(false)

	notes_effects.animation_finished.connect(_on_notes_animation_finished)


# 🔁 Lectura repetible (no se marca como leída)
func show_note(note_names: Array[String]) -> void:
	if note_names.is_empty():
		push_warning("⚠️ No se proporcionaron nombres de notas.")
		return

	note_queue = note_names.duplicate()
	current_index = 0
	read_once = false

	if notes.sprite_frames.has_animation(note_queue[current_index]):
		PlayerManager.player.freeze_movement()
		AudioManager.play_sfx_path("res://audio/SFX/Enviorement/notes/Sfx_Note_Grab1.ogg", 1.0, -5.0)
		notes_effects.play("note_fade_in")  # 👈 AÑADIR ESTO
		notes.play(note_queue[current_index])
		note_visible = true
		show()
		set_process_unhandled_input(true)
	else:
		push_warning("⚠️ Animación no encontrada para nota: %s" % note_queue[current_index])


func _wait_for_player() -> void:
	var max_wait_frames := 120
	while (PlayerManager.player == null or not PlayerManager.player.is_inside_tree()) and max_wait_frames > 0:
		await get_tree().process_frame
		max_wait_frames -= 1

	player = PlayerManager.player
	if not player:
		push_error("❗ No se pudo encontrar al jugador.")


# 🕓 Lectura única (se marca como leída)
func show_note_once(note_names: Array[String]) -> void:
	if note_names.is_empty():
		push_warning("⚠️ No se proporcionaron nombres de notas.")
		return

	note_queue = note_names.duplicate()
	current_index = 0
	read_once = true

	for note_name in note_queue:
		read_notes[note_name] = true

	if notes.sprite_frames.has_animation(note_queue[current_index]):
		PlayerManager.player.freeze_movement()
		AudioManager.play_sfx_path("res://audio/SFX/Enviorement/notes/Sfx_Note_Grab1.ogg", 1.0, -5.0)
		notes_effects.play("note_fade_in")  # 👈 AÑADIR ESTO TAMBIÉN
		notes.play(note_queue[current_index])
		note_visible = true
		show()
		set_process_unhandled_input(true)
	else:
		push_warning("⚠️ Animación no encontrada para nota: %s" % note_queue[current_index])


func _on_notes_animation_finished(anim_name: String) -> void:
	if anim_name == "note_fade_in":
		note_opened.emit()


# 🎮 Interacción
func _unhandled_input(event: InputEvent) -> void:
	if not note_visible:
		return

	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		current_index += 1

		if current_index < note_queue.size():
			var next_note := note_queue[current_index]

			if notes.sprite_frames.has_animation(next_note):
				AudioManager.play_sfx_path("res://audio/SFX/Enviorement/notes/Sfx_Note_Grab1.ogg", 1.0, -5.0)
				notes_effects.play("note_fade_in")
				notes.play(next_note)

				if read_once:
					read_notes[next_note] = true  # 📌 Marcar como leída si es necesario
			else:
				push_warning("⚠️ Animación no encontrada para nota: %s" % next_note)
		else:
			_close_note()


func _close_note() -> void:
	PlayerManager.player.restore_movement()
	note_visible = false
	set_process_unhandled_input(false)
	notes_effects.play("note_fade_out")
	note_closed.emit()


# 📓 Para el Diario: obtener lista de notas leídas
func get_read_notes() -> Array[String]:
	return read_notes.keys()



##NotesManager.gd (escena autoload):
#
#extends CanvasLayer
#
#signal note_fade_in_finished
#signal note_closed
#
#@onready var notes: AnimatedSprite2D = $Control/Notes
#@onready var notes_effects: AnimationPlayer = $NotesEffects
#
#var player: Node = null
#
#var current_index := 0
#var note_queue: Array[String] = []
#var note_visible := false
#var read_once := false
#
## 📘 Notas leídas para el Diario
#var read_notes: = {} # Set en GDScript (Dictionary usado como set)
#
#func _ready():
	#await _wait_for_player()
	#hide()
	#set_process_unhandled_input(false)
#
## 🔁 Lectura repetible (no se marca como leída)
#func show_note(note_names: Array[String]) -> void:
	#if note_names.is_empty():
		#push_warning("⚠️ No se proporcionaron nombres de notas.")
		#return
#
	#note_queue = note_names.duplicate()
	#current_index = 0
	#read_once = false
#
	#if notes.sprite_frames.has_animation(note_queue[current_index]):
		#PlayerManager.player.freeze_movement()
		#AudioManager.play_sfx_path("res://audio/SFX/Enviorement/notes/Sfx_Note_Grab1.ogg", 1.0, -5.0)
#
		#notes_effects.play("note_fade_in")
		#await notes_effects.animation_finished
		#note_fade_in_finished.emit()
#
		#notes.play(note_queue[current_index])
		#note_visible = true
		#show()
		#set_process_unhandled_input(true)
	#else:
		#push_warning("⚠️ Animación no encontrada para nota: %s" % note_queue[current_index])
#
#
#func _wait_for_player() -> void:
	#var max_wait_frames := 120
	#while (PlayerManager.player == null or not PlayerManager.player.is_inside_tree()) and max_wait_frames > 0:
		#await get_tree().process_frame
		#max_wait_frames -= 1
#
	#player = PlayerManager.player
	#if not player:
		#push_error("❗ No se pudo encontrar al jugador.")
#
#
## 🕓 Lectura única (se marca como leída)
#func show_note_once(note_names: Array[String]) -> void:
	#if note_names.is_empty():
		#push_warning("⚠️ No se proporcionaron nombres de notas.")
		#return
#
	#note_queue = note_names.duplicate()
	#current_index = 0
	#read_once = true
#
	#for note_name in note_queue:
		#read_notes[note_name] = true
#
	#if notes.sprite_frames.has_animation(note_queue[current_index]):
		#PlayerManager.player.freeze_movement()
		#AudioManager.play_sfx_path("res://audio/SFX/Enviorement/notes/Sfx_Note_Grab1.ogg", 1.0, -5.0)
#
		#notes_effects.play("note_fade_in")
		#await notes_effects.animation_finished
		#note_fade_in_finished.emit()
#
		#notes.play(note_queue[current_index])
		#note_visible = true
		#show()
		#set_process_unhandled_input(true)
	#else:
		#push_warning("⚠️ Animación no encontrada para nota: %s" % note_queue[current_index])
#
#
## 🎮 Interacción
#func _unhandled_input(event: InputEvent) -> void:
	#if not note_visible:
		#return
#
	#if event.is_action_pressed("ui_accept"):
		#current_index += 1
#
		#if current_index < note_queue.size():
			#var next_note := note_queue[current_index]
#
			#if notes.sprite_frames.has_animation(next_note):
				#AudioManager.play_sfx_path("res://audio/SFX/Enviorement/notes/Sfx_Note_Grab1.ogg", 1.0, -5.0)
				#notes_effects.play("note_fade_in")
				#notes.play(next_note)
#
				#if read_once:
					#read_notes[next_note] = true  # 📌 Marcar como leída si es necesario
			#else:
				#push_warning("⚠️ Animación no encontrada para nota: %s" % next_note)
		#else:
			#_close_note()
#
#
#func _close_note() -> void:
	#PlayerManager.player.restore_movement()
	#note_visible = false
	#set_process_unhandled_input(false)
	#notes_effects.play("note_fade_out")
	#note_closed.emit()
#
#
## 📓 Para el Diario: obtener lista de notas leídas
#func get_read_notes() -> Array[String]:
	#return read_notes.keys()
