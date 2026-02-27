#GlobalChestsState (autoload):

extends Node

signal state_restored

var chests_triggered: Dictionary = {}

# Serialización
func _get_serializable_state() -> Dictionary:
	return {
		"chests_triggered": chests_triggered.keys()
	}


# Deserialización
func _set_serializable_state(state: Dictionary) -> void:
	chests_triggered.clear()
	if state.has("chests_triggered"):
		for chest_name in state["chests_triggered"]:
			chests_triggered[chest_name] = true
	state_restored.emit()


func reset_state() -> void:
	chests_triggered.clear()
	state_restored.emit()
