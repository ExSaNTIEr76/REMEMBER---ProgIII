#persistence.gd (la escena es un autoload)
extends Node

signal save_created(save_data: SaveData)
signal save_loaded(save_data: SaveData)
signal save_failed(error: String)

var current_save: SaveData
var _start_time: int

func _ready() -> void:
	_start_time = int(Time.get_unix_time_from_system())

func get_play_time() -> String:
	var current_time := int(Time.get_unix_time_from_system())
	var total_seconds := current_time - _start_time
	var hours := floori(total_seconds / 3600.0)
	var minutes := floori((total_seconds - hours * 3600) / 60.0)
	var seconds := total_seconds % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func save() -> void:
	current_save = generate_save_data()

func load_data(data: SaveData) -> void:
	if not data:
		save_failed.emit("Invalid save data")
		return
	current_save = data
	_restore_game_state(data)
	save_loaded.emit(data)

func generate_save_data() -> SaveData:
	var save_data = SaveData.new()
	
	# Datos básicos
	save_data.player_name = GlobalConditions.player_name
	save_data.player_level = GlobalConditions.level_name
	save_data.zone_name = GlobalConditions.zone_name
	save_data.play_time = get_play_time()
	
	# Datos del jugador
	if PlayerManager.player:
		save_data.player_position = PlayerManager.player.global_position
		save_data.player_stats = _collect_player_stats()
	
	# Datos del mundo y estado del juego
	save_data.world_state = _collect_world_state()
	save_data.autoloads = _collect_autoloads()
	
	save_created.emit(save_data)
	return save_data

func _collect_player_stats() -> Dictionary:
	var stats := {}
	var player = PlayerManager.player
	
	if player:
		# Stats básicos
		stats["hp"] = player.stats.CURRENT_HP
		stats["max_hp"] = player.stats.MAX_HP
		stats["cp"] = player.stats.CURRENT_CP
		stats["max_cp"] = player.stats.MAX_CP
		stats["ep"] = player.stats.CURRENT_EP
		stats["max_ep"] = player.stats.MAX_EP
		
		# Stats de nivel y experiencia
		stats["level"] = player.stats.CURRENT_LEVEL
		stats["xp"] = player.stats.XP
		stats["next_exp"] = player.stats.NEXT_EXP
		
		# Atributos
		stats["atk"] = player.stats.ATK
		stats["str"] = player.stats.STR
		stats["int"] = player.stats.INT
		stats["def"] = player.stats.DEF
		stats["con"] = player.stats.CON
		stats["lck"] = player.stats.LCK
		
		# Estado alterado
		stats["altered_state"] = player.stats.CURRENT_ALTERED_STATE
		
		# Créditos y otros
		stats["credits"] = player.stats.CREDITS
		stats["speed"] = player.stats.speed
		stats["running_speed_multiplier"] = player.stats.running_speed_multiplier
	
	return stats

func _collect_world_state() -> Dictionary:
	var state := {}
	
	# Estado del nivel actual
	state["current_level"] = LevelManager.get_current_level()
	state["current_zone"] = LevelManager.get_current_zone()
	
	# Estado de los nodos persistentes
	var persist_nodes = get_tree().get_nodes_in_group("Persist")
	for node in persist_nodes:
		if node.has_method("get_save_data"):
			var node_path = node.get_path()
			state[node_path] = node.get_save_data()
	
	return state

func _collect_autoloads() -> Dictionary:
	var autoloads := {}
	var autoload_list = ProjectSettings.get_setting("autoload", {})
	
	for autoload_name in autoload_list.keys():
		if autoload_name == "Persistence" or autoload_name == name:
			continue
		
		var node = get_node_or_null("/root/" + autoload_name)
		if not node:
			continue
		
		if node.has_method("get_save_data"):
			autoloads[autoload_name] = node.get_save_data()
		else:
			# Intentar serializar propiedades exportadas
			var data := {}
			for property in node.get_property_list():
				if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
					var value = node.get(property.name)
					if _is_serializable(value):
						data[property.name] = value
			if not data.is_empty():
				autoloads[autoload_name] = data
	
	return autoloads

func _restore_game_state(data: SaveData) -> void:
	# Restaurar datos básicos
	GlobalConditions.player_name = data.player_name
	GlobalConditions.level_name = data.player_level
	GlobalConditions.zone_name = data.zone_name
	
	# Restaurar datos del jugador
	if PlayerManager.player and data.player_position:
		PlayerManager.player.global_position = data.player_position
		if data.player_stats:
			_restore_player_stats(data.player_stats)
	
	# Restaurar estado del mundo
	_restore_world_state(data.world_state)
	
	# Restaurar autoloads
	_restore_autoloads(data.autoloads)

func _restore_player_stats(stats: Dictionary) -> void:
	var player = PlayerManager.player
	if not player:
		return
	
	# Stats básicos
	player.stats.CURRENT_HP = stats.get("hp", player.stats.CURRENT_HP)
	player.stats.MAX_HP = stats.get("max_hp", player.stats.MAX_HP)
	player.stats.CURRENT_CP = stats.get("cp", player.stats.CURRENT_CP)
	player.stats.MAX_CP = stats.get("max_cp", player.stats.MAX_CP)
	player.stats.CURRENT_EP = stats.get("ep", player.stats.CURRENT_EP)
	player.stats.MAX_EP = stats.get("max_ep", player.stats.MAX_EP)
	
	# Stats de nivel y experiencia
	player.stats.CURRENT_LEVEL = stats.get("level", player.stats.CURRENT_LEVEL)
	player.stats.XP = stats.get("xp", player.stats.XP)
	player.stats.NEXT_EXP = stats.get("next_exp", player.stats.NEXT_EXP)
	
	# Atributos
	player.stats.ATK = stats.get("atk", player.stats.ATK)
	player.stats.STR = stats.get("str", player.stats.STR)
	player.stats.INT = stats.get("int", player.stats.INT)
	player.stats.DEF = stats.get("def", player.stats.DEF)
	player.stats.CON = stats.get("con", player.stats.CON)
	player.stats.LCK = stats.get("lck", player.stats.LCK)
	
	# Estado alterado
	player.stats.CURRENT_ALTERED_STATE = stats.get("altered_state", player.stats.CURRENT_ALTERED_STATE)
	
	# Créditos y otros
	player.stats.CREDITS = stats.get("credits", player.stats.CREDITS)
	player.stats.speed = stats.get("speed", player.stats.speed)
	player.stats.running_speed_multiplier = stats.get("running_speed_multiplier", player.stats.running_speed_multiplier)

func _restore_world_state(state: Dictionary) -> void:
	# Restaurar estado del nivel
	if "current_level" in state:
		LevelManager.set_current_level(state.current_level)
	if "current_zone" in state:
		LevelManager.set_current_zone(state.current_zone)
	
	# Restaurar nodos persistentes
	for node_path in state:
		if node_path == "current_level" or node_path == "current_zone":
			continue
		
		var node = get_node_or_null(node_path)
		if node and node.has_method("load_data"):
			node.load_data(state[node_path])

func _restore_autoloads(autoloads: Dictionary) -> void:
	for autoload_name in autoloads:
		var node = get_node_or_null("/root/" + autoload_name)
		if not node:
			continue
		
		var data = autoloads[autoload_name]
		if node.has_method("load_data"):
			node.load_data(data)
		else:
			# Restaurar propiedades individuales
			for key in data:
				if node.has_method("set"):
					node.set(key, data[key])

func _is_serializable(value) -> bool:
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING:
			return true
		TYPE_VECTOR2, TYPE_VECTOR3, TYPE_COLOR:
			return true
		TYPE_DICTIONARY, TYPE_ARRAY:
			return true
		_:
			return false

 
