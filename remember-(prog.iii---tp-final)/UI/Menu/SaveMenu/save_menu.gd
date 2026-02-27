class_name SaveMenu    extends MenuBase

var is_open := false

@onready var menu_title: Label = $MENUTITLE

@onready var no_button: Button = %NO
@onready var yes_button: Button = %YES

@onready var menu_animations: AnimationPlayer = $MenuAnimations

@onready var save_list = %SaveList
@onready var save_and_load = %SaveLoadPanel

@onready var slot_details_panel: SaveSlotData = $"SLOTDATA"
@onready var savestate: ThothGameState = $Savestate

var _current_hovered_slot: SaveSlot = null

const MAX_SAVE_SLOTS := 30
@onready var save_slots: Array = [
	%save_slot_1, %save_slot_2, %save_slot_3, %save_slot_4, %save_slot_5,
	%save_slot_6, %save_slot_7, %save_slot_8, %save_slot_9, %save_slot_10,
	%save_slot_11, %save_slot_12, %save_slot_13, %save_slot_14, %save_slot_15,
	%save_slot_16, %save_slot_17, %save_slot_18, %save_slot_19, %save_slot_20,
	%save_slot_21, %save_slot_22, %save_slot_23, %save_slot_24, %save_slot_25,
	%save_slot_26, %save_slot_27, %save_slot_28, %save_slot_29, %save_slot_30,
]

enum MODE { SAVE, LOAD }
var mode: MODE

var selected_slot = null
var ui_stack = []

var _slot_callables: Dictionary = {}

func _ready():
	visible = false
	hidden.emit()
	AudioManager.mute_hover_once()

	for i in range(MAX_SAVE_SLOTS):
		var slot_node = save_slots[i]
		if not slot_node:
			continue

		# Conectar señales
		var slot_callable := Callable( self, "_on_slot_activated" )
		var slot_id := str(slot_node.get_instance_id())
		if not _slot_callables.has(slot_id):
			_slot_callables[slot_id] = {}
		_slot_callables[slot_id].pressed = slot_callable

		if not slot_node.is_connected("pressed", slot_callable):
			slot_node.pressed.connect(slot_callable)

		# 🔍 Obtener info del slot desde Thoth
		var info = savestate.get_save_info(i)
		if not info.is_empty():
			slot_node.save_data = info.duplicate(true)
			#print("📂 SLOT ", i, " cargado con TAGS: ", info)
			if slot_node.has_method("update_from_save_data"):
				slot_node.update_from_save_data(info)
		else:
			slot_node.save_data = {}
			if slot_node.has_method("clear_display"):
				slot_node.clear_display()
			#print("📂 SLOT ", i, " vacío.")

		# Hover/focus
		if slot_node.has_node("SlotButton"):
			var btn = slot_node.get_node("SlotButton")
			var hover_callable := Callable(self, "_on_slot_hovered").bind(slot_node)
			var focus_callable := Callable(self, "_on_slot_hovered").bind(slot_node)
			_slot_callables[slot_id].hover = hover_callable
			_slot_callables[slot_id].focus = focus_callable

			if not btn.is_connected("mouse_entered", hover_callable):
				btn.mouse_entered.connect(hover_callable)
			if not btn.is_connected("focus_entered", focus_callable):
				btn.focus_entered.connect(focus_callable)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 24)
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	save_list.add_child(spacer)


func _on_slot_hovered(slot_node) -> void:
	if not slot_node:
		return

	_current_hovered_slot = slot_node
	slot_details_panel.update_from_save_data(slot_node.save_data)

	# En modo SAVE, no se busca previsualización en vivo aquí
	if mode == MODE.SAVE:
		if slot_node.save_data:
			if slot_node.has_method("update_from_save_data"):
				slot_node.update_from_save_data(slot_node.save_data)
			if slot_details_panel:
				slot_details_panel.update_from_save_data(slot_node.save_data)
				slot_details_panel.slot_data_animations.play("slot_data_navigate")
		else:
			if slot_node.has_method("clear_display"):
				slot_node.clear_display()
			if slot_details_panel:
				slot_details_panel.clear_display()

	# En modo LOAD, muestra únicamente datos guardados si existen
	if mode == MODE.LOAD:
		if slot_node.save_data:
			if slot_node.has_method("update_from_save_data"):
				slot_node.update_from_save_data(slot_node.save_data)
			if slot_details_panel:
				slot_details_panel.update_from_save_data(slot_node.save_data)
				slot_details_panel.slot_data_animations.play("slot_data_navigate")
		else:
			if slot_node.has_method("clear_display"):
				slot_node.clear_display()
			if slot_details_panel:
				slot_details_panel.clear_display()


func _menu_opened():
	if is_open:
		return
	
	if mode == MODE.SAVE:
		menu_title.text = "SAVE"
	else:
		menu_title.text = "LOAD"
	
	await SceneTransition.fade_out("menu")
	visible = true
	get_tree().paused = true
	is_open = true
	
	if save_and_load:
		save_and_load.show()
		if save_and_load not in ui_stack:
			ui_stack.append(save_and_load)
	
	shown.emit()
	SceneTransition.fade_in("menu")
	
	if save_slots.size() > 0:
		var first = save_slots[0]
		if first.has_node("SlotButton"):
			first.get_node("SlotButton").grab_focus()
	slot_details_panel.slot_data_animations.play("slot_data_open")


func _menu_closed():
	if not is_open:
		return
	
	get_tree().paused = false
	GlobalConditions.floating_box_state = 2
	PlayerManager.player.state_machine.change_to(PlayerManager.player.states.Saving)
	slot_details_panel.slot_data_animations.play("slot_data_close")
	await CinematicManager._wait(0.4)

	visible = false
	is_open = false
	hidden.emit()
	AudioManager.play_sfx(menu_closed, menu_closed_pitch, menu_closed_volume_db)
	await CinematicManager._wait(0.4)
	slot_details_panel.slot_data_animations.play("slot_data_close")
	PlayerManager.player.state_machine.change_to(PlayerManager.player.states.Idle)


func on_cancel() -> bool:
	GlobalMenuHub.menu_stack.clear()
	GlobalMenuHub.hide_pause_menu()
	return true


func _grab_first_slot():
	if save_slots.size() == 0:
		return

	var first = save_slots[0]
	if first and first.has_node("SlotButton"):
		await get_tree().process_frame
		await get_tree().process_frame
		first.get_node("SlotButton").grab_focus()


func _on_slot_activated(slot):

	selected_slot = slot
	var slot_index = slot.get_index()


# ------------------------------- BLOQUE SAVE ------------------------------- 

	match mode:
		MODE.SAVE:

			for s in save_slots:
				if s != slot and s.has_method("deactivate"):
					s.deactivate()
			if slot.has_method("activate"):
				slot.activate()
				slot_details_panel.slot_data_animations.play("slot_data_updated")
			else:
				return

			var level = get_tree().current_scene
			PlayerManager.current_level = level.scene_file_path

			# Asegurar sincronización antes de guardar
			PlayerManager.current_level = level.scene_file_path

			var current_scene = get_tree().current_scene

			if current_scene and current_scene is Level:
				GlobalConditions.level_name = current_scene.level_name
				GlobalConditions.zone_name = current_scene.zone_name
				GlobalConditions.zone_tag  = current_scene.zone_tag

			# Nombre del jugador
			if PlayerManager.player and PlayerManager.player.has_method("get_player_name"):
				GlobalConditions.player_name = PlayerManager.player.get_player_name()
			elif GlobalConditions.player_name == "":
				GlobalConditions.player_name = "Player"

			# Guardar tiempo jugado global (desde TimeManager)
			if is_instance_valid(TimeManager):
				savestate.save_data["play_time"] = TimeManager.get_time_string()
			else:
				savestate.save_data["play_time"] = "00:00:00"

			# Zone tag / player name / level name (desde GlobalConditions / Level)
			if current_scene and current_scene is Level:
				savestate.save_data["zone_tag"] = str(current_scene.zone_tag)
				savestate.save_data["level_name"] = str(current_scene.level_name)
				savestate.save_data["zone_name"] = str(current_scene.zone_name)
			else:
				savestate.save_data["zone_tag"] = str(GlobalConditions.zone_tag)
				savestate.save_data["level_name"] = str(GlobalConditions.level_name)
				savestate.save_data["zone_name"] = str(GlobalConditions.zone_name)

			savestate.save_data["player_name"] = str(GlobalConditions.player_name)

			# Nivel y créditos del player
			if PlayerManager.stats:
				var sts := PlayerManager.stats

				savestate.save_data["player_level"] = int(sts["CURRENT_LEVEL"])
				savestate.save_data["credits"]      = int(sts["CREDITS"])
				savestate.save_data["stats"]        = sts.duplicate(true)

				PlayerManager.CURRENT_LEVEL = sts["CURRENT_LEVEL"]
				PlayerManager.CREDITS       = sts["CREDITS"]
			else:
				savestate.save_data["player_level"] = int(PlayerManager.CURRENT_LEVEL)
				savestate.save_data["credits"]      = int(PlayerManager.CREDITS)

			# Congelar posición real para el save
			if PlayerManager.player:
				PlayerManager.saved_position = PlayerManager.player.global_position
				PlayerManager.saved_direction = PlayerManager.player.move_direction
				print("💾 Posición congelada para save:", PlayerManager.saved_position)



			# Guardam en el slot con Thoth (primero PlayerManager, luego GlobalConditions)
			savestate.set_game_variables(PlayerManager)
			savestate.set_game_variables(GlobalConditions)

			# Forzar actualización del diccionario de globals antes de guardarlo
			print("🌍 Guardando: ", GlobalConditions.player_name, GlobalConditions.level_name, GlobalConditions.zone_name)
			print("🧾 Thoth guardando globals: ", savestate.game_state.globals.keys())

			GlobalInventoryState.sync_from_player()
			savestate.set_game_variables(StateUnlockManager)
			savestate.set_game_variables(GlobalInventoryState)
			savestate.set_game_variables(GlobalChestsState)
			savestate.set_game_variables(GlobalCinematicsState)
			savestate.set_game_variables(GlobalPuzzlesState)
			savestate.set_game_variables(GlobalFightsState)
			savestate.pack_level(level)

			print("DEBUG -> saving top-level:", savestate.save_data)

			savestate.save_game_state(slot_index)

			# Refrescar UI después de guardar
			var info = savestate.get_save_info(slot_index)
			if not info.is_empty():
				slot.save_data = info.duplicate(true)
			else:
				slot.save_data = {}
				if slot.has_method("update_from_save_data"):
					slot.update_from_save_data(info)

			print("DEBUG game_state.globals keys after save:", savestate.game_state.globals.keys())

			if savestate.game_state.globals.has("PlayerGlobalStats"):
				var saved_stats_res = savestate.game_state.globals["PlayerGlobalStats"]
				if saved_stats_res == null:
					print("⚠️ PlayerGlobalStats key existe pero valor es null.")
				elif typeof(saved_stats_res) == TYPE_OBJECT:
					print("✅ PlayerGlobalStats saved! instance_id:", str(saved_stats_res.get_instance_id()))
				elif typeof(saved_stats_res) == TYPE_DICTIONARY:
					print("📦 PlayerGlobalStats guardado como diccionario serializado con keys:", saved_stats_res.keys())
				else:
					print("⚠️ PlayerGlobalStats tiene tipo inesperado:", typeof(saved_stats_res))
			else:
				var pm_entry = savestate.game_state.globals.get("PlayerManager", null)
				print("❌ No PlayerGlobalStats top-level.")
				if pm_entry != null:
					print("Dumping PlayerManager entry:", pm_entry)
				else:
					print("⚠️ Tampoco se encontró PlayerManager en globals.")

			if _current_hovered_slot == slot:
				slot_details_panel.update_from_save_data(slot.save_data)




# ------------------------------- BLOQUE LOAD ------------------------------- 
		MODE.LOAD:

			for s in save_slots:
				if s != slot and s.has_method("deactivate"):
					s.deactivate()
			if slot.has_method("activate_load"):
				slot.activate_load()
			else:
				return

			if not slot.save_data:
				print("⚠️ No hay datos para cargar en este slot")
				return

			print("🔄 Cargando slot ", slot_index, "...")

			# 1️. Restaurar tiempo jugado guardado
			if Engine.has_singleton("TimeManager") and slot.save_data.has("play_time"):
				TimeManager.set_time_from_string(slot.save_data["play_time"])
				TimeManager.pause_time()

			print("DBG load - globals keys:", ThothGameState.game_state.globals.keys())

			# 2️. Cargar el save
			savestate.load_game_state(slot_index)

			# 3️. Restaurar autoloads
			savestate.get_game_variables(PlayerManager)
			savestate.get_game_variables(GlobalConditions)
			savestate.get_game_variables(GlobalInventoryState)
			GlobalInventoryState.apply_to_player()
			savestate.get_game_variables(StateUnlockManager)
			savestate.get_game_variables(GlobalChestsState)
			savestate.get_game_variables(GlobalCinematicsState)
			savestate.get_game_variables(GlobalPuzzlesState)
			savestate.get_game_variables(GlobalFightsState)
			PlayerManager.restore_health_and_cp()

			if slot.save_data.has("stats"):
				PlayerManager.apply_stats_from_dict(slot.save_data["stats"].duplicate(true))
			else:
				print("⚠️ No hay stats guardadas en el slot.")

			# 4️. Preparar transición
			savestate.loading_from_save = true
			savestate.current_slot = slot_index

			# 5. Cambiar de nivel (el unpack ocurrirá dentro del Level)
			on_cancel()
			var saved_path := PlayerManager.current_level
			if saved_path == "" or not ResourceLoader.exists(saved_path):
				push_error("❌ Save inválido: current_level vacío o inexistente")
				return

			await SceneTransition.fade_out_black()
			print("🚪 Cambiando a escena guardada:", saved_path)
			get_tree().paused = false
			get_tree().change_scene_to_file(saved_path)

			await get_tree().process_frame

			# 6. Reaplicar el tiempo del save después del cambio de escena
			if is_instance_valid(TimeManager) and slot.save_data.has("play_time"):
				TimeManager.pause_time()
				TimeManager.set_time_from_string(slot.save_data["play_time"])
				await get_tree().process_frame
				TimeManager.emit_signal("time_loaded", TimeManager.total_seconds)
				TimeManager.resume_time()
				print("🕓 Tiempo restaurado definitivamente tras LOAD:", TimeManager.get_time_string())

			print("✅ Slot ", slot_index, " cargado exitosamente y tiempo reanudado")
			PlayerManager.player.restore_movement()
