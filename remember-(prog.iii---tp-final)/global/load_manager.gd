#load_manager.gd (autoload):
extends Node

signal load_completed(save_data: SaveData)
signal load_failed(error: String)

const SAVE_PATH := "user://Saves/"
const MAX_SLOTS := 30
const SAVE_FILE_PATTERN := "save_%d.tres"

func load_slot(index: int) -> SaveData:
	if index < 0 or index >= MAX_SLOTS:
		load_failed.emit("Invalid slot index")
		return null

	var file_path := SAVE_PATH.path_join(SAVE_FILE_PATTERN % index)
	if not FileAccess.file_exists(file_path):
		load_failed.emit("Save file does not exist")
		return null

	var err = ResourceLoader.load_threaded_request(file_path, "Resource")
	if err != OK:
		load_failed.emit("Failed to start loading: " + error_string(err))
		return null

	# Esperar a que la carga termine
	var save_data: SaveData = null
	while true:
		var load_status = ResourceLoader.load_threaded_get_status(file_path)
		match load_status:
			ResourceLoader.THREAD_LOAD_LOADED:
				save_data = ResourceLoader.load_threaded_get(file_path)
				break
			ResourceLoader.THREAD_LOAD_FAILED:
				load_failed.emit("Failed to load save file")
				return null
			_:
				continue

	if not save_data is SaveData:
		load_failed.emit("Invalid save data format")
		return null

	load_completed.emit(save_data)
	return save_data

func load_all_saves() -> Array[Dictionary]:
	var loaded: Array[Dictionary] = []
	
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		return loaded
		
	var dir := DirAccess.open(SAVE_PATH)
	if not dir:
		push_error("Failed to open saves directory")
		return loaded
		
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while not file_name.is_empty():
		if not file_name.ends_with(".tres"):
			file_name = dir.get_next()
			continue
			
		var full_path := SAVE_PATH.path_join(file_name)
		var err := ResourceLoader.load_threaded_request(full_path, "Resource")
		if err != OK:
			push_error("Failed to load " + file_name)
			file_name = dir.get_next()
			continue
			
		# Esperar a que la carga termine
		var save_data: SaveData = null
		while true:
			var load_status = ResourceLoader.load_threaded_get_status(full_path)
			match load_status:
				ResourceLoader.THREAD_LOAD_LOADED:
					save_data = ResourceLoader.load_threaded_get(full_path)
					break
				ResourceLoader.THREAD_LOAD_FAILED:
					push_error("Failed to load " + file_name)
					break
				_:
					continue
					
		if save_data is SaveData:
			var slot_index := save_data.slot_index
			if slot_index >= 0 and slot_index < MAX_SLOTS:
				# Crear una copia limpia
				var clean_save := SaveData.new()
				clean_save.slot_index = save_data.slot_index
				clean_save.uuid = save_data.uuid
				clean_save.save_date = save_data.save_date
				clean_save.play_time = save_data.play_time
				clean_save.player_name = save_data.player_name
				clean_save.player_level = save_data.player_level
				clean_save.zone_name = save_data.zone_name
				clean_save.player_position = save_data.player_position
				clean_save.player_stats = save_data.player_stats.duplicate(true)
				#clean_save.player_inventory = save_data.player_inventory.duplicate(true)
				#clean_save.player_equipment = save_data.player_equipment.duplicate(true)
				#clean_save.player_quests = save_data.player_quests.duplicate(true)
				clean_save.world_state = save_data.world_state.duplicate(true)
				#clean_save.discovered_locations = save_data.discovered_locations.duplicate(true)
				#clean_save.completed_events = save_data.completed_events.duplicate(true)
				#clean_save.npc_states = save_data.npc_states.duplicate(true)
				#clean_save.environment_states = save_data.environment_states.duplicate(true)
				#clean_save.game_settings = save_data.game_settings.duplicate(true)
				clean_save.autoloads = save_data.autoloads.duplicate(true)
				
				loaded.append({
					"index": slot_index,
					"data": clean_save
				})
				
		file_name = dir.get_next()
		
	dir.list_dir_end()
	return loaded

func verify_save_integrity(save_data: SaveData) -> bool:
	if not save_data:
		return false
		
	# Verificar campos requeridos
	if save_data.slot_index < 0 or save_data.slot_index >= MAX_SLOTS:
		return false
	if save_data.uuid.is_empty():
		return false
	if save_data.save_date.is_empty():
		return false
		
	# Verificar que los diccionarios existan
	if not save_data.player_stats is Dictionary:
		return false
	if not save_data.world_state is Dictionary:
		return false
	if not save_data.autoloads is Dictionary:
		return false
		
	return true 
