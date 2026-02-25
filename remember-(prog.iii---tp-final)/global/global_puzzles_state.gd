#GlobalPuzzlesState (autoload):

extends Node

signal state_restored

var puzzles_completed: Dictionary = {}


# 🔄 Serialización: convertir el diccionario en un array
func _get_serializable_state() -> Dictionary:
	return {
		"puzzles_completed": puzzles_completed.keys()
	}


# 🔄 Deserialización: reconstruir diccionario desde array
func _set_serializable_state(state: Dictionary) -> void:
	puzzles_completed.clear()
	if state.has("puzzles_completed"):
		for puzzle_name in state["puzzles_completed"]:
			puzzles_completed[puzzle_name] = true
	state_restored.emit()


func reset_state() -> void:
	puzzles_completed.clear()
	state_restored.emit()
