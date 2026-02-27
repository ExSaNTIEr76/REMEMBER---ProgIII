#GlobalCinematicsState (autoload):

extends Node

var cinematics_triggered: Dictionary = {}

# Serialización: convertir el diccionario en un array
func _get_serializable_state() -> Dictionary:
	return {
		"cinematics_triggered": cinematics_triggered.keys()
	}


# Deserialización: reconstruir diccionario desde array
func _set_serializable_state(state: Dictionary) -> void:
	cinematics_triggered.clear()
	if state.has("cinematics_triggered"):
		for cinematic_name in state["cinematics_triggered"]:
			cinematics_triggered[cinematic_name] = true


func reset_state() -> void:
	cinematics_triggered.clear()


@warning_ignore("shadowed_variable_base_class")
func has_cinematic(name: String) -> bool:
	return cinematics_triggered.has(name)


@warning_ignore("shadowed_variable_base_class")
func mark_cinematic(name: String) -> void:
	cinematics_triggered[name] = true
