#load_menu.gd (la escena es un autoload):
extends CanvasLayer

signal shown
signal hidden

var is_open := false

@export var allow_pause := false

@export_category( "Menu Open Sound" )

@export var menu_opened: AudioStream
@export_range(-80, 0) var menu_open_volume_db := -15.0
@export_range(0.5, 2.0) var menu_open_pitch := 1.5

@export_category( "Menu Close Sound" )

@export var menu_close: AudioStream
@export_range(-80, 0) var menu_close_volume_db := -10.0
@export_range(0.5, 2.0) var menu_close_pitch := 0.5

# 🚨 Tomamos los slots directamente del nodo
const MAX_SAVE_SLOTS := 30
@onready var save_slots: Array = []
var selected_slot = null # Variable para el slot seleccionado


func _ready() -> void:
	layer = 100  # ⚠️ Más alto que el de title_screen
	visible = false
	hidden.emit()
	AudioManager.mute_hover_once()
	
	# Inicializar los slots
	for i in range(MAX_SAVE_SLOTS):
		var slot = get_node_or_null("SaveLoadPanel/MarginContainer/VBoxContainer/SaveList/save_slot_%d" % (i + 1))
		if slot:
			save_slots.append(slot)
	
	# Conectar señales
	#LoadManager.load_completed.connect(_on_load_completed)
	#LoadManager.load_failed.connect(_on_load_failed)
	
	#_refresh_save_slots()


func _menu_opened() -> void:
	AudioManager.play_sfx(menu_opened, menu_open_pitch, menu_open_volume_db)


func _menu_closed() -> void:
	AudioManager.play_sfx(menu_close, menu_close_pitch, menu_close_volume_db)


func show_load_menu() -> void:
	if is_open or get_tree().paused:
		return

	await SceneTransition.fade_out("menu")
	visible = true
	get_tree().paused = true
	is_open = true

	shown.emit()
	_menu_opened()
	#_refresh_save_slots()
	SceneTransition.fade_in("menu")

	if save_slots.size() > 0:
		var first = save_slots[0]
		if first.has_node("SlotButton"):
			first.get_node("SlotButton").grab_focus()

	await get_tree().process_frame  # Asegura que el menú esté visible antes del focus
	if save_slots.size() > 0:
		var first = save_slots[0]
		if first.has_node("SlotButton"):
			first.get_node("SlotButton").grab_focus()


func hide_load_menu() -> void:
	if not is_open:
		return

	await SceneTransition.fade_out("menu")
	visible = false
	get_tree().paused = false
	is_open = false
	hidden.emit()
	_menu_closed()
	SceneTransition.fade_in("menu")

	# ✅ Restaurar foco a título (si existe y está en escena)
	var title = get_tree().get_first_node_in_group("title_screen")
	if title and title.has_method("grab_default_focus"):
		await get_tree().process_frame
		title.grab_default_focus()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open:
		return

	if event.is_action_pressed("ui_pause") or event.is_action_pressed("ui_cancel"):
		hide_load_menu()
		get_viewport().set_input_as_handled()


#func _refresh_save_slots() -> void:
	#var loaded_saves = LoadManager.load_all_saves()
	#
	## Asegurarnos de que los slots estén ordenados por índice
	#loaded_saves.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: 
		#return a.index < b.index
	#)
#
	#for i in range(save_slots.size()):
		#var slot_node = save_slots[i]
		#if not slot_node.is_connected("pressed", _on_slot_activated):
			#slot_node.pressed.connect(_on_slot_activated)
			#
		## Buscar si hay datos guardados para este slot
		#var save_data: SaveData = null
		#for save_info in loaded_saves:
			#if save_info.index == i:
				#save_data = save_info.data
				#break
				#
		#if save_data:
			#slot_node.save_data = save_data
			#if slot_node.has_method("update_from_save_data"):
				#slot_node.update_from_save_data(save_data)
#
			##print("📂 SLOT ", i, " cargado con UUID: ", save_data.uuid)
		#else:
			#slot_node.save_data = null
			#if slot_node.has_method("clear_display"):
				#slot_node.clear_display()
			##print("📂 SLOT ", i, " vacío.")


func _on_slot_activated(slot):
	if not slot.save_data:
		print("⚠️ No hay datos para cargar en este slot")
		return

	for s in save_slots:
		if s != slot and s.has_method("deactivate"):
			s.deactivate()
	if slot.has_method("activate"):
		slot.activate()

	selected_slot = slot
	var slot_index = slot.get_index()

	var savestate = get_node("/root/Savestate")
	savestate.load_game_state(slot_index)
	savestate.unpack_level(LevelManager.get_current_level())
	savestate.get_game_variables(PlayerManager)

	hide_load_menu()

	# Aquí podrías emitir una señal o llamar a una función para actualizar el estado del juego
	# Por ejemplo, cambiar de escena, actualizar HUD, etc.


func _on_load_failed(error: String) -> void:
	push_error("❌ Load failed: " + error)
	# Aquí podrías mostrar un mensaje de error al usuario
	# Por ejemplo, usando un popup o un mensaje en pantalla
