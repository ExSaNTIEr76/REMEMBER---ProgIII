#NewGameManager.gd (autoload):

extends Node

func start_new_game() -> void:
	print("🆕 Iniciando New Game...")

	# Resetear estados globales
	GlobalCinematicsState.reset_state()
	GlobalChestsState.reset_state()
	GlobalPuzzlesState.reset_state()
	GlobalFightsState.reset_state()

	GlobalConditions.reset_conditions()
	InventoryManager.remove_credits(9999999)
	InventoryManager.reset_all()

	# Resetear PlayerManager
	PlayerManager.reset_stats()

	print("✅ New Game listo.")
