#global_menu_hub.gd (autoload):

extends CanvasLayer

signal shown(menu_id)
@warning_ignore("unused_signal")
signal hidden(menu_id)

var menus := {}
var stack: Array = []
var current: MenuBase = null
var is_busy: bool = false

var is_paused : bool = false

var current_menu: MenuBase = null
var menu_stack: Array[MenuBase] = []

var main_menu: MenuBase
var items_menu: MenuBase
var equip_menu: MenuBase
var options_menu: MenuBase

var save_menu: MenuBase

var last_main_button: Button = null
var input_locked: bool = false

func _ready():
	AudioManager.mute_all_buses()
	AudioManager.unmute_all_buses(0.5)
	
	visible = false

	_load_menu( "main",    "res://UI/Menu/MainMenu/main_menu.tscn" )
	_load_menu( "items",   "res://UI/Menu/ItemsMenu/items_menu.tscn" )
	_load_menu( "equip",   "res://UI/Menu/EquipMenu/equip_menu.tscn" )
	_load_menu( "options", "res://UI/Menu/OptionsMenu/options_menu.tscn" )
	_load_menu( "save",    "res://UI/Menu/SaveMenu/save_menu.tscn" )

	# Guardar accesos rápidos
	main_menu   = menus[ "main" ]
	items_menu  = menus[ "items" ]
	equip_menu  = menus[ "equip" ]
	options_menu = menus[ "options" ]
	save_menu = menus[ "save" ]


func _load_menu( id: String, path: String ) -> void:
	var scene := load( path )
	if scene == null:
		push_error( "MenuHub: no se pudo cargar escena: " + path )
		return

	var instance: MenuBase = scene.instantiate()
	instance.visible = false
	add_child( instance )

	menus[ id ] = instance


func open( id: String ) -> void:
	if is_busy:
		return

	if not menus.has( id ):
		push_error( "MenuHub: no existe el menú '" + id + "'" )
		return

	var next_menu: MenuBase = menus[ id ]

	is_busy = true
	await SceneTransition.fade_out( "menu" )

	if current:
		stack.append( current )
		current.visible = false

	current = next_menu
	current.visible = true
	current._menu_opened()

	emit_signal( "shown", id )

	if current.has_method( "initialize_focus" ):
		current.initialize_focus()

	visible = true
	get_tree().paused = true

	await SceneTransition.fade_in( "menu" )
	is_busy = false


func back() -> void:
	if is_busy:
		return

	# Si no hay nada detrás, cerrar todo
	if stack.is_empty():
		close_all()
		return

	is_busy = true
	await SceneTransition.fade_out( "menu" )

	# Cerrar el menú actual
	if current:
		current._menu_closed()
		current.visible = false

	# Sacar el menú anterior de la pila
	current = stack.pop_back()
	current.visible = true
	if current.has_method( "initialize_focus" ):
		current.initialize_focus()

	await SceneTransition.fade_in( "menu" )
	is_busy = false


func close_all() -> void:
	if is_busy:
		return

	is_busy = true
	await SceneTransition.fade_out( "menu" )

	for m in menus.values():
		m.visible = false
		if m.has_method( "_menu_closed" ):
			m._menu_closed()

	stack.clear()
	current = null
	visible = false
	get_tree().paused = false

	await SceneTransition.fade_in( "menu" )
	is_busy = false



func show_pause_menu( menu: MenuBase = null, clear_stack := false ) -> void:
	input_locked = true
	AudioManager.mute_hover_once()
	get_tree().paused = true
	await SceneTransition.fade_out( "menu" )

	if menu == null:
		menu = main_menu

	# Si el caller pide limpiar el stack
	if clear_stack:
		menu_stack.clear()

	# Si ya había menú abierto, apilar
	if current_menu and current_menu != menu:
		menu_stack.append( current_menu )
		current_menu.visible = false

	current_menu = menu

	if current_menu:
		current_menu._menu_opened()
		current_menu.visible = true
		current_menu.emit_signal( "shown" )
		if current_menu.has_method( "initialize_focus" ):
			current_menu.initialize_focus()

	visible = true
	is_paused = true
	shown.emit()

	SceneTransition.fade_in( "menu" )
	input_locked = false


func open_save_menu():
	if save_menu:
		save_menu.mode = save_menu.MODE.SAVE
		show_pause_menu( save_menu )


func open_load_menu():
	if save_menu:
		save_menu.mode = save_menu.MODE.LOAD
		show_pause_menu( save_menu )


func open_options_menu():
	if options_menu:
		show_pause_menu( options_menu )


func go_back_in_menu() -> void:
	if current_menu is MainMenu and current_menu.is_confirm_open:
		return

	if current_menu == main_menu:
		hide_pause_menu()
		return

	if menu_stack.size() > 0:
		input_locked = true
		if current_menu:
			AudioManager.mute_hover_once()
			await SceneTransition.fade_out( "menu" )
			current_menu._menu_closed()
			current_menu.visible = false
			current_menu.emit_signal( "hidden" )

		current_menu = menu_stack.pop_back()
		current_menu.visible = true
		if current_menu.has_method( "initialize_focus" ):
			current_menu.initialize_focus()
		await SceneTransition.fade_in( "menu" )
		input_locked = false
	else:
		hide_pause_menu()


func hide_pause_menu() -> void:
	input_locked = true
	await SceneTransition.fade_out( "menu" )

	if current_menu:
		current_menu._menu_closed()
		current_menu.visible = false
		current_menu.emit_signal( "hidden" )

	menu_stack.clear()
	get_tree().paused = false
	visible = false
	is_paused = false
	hidden.emit()
	last_main_button = null

	await SceneTransition.fade_in( "menu" )
	input_locked = false


func _can_pause() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return true
	if "allow_pause" in current_scene:
		return current_scene.allow_pause
	return true


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()

	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
