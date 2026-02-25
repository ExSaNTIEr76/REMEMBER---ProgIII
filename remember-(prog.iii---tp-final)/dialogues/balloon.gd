#ballon.gd:
@icon("res://addons/proyect_icons/dialogue_balloon_proyect_icon.png")
extends CanvasLayer
## A basic dialogue balloon for use with Dialogue Manager.

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## The dialogue resource
var resource: DialogueResource

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false:
	set(value):
		is_waiting_for_input = value
		indicator.visible = value
	get:
		return is_waiting_for_input

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

var _locale: String = TranslationServer.get_locale()

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			# The dialogue has finished so close the balloon
			get_tree().paused = false
			_dialogue_skip()
			ballon_animations.play("balloon_fade_out")
			await get_tree().create_timer(0.2).timeout
			queue_free()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

## The base balloon anchor
@onready var balloon: Control = %Balloon

## The label showing the name of the currently speaking character
@onready var name_tab: AnimatedSprite2D = $Balloon/DialogueBar/NameTab
@onready var character_label: RichTextLabel = %CharacterLabel

@onready var talkface: AnimatedSprite2D = $Balloon/DialogueBar/Talkface

## The label showing the currently spoken dialogue
@onready var dialogue_label: DialogueLabel = %DialogueLabel

## The menu of responses
@onready var responses_menu: DialogueResponsesMenu = %ResponsesMenu

@onready var indicator: Sprite2D = $Balloon/DialogueBar/Indicator

@onready var ballon_animations: AnimationPlayer = $Balloon/BallonAnimations
@onready var indicator_animations: AnimationPlayer = $Balloon/IndicatorAnimations
@onready var responses_animations: AnimationPlayer = $Balloon/ResponsesAnimations


@export var dialogue_start: AudioStream
@export var dialogue_skip: AudioStream
@export var indicator_appears: AudioStream

@export_range(-80, 0) var volume_db := 0.0
@export_range(0.5, 2.0) var pitch := 1.0


func _dialogue_start():
	AudioManager.play_sfx(dialogue_start, pitch, volume_db)


func _dialogue_skip():
	AudioManager.play_sfx(dialogue_skip, pitch, volume_db)


func _indicator_appears():
	AudioManager.play_sfx(indicator_appears, pitch, volume_db)


func _ready() -> void:
	balloon.hide()
	indicator.hide()
	talkface.visible = false

	Engine.get_singleton("DialogueManager").mutated.connect(_on_mutated)

	# If the responses menu doesn't have a next action set, use this one
	if responses_menu.next_action.is_empty():
		responses_menu.next_action = next_action

	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)


func _unhandled_input(_event: InputEvent) -> void:
	# Only the balloon is allowed to handle input while it's showing
	get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	## Detect a change of locale and update the current dialogue line to show the new language
	if what == NOTIFICATION_TRANSLATION_CHANGED and _locale != TranslationServer.get_locale() and is_instance_valid(dialogue_label):
		_locale = TranslationServer.get_locale()
		var visible_ratio = dialogue_label.visible_ratio
		self.dialogue_line = await resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			dialogue_label.skip_typing()


## Start some dialogue
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	resource = dialogue_resource
	self.dialogue_line = await resource.get_next_dialogue_line(title, temporary_game_states)


## Apply any changes to the balloon given a new [DialogueLine].
func apply_dialogue_line() -> void:
	
	# --- BLOQUE DE PERSONALIZACIÓN DE NOMBRE ---
	var show_name := true
	var display_name := dialogue_line.character

	# Revisa tags especiales
	for tag in dialogue_line.tags:
		if tag.begins_with("alias="):
			display_name = tag.split("=", true, 1)[1].strip_edges()
		elif tag == "no_name":
			show_name = false

	# Aplica el nombre o lo oculta
	character_label.visible = show_name and not display_name.is_empty()
	name_tab.visible = show_name and not display_name.is_empty()
	character_label.text = tr(display_name, "dialogue")

	_load_talkface_for(dialogue_line)

	var frames_path := "res://dialogues/TALKSPRITES/spriteframes/%s_talksprites.tres" % dialogue_line.character

	if ResourceLoader.exists(frames_path):
		var frames := load(frames_path)
		if frames is SpriteFrames:
			talkface.visible = true
			talkface.sprite_frames = frames

			# Obtener el mood desde los tags
			var mood := "neutral"
			for tag in dialogue_line.tags:
				if not tag.to_lower() in ["left", "right", "center"]:
					mood = tag.to_lower()
					break

			print("🗣️ Mood solicitado:", mood)
			#for _name in frames.get_animation_names():
				#print(" -", _name)

			if frames.has_animation(mood):
				talkface.play(mood)
			else:
				print("⚠️ Animación no encontrada:", mood)
				talkface.play("neutral")
		else:
			talkface.visible = false
			talkface.sprite_frames = null
	else:
		talkface.visible = false
		talkface.sprite_frames = null


		# 🎙️ Conectar el signal "spoke" para controlar cuándo hablar
		if dialogue_label.is_connected("spoke", Callable(self, "_on_spoke")):
			dialogue_label.disconnect("spoke", Callable(self, "_on_spoke"))
		dialogue_label.connect("spoke", Callable(self, "_on_spoke"))

			# 🔌 Evitar conectar varias veces
		if dialogue_label.is_connected("finished_typing", Callable(self, "_on_typing_finished")):
			dialogue_label.disconnect("finished_typing", Callable(self, "_on_typing_finished"))
		dialogue_label.connect("finished_typing", Callable(self, "_on_typing_finished"))


	if not dialogue_label.finished_typing.is_connected(_on_typing_finished):
		dialogue_label.finished_typing.connect(_on_typing_finished)

	dialogue_label.hide()
	dialogue_label.dialogue_line = dialogue_line

	# Limpieza del texto visible: eliminam tags personalizados [alias=...] y [no_name]
	var clean_text := dialogue_label.text
	clean_text = clean_text.replace("[no_name]", "")
	var alias_regex := RegEx.new()
	alias_regex.compile("\\[alias=[^\\]]+\\]")
	clean_text = alias_regex.sub(clean_text, "", true)

	dialogue_label.text = clean_text

	responses_menu.hide()
	responses_menu.responses = dialogue_line.responses

	# Show our balloon
	balloon.show()
	_dialogue_start()
	will_hide_balloon = false

	dialogue_label.show()
	if not dialogue_line.text.is_empty():
		dialogue_label.type_out()
		indicator.hide()
		await dialogue_label.finished_typing


	# Wait for input
	if dialogue_line.responses.size() > 0:
		balloon.focus_mode = Control.FOCUS_NONE
		responses_menu.show()
		responses_animations.play("responses_fade_in")
	elif dialogue_line.time != "":
		var time = dialogue_line.text.length() * 0.02 if dialogue_line.time == "auto" else dialogue_line.time.to_float()
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		balloon.focus_mode = Control.FOCUS_ALL
		balloon.grab_focus()
		_indicator_appears()

#region TALKSPRITES

func _load_talkface_for(line: DialogueLine) -> void:
	if line.character.is_empty():
		talkface.visible = false
		talkface.sprite_frames = null
		return

	var frames_path := "res://dialogues/TALKSPRITES/spriteframes/%s_talksprites.tres" % line.character

	if ResourceLoader.exists(frames_path):
		var frames := load(frames_path)
		if frames is SpriteFrames:
			talkface.visible = true
			talkface.sprite_frames = frames

			var mood := "neutral"
			for tag in line.tags:
				if not tag.to_lower() in ["left", "right", "center"]:
					mood = tag.to_lower()
					break

			if frames.has_animation(mood):
				talkface.play(mood)
			else:
				print("⚠️ Animación no encontrada:", mood)
				talkface.play("neutral")
		else:
			talkface.visible = false
			talkface.sprite_frames = null
	else:
		talkface.visible = false
		talkface.sprite_frames = null


func _on_spoke(letter: String, _index: int, _speed: float) -> void:
	if not talkface.visible or talkface.sprite_frames == null:
		return
	var ignore := "-_()[]{}:;/#"
	#var ignore := ",.¿?¡!()-_[]{}:;\"…\n\t "
	if letter in ignore:
		talkface.pause()
	else:
		if not talkface.is_playing():
			talkface.play()


func _on_typing_finished():
	indicator.show()
	talkface.stop()
#endregion


## For a manual disconect:
#func _exit_tree():
	#if dialogue_label.finished_typing.is_connected(_on_typing_finished):
		#dialogue_label.finished_typing.disconnect(_on_typing_finished)


## Go to the next line
func next(next_id: String) -> void:
	ballon_animations.play("ballon_nextLine")
	self.dialogue_line = await resource.get_next_dialogue_line(next_id, temporary_game_states)


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		balloon.hide()


func _on_mutated(_mutation: Dictionary) -> void:
	is_waiting_for_input = false
	will_hide_balloon = true
	mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	# Si el texto aún se está tipeando → sólo permite saltar el tipeo
	if dialogue_label.is_typing and dialogue_label.visible_ratio < 1.0:
		var mouse_was_clicked = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()
		var skip_button_was_pressed := event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			dialogue_label.skip_typing()
			return
		else:
			# No permitir avanzar si el texto aún se está tipeando
			get_viewport().set_input_as_handled()
			return

	# Si ya terminó de tipear, pero aún no se espera input, no avanzar
	if not is_waiting_for_input:
		return
	if dialogue_line.responses.size() > 0:
		return

	get_viewport().set_input_as_handled()

	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == balloon:
		next(dialogue_line.next_id)



func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	responses_menu.input_locked = true
	responses_animations.play("responses_fade_out")
	await get_tree().create_timer(0.2).timeout
	next(response.next_id)



#endregion
