class_name InventoryUI    extends Control

const INVENTORY_SLOT = preload("res://UI/Menu/ItemsMenu/inventory/inventory_slot.tscn")
@onready var items_menu: ItemsMenu

var data: InventoryData
var slots: Array[InventorySlotUI] = []


func _ready() -> void:
	GlobalMenuHub.hidden.connect(clear_inventory)
	clear_inventory()
	data = PlayerManager.INVENTORY_DATA
	data.inventory_changed.connect(on_inventory_changed)


func clear_inventory() -> void:
	for c in get_children():
		c.queue_free()
	slots.clear()


func update_inventory(item_list: Array[ItemData], preferred_idx: int = -1) -> void:
	clear_inventory()
	for item in item_list:
		var slot: InventorySlotUI = INVENTORY_SLOT.instantiate()
		add_child(slot)
		slot.items_menu = items_menu
		slot.set_item(item)
		slots.append(slot)
		#print("InventoryUI.update_inventory: count=", item_list.size())

	# Restaurar focus al siguiente frame
	if preferred_idx >= 0:
		await get_tree().process_frame
		if preferred_idx < slots.size():
			slots[preferred_idx]._grab_focus()
		else:
			# Fallback: volver al botón de categoría
			if items_menu and items_menu.last_button:
				items_menu.last_button.grab_focus()


func on_inventory_changed() -> void:
	if not visible: return

	var menu := items_menu
	if not menu or not is_instance_valid(menu.last_button):
		return

	var item_type := ItemData.ItemType.CONSUMABLE
	match menu.last_button:
		menu.button_usables:       item_type = ItemData.ItemType.CONSUMABLE
		menu.button_keys:          item_type = ItemData.ItemType.KEY
		menu.button_materials:     item_type = ItemData.ItemType.MATERIAL
		menu.button_miscellaneous: item_type = ItemData.ItemType.MISCELLANEOUS

	update_inventory(data.get_items_by_type(item_type))
