# GameOverScreen.gd (escena autoload):

extends CanvasLayer

@export var allow_pause := false
var skip_requested := false

@export_file("*.tscn") var title_screen_scene: String

@export var game_over_delay := 60.0

var active := false

@onready var puppet_animations: AnimationPlayer = %PuppetAnimations
@onready var text_animations: AnimationPlayer = %TextAnimations
@onready var particles_animations: AnimationPlayer = %ParticlesAnimations
@onready var background_animations: AnimationPlayer = %BackgroundAnimations


func _ready():
	hide()

	if PlayerManager.player_died.is_connected(_on_player_died) == false:
		PlayerManager.player_died.connect(_on_player_died)


func _on_player_died():
	if active:
		return

	active = true
	show()

	_pause_game()
	await _play_game_over_sequence()
	_reset_and_return_to_title()


func _pause_game():
	get_tree().paused = true

	process_mode = Node.PROCESS_MODE_ALWAYS
	puppet_animations.process_mode = Node.PROCESS_MODE_ALWAYS
	text_animations.process_mode = Node.PROCESS_MODE_ALWAYS
	particles_animations.process_mode = Node.PROCESS_MODE_ALWAYS
	background_animations.process_mode = Node.PROCESS_MODE_ALWAYS


func _play_game_over_sequence() -> void:
	@warning_ignore("redundant_await")
	AudioManager.fade_out_all(1.0)
	AudioManager.play_voice_path("res://audio/SFX/Puppet SFX/hurt/Sfx_Puppet_Death_1.ogg", 1.0, -8.0)
	await CinematicManager._wait(2.5)
	AudioManager.play_sfx_path("res://audio/music/Sweet Dreams.ogg", 1.0, -8.0)
	await CinematicManager._wait(3.0)

	puppet_animations.play("puppet_on")
	text_animations.play("text_on")
	particles_animations.play("particles_on")
	background_animations.play("fade_in")
	await background_animations.animation_finished

	await _wait_for_skip_or_timeout()

	if skip_requested:
		AudioManager.fade_out_all(2.0)
		background_animations.play("fade_out_fast")
		await background_animations.animation_finished
	else:
		AudioManager.fade_out_all(5.0)
		background_animations.play("fade_out")
		await background_animations.animation_finished

	skip_requested = false



func _reset_and_return_to_title():
	get_tree().paused = false
	active = false

	# 🧹 Reset global
	NewGameManager.start_new_game()

	PlayerManager.game_over = false
	hide()

	get_tree().change_scene_to_file(title_screen_scene)


func _wait_for_skip_or_timeout() -> void:
	var timer := get_tree().create_timer(game_over_delay, true)

	while timer.time_left > 0:
		if skip_requested:
			break
		await get_tree().process_frame


func _unhandled_input(event: InputEvent) -> void:
	if not active:
		return
	
	if event.is_action_pressed("ui_cancel") \
	or event.is_action_pressed("ui_pause") \
	or event.is_action_pressed("ui_accept"):

		skip_requested = true
		print("⏩ Game Over saltado por el jugador.")
		get_viewport().set_input_as_handled()
