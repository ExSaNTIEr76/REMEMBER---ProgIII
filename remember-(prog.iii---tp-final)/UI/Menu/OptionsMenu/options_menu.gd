class_name OptionsMenu    extends MenuBase

var is_open := false

@warning_ignore("unused_signal")

@onready var music_number: Label = %MusicNumber
@onready var ambient_number: Label = %AmbientNumber
@onready var sfx_number: Label = %SFXNumber
@onready var voices_number: Label = %VoicesNumber

@onready var music_slider: HSlider = %MusicSlider
@onready var ambient_slider: HSlider = %AmbientSlider
@onready var sfx_slider: HSlider = %SFXSlider
@onready var voices_slider: HSlider = %VoicesSlider

@onready var resolution_button: Button = %ResolutionButton
@onready var languaje_button: Button = %LanguajeButton
@onready var voices_button: Button = %VoicesButton

@onready var controls_button: Button = %ControlsButton
@onready var preferences_button: Button = %PreferencesButton

var last_button: Button = null


func _ready() -> void:
	get_tree().paused = false
	AudioManager.mute_hover_once()
	visible = false

	_bind_slider(music_slider, music_number)
	_bind_slider(ambient_slider, ambient_number)
	_bind_slider(sfx_slider, sfx_number)
	_bind_slider(voices_slider, voices_number)


func _bind_slider(slider: HSlider, label: Label):
	slider.value_changed.connect(
		func(v): label.text = str(int(round(v * 100)))
	)
	label.text = str(int(round(slider.value * 100)))


func _on_visibility_changed():
	if visible:
		await get_tree().process_frame
		music_slider.grab_focus()


func open_menu():
	visible = true

	# Asegura que el menú ya se dibujó
	await get_tree().process_frame

	# Focus inicial
	music_slider.grab_focus()


func on_cancel() -> bool:
	# Si se está en TitleScreen
	if get_tree().get_first_node_in_group("title_screen") != null:
		GlobalMenuHub.menu_stack.clear()
		GlobalMenuHub.hide_pause_menu()
		return true
	
	# Si se está in-game
	return false 


func show_options_menu():
	if is_open:
		return
	
	await SceneTransition.fade_out("menu")
	visible = true
	get_tree().paused = true
	is_open = true

	shown.emit()
	_menu_opened()
	SceneTransition.fade_in("menu")


func hide_options_menu():
	if not is_open:
		return
	
	await SceneTransition.fade_out("menu")
	visible = false
	get_tree().paused = false
	is_open = false
	hidden.emit()
	_menu_closed()
	SceneTransition.fade_in("menu")
	PlayerManager.player.state_machine.change_to(PlayerManager.player.states.Idle)


func _step_slider(slider: HSlider, amount: float) -> void:
	slider.value = clamp(slider.value + amount, 0.0, 1.0)


func _toggle_slider(node: Node) -> void:
	if node is HSlider:
		var slider := node as HSlider
		
		if slider.value > 0.0:
			slider.value = 0.0
		else:
			slider.value = 1.0


func _unhandled_input(event: InputEvent) -> void:
	var focused := get_viewport().gui_get_focus_owner()

	if focused is HSlider:
		var slider := focused as HSlider

		if event.is_action_pressed("ui_attack_a"):
			_toggle_slider(slider)

		if Input.is_action_pressed("ui_run"):
			if event.is_action_pressed("ui_left"):
				_step_slider(slider, -0.1)
			elif event.is_action_pressed("ui_right"):
				_step_slider(slider, 0.1)

	super._unhandled_input(event)


func _process(_delta: float) -> void:
	var focused := get_viewport().gui_get_focus_owner()

	if focused is HSlider:
		var slider := focused as HSlider

		if Input.is_action_pressed("ui_run"):
			slider.step = 0.1
		else:
			slider.step = 0.01
