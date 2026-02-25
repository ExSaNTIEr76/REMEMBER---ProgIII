class_name InventoryData    extends Resource

signal inventory_changed

# Diccionario: { ID : cantidad }
var items: Dictionary = {}

func add_item(item: ItemData, count: int = 1) -> void:
	if not item: return
	if not items.has(item.ID):
		items[item.ID] = 0
	items[item.ID] += count
	inventory_changed.emit()

func remove_item(item: ItemData, count: int = 1) -> void:
	if not items.has(item.ID): return
	items[item.ID] -= count
	if items[item.ID] <= 0:
		items.erase(item.ID)
	inventory_changed.emit()

func get_quantity(item: ItemData) -> int:
	return items.get(item.ID, 0)

func has_item(item: ItemData, count: int = 1) -> bool:
	return get_quantity(item) >= count

func get_items_by_type(item_type: ItemData.ItemType) -> Array[ItemData]:
	var result: Array[ItemData] = []
	for id in items.keys():
		var data: ItemData = ItemDB.get_item(id)
		if data and data.type == item_type:
			result.append(data)
	result.sort_custom(func(a, b): return a.ID < b.ID)
	return result

# --- Save / Load ---
func get_save_data() -> Dictionary:
	return items.duplicate()

func parse_save_data(data: Dictionary) -> void:
	items.clear()
	for key in data.keys():
		var int_id = int(key) # 👈 siempre casteamos
		items[int_id] = data[key]
	inventory_changed.emit()
