# GlobalInventoryState (autoload)

extends Node

# Diccionario único con todo el estado
var all_inventory_state: Dictionary = {
	"inventory_data": {},
	"equipment_data": {}
}

# ----------------------------------------------------
# SINCRONIZACIÓN
# ----------------------------------------------------

func sync_from_player() -> void:
	# Guardar items
	if PlayerManager and PlayerManager.INVENTORY_DATA:
		all_inventory_state["inventory_data"] = PlayerManager.INVENTORY_DATA.get_save_data()

	# Guardar equipamiento
	if PlayerManager and PlayerManager.EQUIPMENT_DATA:
		all_inventory_state["equipment_data"] = PlayerManager.EQUIPMENT_DATA.get_save_data()


func apply_to_player() -> void:
	# Restaurar items
	if all_inventory_state.has("inventory_data") and PlayerManager and PlayerManager.INVENTORY_DATA:
		PlayerManager.INVENTORY_DATA.parse_save_data(all_inventory_state["inventory_data"])

	# Restaurar equipamiento
	if all_inventory_state.has("equipment_data") and PlayerManager and PlayerManager.EQUIPMENT_DATA:
		PlayerManager.EQUIPMENT_DATA.parse_save_data(all_inventory_state["equipment_data"])

# ----------------------------------------------------
# SERIALIZACIÓN
# ----------------------------------------------------

func _get_serializable_state() -> Dictionary:
	sync_from_player()
	return {
		"all_inventory_state": all_inventory_state
	}

func _set_serializable_state(state: Dictionary) -> void:
	if state.has("all_inventory_state"):
		all_inventory_state = state["all_inventory_state"].duplicate(true)
		apply_to_player()
