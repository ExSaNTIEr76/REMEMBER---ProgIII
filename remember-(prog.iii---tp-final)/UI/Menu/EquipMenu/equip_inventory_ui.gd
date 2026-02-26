class_name EquipInventoryUI    extends Control

@export var INVENTORY_SLOT: PackedScene
@onready var equip_menu: EquipMenu

@onready var scroll_container := get_parent() as ScrollContainer

@export var data: InventoryData
var slots: Array[InventorySlotUI] = []

const IGNORED_EQUIP_PREFIXES := [
	"DEFENSIVO",
	"ESPECIAL",
	"CONCRETO",
	"ABSTRACTO",
	"SINGULAR"
]


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP

	GlobalMenuHub.hidden.connect(clear_inventory)
	clear_inventory()
	data.inventory_changed.connect(on_inventory_changed)


func clear_inventory() -> void:
	for c in get_children():
		if c is InventorySlotUI:
			var btn = c.item_button
			btn.focus_neighbor_top = NodePath("")
			btn.focus_neighbor_bottom = NodePath("")
			btn.focus_neighbor_left = NodePath("")
			btn.focus_neighbor_right = NodePath("")
		c.queue_free()
	slots.clear()


func update_inventory(item_list: Array[ItemData], preferred_idx: int = -1) -> void:
	clear_inventory()
	for item in item_list:
		var slot: InventorySlotUI = INVENTORY_SLOT.instantiate()
		add_child(slot)
		slot.equip_menu = equip_menu
		slot.set_item(item)
		slots.append(slot)


	# Restaurar focus al siguiente frame
	if preferred_idx >= 0:
		await get_tree().process_frame
		if preferred_idx < slots.size():
			slots[preferred_idx]._grab_focus()
		else:
			# fallback: volver al botón de categoría
			if equip_menu and equip_menu.last_button:
				equip_menu.last_button.grab_focus()


func _on_slot_hovered(_equip_type: String) -> void:
	if not equip_menu or not equip_menu.last_slot:
		return

	var t = equip_menu.last_slot.inventory_item_type
	if t == ItemData.ItemType.NONE:
		return

	update_inventory(
		PlayerManager.INVENTORY_DATA.get_items_by_type(t)
	)



func on_inventory_changed() -> void:
	if not visible:
		return

	var item_type := ItemData.ItemType.NONE

	if equip_menu and is_instance_valid(equip_menu.last_button):
		match equip_menu.last_button:
			equip_menu.defensive_1:      item_type = ItemData.ItemType.DEF1
			equip_menu.defensive_2:      item_type = ItemData.ItemType.DEF2
			equip_menu.special_1:        item_type = ItemData.ItemType.SPECIAL
			equip_menu.special_2:        item_type = ItemData.ItemType.SPECIAL
			equip_menu.concrete_a:       item_type = ItemData.ItemType.CONCRETE
			equip_menu.concrete_b:       item_type = ItemData.ItemType.CONCRETE
			equip_menu.abstract:         item_type = ItemData.ItemType.ABSTRACT
			equip_menu.singular:         item_type = ItemData.ItemType.SINGULAR

	if item_type != ItemData.ItemType.NONE:
		update_inventory(PlayerManager.INVENTORY_DATA.get_items_by_type(item_type))
