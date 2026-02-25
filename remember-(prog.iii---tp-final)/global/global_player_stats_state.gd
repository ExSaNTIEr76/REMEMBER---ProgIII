#GlobalPlayerStatsState (autoload):

extends Node

# Guarda la última representación serializable (Dictionary plano) de las stats
var saved_stats: Dictionary = {}

# -----------------------
# SINCRONIZACIÓN
# -----------------------
func sync_from_player() -> void:
	# Si el player tiene stats, pedimos su representación plana
	if PlayerManager and PlayerManager.player and PlayerManager.player.stats:
		# PlayerGlobalStats.get_save_data -> devuelve un Dictionary plano
		saved_stats = PlayerManager.player.stats.get_save_data()
	else:
		# mantener lo que teníamos si no hay player
		saved_stats = saved_stats

# -----------------------
# APLICAR AL PLAYER
# -----------------------
func apply_to_player() -> void:
	# Solo aplicamos si hay player y stats
	if not PlayerManager or not PlayerManager.player or not is_instance_valid(PlayerManager.player):
		# Si no hay player aún, guardamos snapshot en PlayerManager para aplicar luego
		if saved_stats and saved_stats.size() > 0:
			PlayerManager.stats_snapshot = PlayerGlobalStats.new()
			PlayerManager.stats_snapshot.parse_save_data(saved_stats)
		return

	# Si no hay resource stats en el player, creamos uno y lo asignamos
	if not PlayerManager.player.stats:
		PlayerManager.player.stats = PlayerGlobalStats.new()

	# Aplicamos la data guardada (parse_save_data)
	if saved_stats and saved_stats.size() > 0:
		PlayerManager.player.stats.parse_save_data(saved_stats)

# -----------------------
# SERIALIZACIÓN (API sencilla para Thoth)
# -----------------------
func _get_serializable_state() -> Dictionary:
	# Llamado antes de que Thoth serialice: actualizamos desde el jugador
	sync_from_player()
	return {"saved_stats": saved_stats}

func _set_serializable_state(state: Dictionary) -> void:
	if state.has("saved_stats"):
		saved_stats = state["saved_stats"].duplicate(true)
		# aplicamos inmediatamente si hay player presente
		apply_to_player()

# Compatibilidad con savestate.set_game_variables / get_game_variables:
# ThothSerializer serializará este Node usando _get_serializable_state/_set_serializable_state
