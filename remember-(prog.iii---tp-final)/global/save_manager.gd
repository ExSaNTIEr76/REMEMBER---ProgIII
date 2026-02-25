#save_manager.gd (autoload):
extends Node

signal save_completed(slot_index: int)
signal save_failed(error: String)
signal save_deleted(slot_index: int)

const SAVE_PATH := "user://Saves/"
const MAX_SLOTS := 30
const SAVE_FILE_PATTERN := "save_%d.tres"
const BACKUP_EXTENSION := ".backup"

func _ready() -> void:
	# Asegurar que el directorio de guardado existe
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_absolute(SAVE_PATH)

func save_to_slot(index: int, data: SaveData) -> void:
	if index < 0 or index >= MAX_SLOTS:
		save_failed.emit("Invalid slot index")
		return

	# Preparar los datos
	var save_data := data.clone()  # Crear una copia limpia
	save_data.slot_index = index
	save_data.save_date = Time.get_datetime_string_from_system()

	var file_path := SAVE_PATH.path_join(SAVE_FILE_PATTERN % index)
	var backup_path := file_path + BACKUP_EXTENSION

	# Si existe un archivo, hacer backup primero
	if FileAccess.file_exists(file_path):
		var backup_err = DirAccess.copy_absolute(file_path, backup_path)
		if backup_err != OK:
			save_failed.emit("Failed to create backup: " + error_string(backup_err))
			return

	# Intentar guardar
	var save_err := ResourceSaver.save(save_data, file_path)
	if save_err != OK:
		save_failed.emit("Failed to save file: " + error_string(save_err))
		# Intentar restaurar backup si existe
		if FileAccess.file_exists(backup_path):
			DirAccess.copy_absolute(backup_path, file_path)
		return

	# Limpiar backup si el guardado fue exitoso
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_path)

	save_completed.emit(index)

func delete_save(index: int) -> void:
	if index < 0 or index >= MAX_SLOTS:
		save_failed.emit("Invalid slot index")
		return

	var file_path := SAVE_PATH.path_join(SAVE_FILE_PATTERN % index)
	if FileAccess.file_exists(file_path):
		var delete_err = DirAccess.remove_absolute(file_path)
		if delete_err != OK:
			save_failed.emit("Failed to delete save: " + error_string(delete_err))
			return
		save_deleted.emit(index)

func get_save_info(index: int) -> Dictionary:
	var file_path := SAVE_PATH.path_join(SAVE_FILE_PATTERN % index)
	if not FileAccess.file_exists(file_path):
		return {}

	var save_data = ResourceLoader.load(file_path) as SaveData
	if not save_data:
		return {}

	return {
		"slot_index": save_data.slot_index,
		"save_date": save_data.save_date,
		"play_time": save_data.play_time,
		"player_name": save_data.player_name,
		"player_level": save_data.player_level,
		"zone_name": save_data.zone_name
	}

func has_save(index: int) -> bool:
	var file_path := SAVE_PATH.path_join(SAVE_FILE_PATTERN % index)
	return FileAccess.file_exists(file_path)

func get_all_saves() -> Array:
	var saves := []
	for i in range(MAX_SLOTS):
		var info = get_save_info(i)
		if not info.is_empty():
			saves.append(info)
	return saves

func _exit_tree() -> void:
	# Limpiar cualquier backup que haya quedado
	var dir = DirAccess.open(SAVE_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(BACKUP_EXTENSION):
				dir.remove(file_name)
			file_name = dir.get_next() 
