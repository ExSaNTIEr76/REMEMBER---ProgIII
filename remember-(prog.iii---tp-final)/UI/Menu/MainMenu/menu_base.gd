class_name MenuBase    extends CanvasLayer

@warning_ignore("unused_signal")
signal shown
@warning_ignore("unused_signal")
signal hidden

@onready var main_menu : MainMenu

@export var allow_pause := false
@export var override_cancel_behaviour := false

@export var menu_opened: AudioStream
@export_range(-80, 0) var menu_opened_volume_db := 0.0
@export_range(0.5, 2.0) var menu_opened_pitch := 1.0

@export var menu_closed: AudioStream
@export_range(-80, 0) var menu_closed_volume_db := 0.0
@export_range(0.5, 2.0) var menu_closed_pitch := 1.0


func _menu_opened():
	AudioManager.play_sfx(menu_opened, menu_opened_pitch, menu_opened_volume_db)

func _menu_closed():
	AudioManager.play_sfx(menu_closed, menu_closed_pitch, menu_closed_volume_db)


func _unhandled_input(event: InputEvent) -> void:
	if GlobalMenuHub.input_locked:
		get_viewport().set_input_as_handled()
		return  # 🚫 Ignora todo input durante fade/transición
	if event.is_action_pressed("ui_pause") and GlobalMenuHub._can_pause():
		if not GlobalMenuHub.is_paused:
			GlobalMenuHub.show_pause_menu()
		else:
			GlobalMenuHub.menu_stack.clear()
			GlobalMenuHub.hide_pause_menu()
		get_viewport().set_input_as_handled()
		#print("MenuBase._unhandled_input — current_menu:", GlobalMenuHub.current_menu)
		return

	if GlobalMenuHub.is_paused and event.is_action_pressed("ui_cancel"):
		
		# 1) Primero damos chance al menú de manejar el cancel
		if GlobalMenuHub.current_menu and GlobalMenuHub.current_menu.has_method("on_cancel"):
			var handled = await GlobalMenuHub.current_menu.on_cancel()
			if handled:
				get_viewport().set_input_as_handled()
				return

		# 2) Si NO lo manejó → ahora sí reseteamos (porque se va a cerrar)
		if GlobalMenuHub.current_menu and GlobalMenuHub.current_menu.has_method("_reset_menu_state"):
			GlobalMenuHub.current_menu._reset_menu_state()

		# 3) Navegación normal
		GlobalMenuHub.go_back_in_menu()
		get_viewport().set_input_as_handled()
		return
