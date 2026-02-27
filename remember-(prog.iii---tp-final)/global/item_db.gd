# ItemDB.gd (escena autoload):

extends Node

const CATALOG_RESOURCE: ItemCatalog = preload("res://items/item_catalog.tres")
var catalog: Dictionary = {}

enum IDs {

# --- USABLES --- #
						
	LUCK_TICKET = 1,
	SIMPLE_SUPPLEMENTS = 2,
						

# --- KEYS --- #
						
	SMALL_KEY = 3,
	GILDED_KEY = 4,
	VALVE = 5,
						

# --- CONCRETE SYMBOLS --- #
						
	PUNCH_1 = 6,
	KNIFE_1 = 7,
	PICKAXE_1 = 8,
						

}

func _ready() -> void:
	if not CATALOG_RESOURCE:
		push_error("❌ ItemCatalog no encontrado.")
		return

	for item in CATALOG_RESOURCE.items:
		catalog[item.ID] = item

	#print("📦 ItemDB cargado:", catalog.size(), "items")


func get_item(id: int) -> ItemData:
	return catalog.get(id, null)
