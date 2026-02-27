class_name TitleScreen    extends CanvasLayer

@export var allow_pause := false
var warning_active: bool = false
var prelude_active: bool = false

@export_category( "Music" )

@export var title_music: AudioStream
@export_range(-80, 0) var music_volume_db := -12.0
@export_range(0.5, 2.0) var music_pitch := 1.0

@export_category( "Switch" )

@export var switch_sfx: AudioStream
@export_range(-80, 0) var switch_volume_db := -5.0
@export_range(0.5, 2.0) var switch_pitch := 1.0

@export_category( "Scenes" )

@export_file("*.tscn") var intro_scene: String
@export_file("*.tscn") var load_menu_scene: String
@export_file("*.tscn") var options_scene: String
@export_file("*.tscn") var extras_scene: String


@export_category( "New Game Cinematic" )

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = ""

@onready var button_new_game: Button = %"NEW GAME"
@onready var button_continue: Button = %CONTINUE
@onready var button_extras: Button = %EXTRAS
@onready var button_options: Button = %OPTIONS
@onready var button_quit: Button = %QUIT

@onready var button_none: Button = %NONE

var last_button: String = ""

@onready var player_name_entry: LineEdit = %PlayerNameEntry
@onready var player_name_label: Label = %PlayerNameLabel

@onready var title_animations: AnimationPlayer = $TitleAnimations
@onready var puppet_animations: AnimationPlayer = $PuppetAnimations
@onready var cinematic_animations: AnimationPlayer = $CinematicAnimations
@onready var player_name_animations: AnimationPlayer = $PlayerNameAnimations

var player: Node = null


func _ready():
	if is_instance_valid(TimeManager):
		TimeManager.pause_time()

	AudioManager.mute_hover_once()
	AudioManager.is_in_combat = false
	AudioManager.fade_out_all(0.5)
	await _wait_for_player()
	set_meta("allow_pause", false)
	PlayerManager.player.freeze_movement()
	visible = true
	_check_save_files()
	await warning_screen()
	await CinematicManager._wait(1.0)
	last_button = "button_new_game"


func _process(_delta: float) -> void:
	if visible and get_viewport().gui_get_focus_owner() == null:
		initialize_focus()
		AudioManager.mute_hover_once()


func initialize_focus() -> void:
	await get_tree().process_frame
	if last_button == "":
		button_none.grab_focus()
	if last_button == "button_new_game":
		button_new_game.grab_focus()
	if last_button == "button_continue":
		button_continue.grab_focus()
	if last_button == "button_extras":
		button_extras.grab_focus()
	if last_button == "button_options":
		button_options.grab_focus()
	if last_button == "button_quit":
		button_quit.grab_focus()


func _on_new_game_pressed():
	await start_new_game_flow()


func start_new_game_flow() -> void:
	prelude_active = true
	button_none.grab_focus()
	AudioManager.play_sfx(switch_sfx, switch_pitch, switch_volume_db)

	if is_instance_valid(TimeManager):
		TimeManager.reset_time()

	title_animations.play("title_fade_out")
	await title_animations.animation_finished
	AudioManager.fade_out_current_music(1.0)

	# UNA VEZ SE TIENE EL NOMBRE
	NewGameManager.start_new_game()

	# MOSTRAR INPUT DE NOMBRE
	await CinematicManager._wait(3.0)
	player_name_animations.play("entry_fade_in")
	await player_name_animations.animation_finished
	AudioManager.play_sfx_path("res://audio/SFX/GUI SFX/menu/Sfx_Cursor.ogg", 1.5, -15.0)
	await ask_player_name()

	player_name_animations.play("entry_fade_out")
	await player_name_animations.animation_finished
	await CinematicManager._wait(2.0)

	AudioManager.play_music_path("res://audio/music/Don't Give Up Yet (please).ogg", 1.0, -12.0)
	puppet_animations.play("floating")
	cinematic_animations.play("puppet_zoom_in")
	await cinematic_animations.animation_finished
	cinematic_animations.play("puppet_wakening")
	await cinematic_animations.animation_finished

	@warning_ignore("int_as_enum_without_cast")
	TeleportManager.teleport_player("/root/Sepulcher/YSORT/SpawnMarker", Vector2(0, 0), 0, "res://scenes/LEVELS/Zone 0/levels/Prelude/Z0_sepulcher.tscn")


func ask_player_name() -> void:
	player_name_entry.visible = true
	player_name_entry.text = ""
	player_name_entry.grab_focus()

	while true:
		var submitted_text = await player_name_entry.text_submitted
		submitted_text = submitted_text.strip_edges()

		if submitted_text.length() > 0:
			GlobalConditions.player_name = submitted_text
			player_name_label.text = submitted_text
			break

	player_name_entry.visible = false


# ---------------------------------------------------------------------------------------------------------------


func _on_continue_pressed():
	GlobalMenuHub.open_load_menu()
	button_none.grab_focus()
	await SceneTransition.fade_out_black()
	SceneTransition.fade_in_black_noawait()
	last_button = "button_continue"


func _on_load_menu_shown():
	visible = true
	_check_save_files()

	await get_tree().process_frame
	await get_tree().process_frame


func _on_load_menu_hidden():
	visible = false
	AudioManager.mute_hover_once()



func _check_save_files() -> void:
	var save_path := "user://Saves"
	var dir := DirAccess.open(save_path)

	if dir == null:
		# Si la carpeta no existe, se oculta el botón
		button_continue.hide()
		print("📁 No existe la carpeta de saves, ocultando CONTINUE.")
		return

	dir.list_dir_begin()
	var has_save := false
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir():
			has_save = true
			break
		file_name = dir.get_next()

	dir.list_dir_end()

	if has_save:
		button_continue.show()
		print("💾 Se detectaron archivos de guardado, mostrando CONTINUE.")
	else:
		button_continue.hide()
		print("📁 Carpeta de saves vacía, ocultando CONTINUE.")


# ---------------------------------------------------------------------------------------------------------------


func _on_extras_pressed():
	if extras_scene != "":
		await SceneTransition.fade_out_black()
		get_tree().change_scene_to_file(extras_scene)
		SceneTransition.fade_in_black_noawait()
	else:
		push_warning("⚠️ No se asignó una escena para los extras.")


# ---------------------------------------------------------------------------------------------------------------


func _on_options_pressed():
	GlobalMenuHub.open_options_menu()
	button_none.grab_focus()
	await SceneTransition.fade_out_black()
	SceneTransition.fade_in_black_noawait()
	last_button = "button_options"


func _on_options_menu_shown():
	visible = false

	await get_tree().process_frame
	await get_tree().process_frame


func _on_options_menu_hidden() -> void:
	visible = true


# ---------------------------------------------------------------------------------------------------------------


func _on_quit_pressed():
	AudioManager.fade_out_current_music(1.0)
	button_none.grab_focus()
	await CinematicManager._wait(1.0)
	AudioManager.play_sfx(switch_sfx, switch_pitch, switch_volume_db)
	title_animations.play("title_fade_out")
	await title_animations.animation_finished
	await CinematicManager._wait(1.0)
	get_tree().quit()


func _on_none_pressed():
	return

# ---------------------------------------------------------------------------------------------------------------


func warning_screen() -> void:
	AudioManager.mute_hover_once()
	await get_tree().process_frame
	AudioManager.fade_out_current_music(1.0)
	await get_tree().process_frame
	AudioManager.fade_out_current_ambient(1.0)
	await get_tree().process_frame

	warning_active = true

	await CinematicManager._wait(1.5)
	title_animations.play("warning_screen")

	await _wait_for_warning_end()

	# Si el jugador no la pasó, desactiva manualmente el flag aquí
	if warning_active:
		warning_active = false

	# Transición sonora al menú principal
	AudioManager.play_music(title_music, music_pitch, music_volume_db)
	title_animations.play("title_fade_in")
	await title_animations.animation_finished
	button_new_game.grab_focus()


func _wait_for_warning_end() -> void:
	# Espera hasta que la animación termine o se interrumpa por input
	while warning_active and title_animations.is_playing():
		await get_tree().process_frame


func _enter_tree():
	add_to_group("title_screen")


func white_static_sfx() -> void:
	AudioManager.play_sfx_path("res://audio/ambient/ambSfx_White_Static.ogg", 1.0, -5.0)


func intro_sfx() -> void:
	AudioManager.fade_out_sfx_path("res://audio/ambient/ambSfx_White_Static.ogg", 1.0)
	AudioManager.play_sfx_path("res://audio/SFX/GUI SFX/menu/Sfx_Intro.ogg", 1.0, -3.0)


func _wait_for_player() -> void:
	var max_wait_frames := 120
	while (PlayerManager.player == null or not PlayerManager.player.is_inside_tree()) and max_wait_frames > 0:
		await get_tree().process_frame
		max_wait_frames -= 1

	player = PlayerManager.player
	if not player:
		push_error("❗ No se pudo encontrar al jugador.")


func _unhandled_input(event: InputEvent) -> void:
	# Solo mientras el warning está activo
	if warning_active and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		if prelude_active:
			return
		else:
			warning_active = false
			print("⏩ Warning screen saltado por el jugador.")

			# Pequeño fade-out visual y de sonido
			AudioManager.fade_out_all(0.8)
			await SceneTransition.fade_out_black()
			title_animations.play("title_fade_in")
			await SceneTransition.fade_in_black()
			await title_animations.animation_finished
			button_new_game.grab_focus()

			# Detiene la animación actual inmediatamente
			if title_animations.is_playing():
				title_animations.stop()

			get_viewport().set_input_as_handled()
