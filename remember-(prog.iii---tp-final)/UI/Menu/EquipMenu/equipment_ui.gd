class_name EquipmentUI   extends Control

@onready var equipment_container: EquipmentUI = %EquipmentContainer

# BODY
@onready var defensive_1: EquipSlotUI = %"DEFENSIVE 1"
@onready var defensive_2: EquipSlotUI = %"DEFENSIVE 2"
@onready var special_1: EquipSlotUI = %"SPECIAL 1"
@onready var special_2: EquipSlotUI = %"SPECIAL 2"

# SYMBOLS
@onready var concrete_a: EquipSlotUI = %"CONCRETE A"
@onready var concrete_b: EquipSlotUI = %"CONCRETE B"
@onready var abstract: EquipSlotUI = %ABSTRACT

const EQUIP_SLOT = preload("res://UI/Menu/EquipMenu/equip_slot.tscn")
@onready var equip_menu: EquipMenu

@export var data = PlayerManager.EQUIPMENT_DATA
var slots: Dictionary = {}


func _ready() -> void:
	slots = {
		"DEFENSIVO 1": defensive_1,
		"DEFENSIVO 2": defensive_2,
		"ESPECIAL 1": special_1,
		"ESPECIAL 2": special_2,
		"CONCRETO A": concrete_a,
		"CONCRETO B": concrete_b,
		"ABSTRACTO": abstract,
	}

	for slot in slots.values():
		slot.equip_menu = equip_menu

	for t in slots.keys():
		slots[t].slot_hovered.connect(_on_slot_hovered)

	if data:
		data.equipment_changed.connect(update_from_data)
		update_from_data()
	
	#print("🧠 EquipmentData instance:", data.get_instance_id())



func _on_slot_hovered(equip_type: String) -> void:
	if equip_menu:
		equip_menu.preview_slot_items(equip_type)


func update_from_data() -> void:
	for t in slots.keys():
		var item := data.get_equipped(t)
		if item:
			slots[t].set_item(item)
		else:
			slots[t].clear()


func set_equip_menu(menu: EquipMenu) -> void:
	equip_menu = menu
	for slot in slots.values():
		slot.equip_menu = menu


func set_equipped(equip_type: String, item: ItemData) -> void:
	if not slots.has(equip_type): return
	slots[equip_type].set_item(item)


func update_equipment(equipped_items: Dictionary) -> void:
	# expected format: { "DEFENSIVE1": ItemData, "SPECIAL1": ItemData, ... }
	for t in slots.keys():
		if equipped_items.has(t) and equipped_items[t]:
			slots[t].set_item(equipped_items[t])
		else:
			slots[t].clear()


func on_inventory_changed() -> void:
	if not visible: return

	# respetar categoría activa
	var menu := equip_menu
	if not menu or not is_instance_valid(menu.last_button):
		return

	var _item_type := ItemData.ItemType.DEF1
	match menu.last_button:
		menu.defensive_1:      _item_type = ItemData.ItemType.DEF1
		menu.defensive_2:      _item_type = ItemData.ItemType.DEF2
		menu.special_1:        _item_type = ItemData.ItemType.SPECIAL
		menu.special_2:        _item_type = ItemData.ItemType.SPECIAL

		menu.concrete_a:       _item_type = ItemData.ItemType.CONCRETE
		menu.concrete_b:       _item_type = ItemData.ItemType.CONCRETE
		menu.abstract:         _item_type = ItemData.ItemType.ABSTRACT

	#update_equipment(data.get_items_by_type(_item_type))
