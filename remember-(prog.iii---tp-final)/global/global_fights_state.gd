#GlobalFightssState (autoload):

extends Node

var fights_completed: Dictionary = {}


# 🔄 Serialización: convertir el diccionario en un array
func _get_serializable_state() -> Dictionary:
	return {
		"fights_completed": fights_completed.keys()
	}


# 🔄 Deserialización: reconstruir diccionario desde array
func _set_serializable_state(state: Dictionary) -> void:
	fights_completed.clear()
	if state.has("fights_completed"):
		for fight_name in state["fights_completed"]:
			fights_completed[fight_name] = true


func reset_state() -> void:
	fights_completed.clear()
