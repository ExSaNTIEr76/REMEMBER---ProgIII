#inventory_manager.gd:
extends Node


# Da ítems al jugador
@warning_ignore("shadowed_variable")
func give(id: int, count: int = 1) -> void:
	var item: ItemData = ItemDB.get_item(id)
	if not item: return
	PlayerManager.INVENTORY_DATA.add_item(item, count)
	_refresh_ui(item.type)


# Da todos los ítems del catálogo para testeo
@warning_ignore("shadowed_variable")
func give_all(count: int = 1) -> void:
	for id in ItemDB.catalog.keys():
		var item: ItemData = ItemDB.get_item(id)
		if item:
			PlayerManager.INVENTORY_DATA.add_item(item, count)
	print("✅ Todos los ítems agregados x", count)

	# Refrescar UI si hay algún menú abierto
	var menu := get_tree().root.get_node_or_null("Root/ItemsMenu")
	if menu and menu.visible:
		menu.inventory_container.update_inventory(
			PlayerManager.INVENTORY_DATA.get_all_items()
		)


# Quita todos los ítems del catálogo para testeo
@warning_ignore("shadowed_variable")
func reset_all(count: int = 1) -> void:
	for id in ItemDB.catalog.keys():
		var item: ItemData = ItemDB.get_item(id)
		if item:
			PlayerManager.INVENTORY_DATA.remove_item(item, count)
	print("✅ Todos los ítems agregados x", count)

	# Refrescar UI si hay algún menú abierto
	var menu := get_tree().root.get_node_or_null("Root/ItemsMenu")
	if menu and menu.visible:
		menu.inventory_container.update_inventory(
			PlayerManager.INVENTORY_DATA.get_all_items()
		)


# Quitar ítems
@warning_ignore("shadowed_variable")
func take(id: int, count: int = 1) -> void:
	var item: ItemData = ItemDB.get_item(id)
	if not item: return
	PlayerManager.INVENTORY_DATA.remove_item(item, count)
	_refresh_ui(item.type)



#InventoryManager.give(ItemDB.IDs.LUCK_TICKET, 3)
#InventoryManager.take(ItemDB.IDs.FORTUNE_TICKET, 1)
#print(InventoryManager.count(ItemDB.IDs.LUCK_TICKET))



#-------------------------------------------------------------------------------


# Obtener cantidad
func count(id: int) -> int:
	var item: ItemData = ItemDB.get_item(id)
	if not item: return 0
	return PlayerManager.INVENTORY_DATA.get_quantity(item)


# Refresca menú si está abierto
func _refresh_ui(item_type: ItemData.ItemType) -> void:
	var menu := get_tree().root.get_node_or_null("Root/ItemsMenu") # adaptá la ruta real
	if menu and menu.visible:
		menu.inventory_container.update_inventory(
			PlayerManager.INVENTORY_DATA.get_items_by_type(item_type)
		)


#-------------------------------------------------------------------------------


# Manejo de créditos (currency del juego)

func add_credits(amount: int) -> void:
	var player := PlayerManager.player
	if not player or not is_instance_valid(player):
		push_warning("⚠️ No se pudo agregar créditos: el jugador no existe.")
		return

	var current = PlayerManager.get_stat("CREDITS")
	PlayerManager.set_credits(current + amount)

	print("💰 Créditos actuales:", PlayerManager.get_stat("CREDITS"))



func remove_credits(amount: int) -> void:
	add_credits(-amount)


func get_credits() -> int:
	var player := PlayerManager.player
	if not player or not is_instance_valid(player):
		return 0
	var stats = player.stats
	return stats.CREDITS if stats else 0



#-------------------------------------------------------------------------------


# Detecta si hay llave para cierto tipo de candado
func has_key_for(padlock_type: String) -> bool:
	match padlock_type:
		"Simple":
			return count(ItemDB.IDs.SMALL_KEY) > 0
		"Complex":
			return count(ItemDB.IDs.GILDED_KEY) > 0
		_:
			return false


# Consume la llave adecuada
func use_key_for(padlock_type: String) -> bool:
	if has_key_for(padlock_type):
		match padlock_type:
			"Simple":
				take(ItemDB.IDs.SMALL_KEY, 1)
			"Complex":
				take(ItemDB.IDs.GILDED_KEY, 1)
		return true
	return false


#-------------------------------------------------------------------------------


# Verifica si el jugador tiene uno o más ítems de una lista
func has_any_item(ids: Array) -> bool:
	for id in ids:
		if count(id) > 0:
			return true
	return false


# Verifica si el jugador tiene *todos* los ítems de una lista
func has_all_items(ids: Array) -> bool:
	for id in ids:
		if count(id) <= 0:
			return false
	return true


# Versión flexible: admite lista de ítems
func is_player_has_item(ids: Array, require_all: bool = false) -> bool:
	if require_all:
		return has_all_items(ids)
	else:
		return has_any_item(ids)


#-------------------------------------------------------------------------------

# InventoryManager.gd
func show_item_popup_by_id(id: int, quantity := 1) -> void:
	var item = ItemDB.get_item(id)
	if not item:
		return
	TextPopup.show_item_popup(item.name, quantity, item.type, item.texture)
