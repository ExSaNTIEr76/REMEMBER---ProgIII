class_name EquipmentData    extends Resource

signal equipment_changed


# Diccionario: { slot_name : item_id }
var equipped: Dictionary = {
	"DEFENSIVE 1": null,
	"DEFENSIVE 2": null,
	"SPECIAL 1": null,
	"SPECIAL 2": null,
	"CONCRETE A": null,
	"CONCRETE B": null,
	"ABSTRACT": null,
}


# -------------------------------------------------
# EQUIP
# -------------------------------------------------
func equip(slot_name: String, item: ItemData) -> void:
	if not equipped.has(slot_name):
		return

	# 🔁 Si había algo equipado antes, devolverlo
	var previous_id = equipped[slot_name]
	if previous_id != null:
		var previous_item := ItemDB.get_item(previous_id)
		if previous_item and _is_finite(previous_item):
			PlayerManager.INVENTORY_DATA.add_item(previous_item, 1)

	# 🧠 Equipar nuevo
	equipped[slot_name] = item.ID

	# 📉 Consumir si es finito
	if _is_finite(item):
		PlayerManager.INVENTORY_DATA.remove_item(item, 1)

	equipment_changed.emit()


# -------------------------------------------------
# UNEQUIP
# -------------------------------------------------
func unequip(slot_name: String) -> void:
	if not equipped.has(slot_name):
		return

	var id = equipped[slot_name]
	if id == null:
		return

	var item := ItemDB.get_item(id)

	# ↩️ Devolver si corresponde
	if item and _is_finite(item):
		PlayerManager.INVENTORY_DATA.add_item(item, 1)

	equipped[slot_name] = null
	equipment_changed.emit()


# -------------------------------------------------
# GETTERS
# -------------------------------------------------
func get_equipped(slot_name: String) -> ItemData:
	if not equipped.has(slot_name):
		return null

	var id = equipped[slot_name]
	if id == null:
		return null

	return ItemDB.get_item(id)


# -------------------------------------------------
# HELPERS
# -------------------------------------------------
func _is_finite(item: ItemData) -> bool:
	return item.type in [
		ItemData.ItemType.DEF1,
		ItemData.ItemType.DEF2,
		ItemData.ItemType.SPECIAL
	]


# -------------------------------------------------
# SAVE / LOAD
# -------------------------------------------------
func get_save_data() -> Dictionary:
	return equipped.duplicate()


func parse_save_data(data: Dictionary) -> void:
	equipped = data.duplicate()
	equipment_changed.emit()
