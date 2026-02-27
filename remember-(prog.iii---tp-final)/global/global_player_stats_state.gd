#GlobalPlayerStatsState (autoload):

extends Node

var saved_stats: Dictionary = {}

# -----------------------
# SINCRONIZACIÓN
# -----------------------
func sync_from_player() -> void:
	if PlayerManager and PlayerManager.player and PlayerManager.player.stats:
		saved_stats = PlayerManager.player.stats.get_save_data()
	else:
		saved_stats = saved_stats

# -----------------------
# APLICAR AL PLAYER
# -----------------------
func apply_to_player() -> void:
	if not PlayerManager or not PlayerManager.player or not is_instance_valid(PlayerManager.player):
		if saved_stats and saved_stats.size() > 0:
			PlayerManager.stats_snapshot = PlayerGlobalStats.new()
			PlayerManager.stats_snapshot.parse_save_data(saved_stats)
		return

	if not PlayerManager.player.stats:
		PlayerManager.player.stats = PlayerGlobalStats.new()

	if saved_stats and saved_stats.size() > 0:
		PlayerManager.player.stats.parse_save_data(saved_stats)

# -----------------------
# SERIALIZACIÓN (API sencilla para Thoth)
# -----------------------
func _get_serializable_state() -> Dictionary:
	# Llamado antes de que Thoth serialice: actualiza desde el jugador
	sync_from_player()
	return {"saved_stats": saved_stats}

func _set_serializable_state(state: Dictionary) -> void:
	if state.has("saved_stats"):
		saved_stats = state["saved_stats"].duplicate(true)
		apply_to_player()
