# ThothGameState.gd (escena autoload):

extends Node

const SAVE_PATH := "user://Saves/"
const SAVE_FILE_PATTERN := "save_%d.sav"
const MAX_SLOTS := 30

var loading_from_save: bool = false
var current_slot: int = -1

var game_state := {
	"globals": {},
	"maps": {}
}
var save_data := {}

func _ready() -> void:
	# Asegurar directorio de saves
	if not DirAccess.dir_exists_absolute(SAVE_PATH):
		DirAccess.make_dir_absolute(SAVE_PATH)


func get_save_info(slot_index: int) -> Dictionary:
	var file_path := SAVE_PATH.path_join(SAVE_FILE_PATTERN % slot_index)
	if not FileAccess.file_exists(file_path):
		return {}

	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}

	var json_conv = JSON.new()
	var err = json_conv.parse(file.get_line())
	file.close()
	if err != OK:
		return {}

	var save_dict: Dictionary = json_conv.get_data()
	if not save_dict.has("game_state"):
		return {}

	var globals = save_dict["game_state"].get("globals", {})
	var info: Dictionary = {}
	info["slot_index"] = slot_index

	# Preferir save_date top-level (ya formateado en save_menu), fallback al sistema
	info["save_date"] = save_dict.get("save_date", Time.get_datetime_string_from_system()).split("T")[0]

	# play_time top-level (nos lo inyectamos en save_menu)
	info["play_time"] = save_dict.get("play_time", "00:00:00")

	# Top-level direct values (si existen) — más fiables
	info["player_level"] = int(save_dict.get("player_level", -1))
	info["credits"] = int(save_dict.get("credits", -1))
	info["player_name"] = str(save_dict.get("player_name", ""))
	info["level_name"] = str(save_dict.get("level_name", ""))
	info["zone_name"] = str(save_dict.get("zone_name", ""))
	info["zone_tag"] = str(save_dict.get("zone_tag", "Empty"))
	info["map_discovered"] = int(save_dict.get("map_discovered", -1))

	# Si no vinieron en top-level, intentamos reconstruir desde globals (fallback)
	if info["player_level"] == -1 or info["credits"] == -1:
		# 🧩 Buscar PlayerManager en globals (estructura serializada)
		var pm_vars := {}
		if globals.has("PlayerManager") and globals["PlayerManager"].has("variables"):
			pm_vars = globals["PlayerManager"]["variables"]

		if pm_vars:
			if pm_vars.has("stats") and pm_vars["stats"].has("data"):
				var stats = pm_vars["stats"]["data"]
				info["player_level"] = int(stats.get("CURRENT_LEVEL", 1))
				info["credits"] = int(stats.get("CREDITS", 0))
			else:
				info["player_level"] = int(pm_vars.get("CURRENT_LEVEL", 1))
				info["credits"] = int(pm_vars.get("CREDITS", 0))

	# Si falta player_name / level_name / zone_tag en top-level, intentar GlobalConditions
	var gc_vars := {}
	if globals.has("GlobalConditions") and globals["GlobalConditions"].has("variables"):
		gc_vars = globals["GlobalConditions"]["variables"]

	if info["player_name"] == "":
		info["player_name"] = gc_vars.get("player_name", "???")
	if info["level_name"] == "" or info["zone_name"] == "":
		info["level_name"] = gc_vars.get("level_name", info.get("level_name", "???"))
		info["zone_name"] = gc_vars.get("zone_name", info.get("zone_name", "???"))
	if info["zone_tag"] == "Empty" or info["zone_tag"] == "":
		info["zone_tag"] = gc_vars.get("zone_tag", "Empty")
	if info["map_discovered"] == -1:
		info["map_discovered"] = int(gc_vars.get("map_discovered", 0))

	print("🔍 Globals disponibles en save slot ", slot_index, ": ", globals.keys())
	return info



# ---------------------------
#  API compatible con SaveMenu
# ---------------------------

func save_exists(slot_index: int) -> bool:
	var file_path := SAVE_PATH.path_join(SAVE_FILE_PATTERN % slot_index)
	return FileAccess.file_exists(file_path)


func load_game_state(slot_index: int) -> void:
	var file_path := SAVE_PATH.path_join(SAVE_FILE_PATTERN % slot_index)
	if FileAccess.file_exists(file_path):
		_load_save_data(file_path)
		if save_data.has("game_state"):
			game_state = save_data["game_state"]
		else:
			_init_new_state()
	else:
		# ❌ No inventar saves en LOAD
		push_warning("⚠️ Intentaste cargar un slot vacío: %s" % file_path)
		_init_new_state()


func save_game_state(slot_index: int) -> void:
	var file_path := SAVE_PATH.path_join(SAVE_FILE_PATTERN % slot_index)

	# 🧩 Insertar game_state actual dentro de save_data
	save_data["game_state"] = game_state.duplicate(true)

	# 🕒 Garantizar que el tiempo jugado se mantenga o se actualice correctamente
	if save_data.has("play_time") and typeof(save_data["play_time"]) == TYPE_STRING:
		save_data["play_time"] = save_data["play_time"]  # conservar si ya venía del SaveMenu
	elif Engine.has_singleton("TimeManager"):
		save_data["play_time"] = TimeManager.get_time_string()
	else:
		save_data["play_time"] = "00:00:00"

	# 🗓️ Guardar fecha actual si no la tiene
	if not save_data.has("save_date"):
		save_data["save_date"] = Time.get_datetime_string_from_system().split("T")[0]

	print("💾 Guardando save_data con play_time:", save_data.get("play_time"))
	_save_save_data(file_path)


# ---------------------------
#  Helpers para game_state
# ---------------------------

func visited_level(level) -> bool:
	if level == null:
		return false
	if typeof(level) == TYPE_STRING:
		return game_state.maps.has(level)
	return game_state.maps.has(level.scene_file_path)


func clear_level_history(level_filename: String) -> void:
	game_state.maps.erase(level_filename)


func pack_level(level: Node) -> void:
	game_state.maps[level.scene_file_path] = ThothSerializer._serialize_object(level)


func unpack_level(level: Node) -> void:
	if level == null:
		push_warning("⚠️ No se pudo hacer unpack: nivel nulo")
		return
	var path := level.scene_file_path
	if not game_state.maps.has(path):
		push_warning("⚠️ El nivel '%s' no está en game_state.maps" % path)
		return
	ThothDeserializer._deserialize_object(game_state.maps[path], level)
	ThothDeserializer._deserialize_solve_references(level)


func set_game_variables(target) -> void:
	if target is Node:
		game_state.globals[target.name] = ThothSerializer._serialize_object(target)
	elif target is Resource:
		var key = target.resource_name if target.resource_name != "" else target.get_class()
		game_state.globals[key] = ThothSerializer._serialize_object(target)
	else:
		push_warning("⚠️ set_game_variables recibió tipo no soportado: %s" % [typeof(target)])



func get_game_variables(target) -> void:
	var key := ""
	if target is Node:
		key = target.name
	elif target is Resource:
		key = target.resource_name if target.resource_name != "" else target.get_class()
	else:
		push_warning("⚠️ get_game_variables recibió tipo no soportado: %s" % [typeof(target)])
		return

	if game_state.globals.has(key):
		ThothDeserializer._deserialize_object(game_state.globals[key], target)



# ---------------------------
#  Internos de IO
# ---------------------------

func _init_new_state() -> void:
	save_data = {}
	game_state = {
		"globals": {},
		"maps": {}
	}
	save_data["game_state"] = game_state


func _load_save_data(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_conv = JSON.new()
	json_conv.parse(file.get_line())
	save_data = json_conv.get_data()
	file.close()


func _load_slot_data(slot_index: int) -> Dictionary:
	var file_path := SAVE_PATH.path_join(SAVE_FILE_PATTERN % slot_index)
	if not FileAccess.file_exists(file_path):
		return {}
	var f := FileAccess.open(file_path, FileAccess.READ)
	if not f:
		return {}
	var json := JSON.new()
	var err = json.parse(f.get_line())
	f.close()
	if err != OK:
		return {}
	return json.get_data()


func _save_save_data(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_line(JSON.new().stringify(save_data))
	file.close()


# ---------------------------
#  Helpers específicos de Player
# ---------------------------

func get_player_position() -> Vector2:
	if not save_data.has("game_state"):
		return Vector2.ZERO
	var globals = save_data["game_state"].get("globals", {})
	if not globals.has("PlayerManager"):
		return Vector2.ZERO
	var player_data = globals["PlayerManager"]
	if player_data.has("saved_position"):
		var pos = player_data["saved_position"]
		# El deserializer guarda como dict { "x": ..., "y": ... }
		if typeof(pos) == TYPE_DICTIONARY and pos.has("x") and pos.has("y"):
			return Vector2(pos["x"], pos["y"])
	return Vector2.ZERO


func set_player_position(pos: Vector2) -> void:
	if not save_data.has("game_state"):
		save_data["game_state"] = { "globals": {}, "maps": {} }
	var globals = save_data["game_state"].get("globals", {})
	if not globals.has("PlayerManager"):
		globals["PlayerManager"] = {}
	var player_data = globals["PlayerManager"]
	player_data["saved_position"] = { "x": pos.x, "y": pos.y }
	globals["PlayerManager"] = player_data
	save_data["game_state"]["globals"] = globals
