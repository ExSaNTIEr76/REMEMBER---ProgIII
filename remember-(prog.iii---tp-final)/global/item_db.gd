# ItemDB.gd (autoload):
extends Node

var catalog: Dictionary = {}

enum IDs {
	
	# --- USABLES --- #
	
	LUCK_TICKET = 1,
	FORTUNE_TICKET = 2,
	SIMPLE_SUPPLEMENTS = 3,
	HIGH_SUPPLEMENTS = 4,
	RELAXING_INCENSE = 5,
	
	CARBON_DESTILLATE = 8,
	MAGNESIUM_DESTILLATE = 9,
	IRON_DESTILLATE = 10,
	
	
	# --- KEYS --- #
	
	SMALL_KEY = 25,
	GILDED_KEY = 26,
	VALVE = 27,
	
	
	# --- MATERIALS --- #
	
	MOLOCH_MEAT = 30,
	AMDUSIAS_MEAT = 31,
	BATHALA_MEAT = 32,
	EYE = 33,
	
	
	
	# --- MISCELLANEOUS --- #
	
	TRAM_PASSPORT = 50,
	LEO_CARD = 55,
	CANCER_CARD = 56,
	PISCES_CARD = 57,
	AQUARIUS_CARD = 58,
	SAGITTARIUS_CARD = 59,
	ARIES_CARD = 60,
	
	
	# --- DEFENSIVE 1 --- #
	
	COMFY_HOODIE = 100,
	PILGRIM_TUNIC = 110,
	
	
	# --- DEFENSIVE 2 --- #
	
	STRONG_SPIRIT = 120,
	
	FLEXIBLE_SPIRIT = 123,
	
	COLOUR_OF_OBLIVION = 130,
	COLOUR_OF_OPTIMISM = 131,
	COLOUR_OF_ANGER = 132,
	
	COLOUR_OF_SACRIFICE = 135,
	
	
	# --- SPECIAL --- #
	
	JOKER = 140,
	
	
	# --- CONCRETE SYMBOLS --- #
	
	PUNCH_1 = 180,
	PUNCH_2 = 181,
	
	KNIFE_1 = 182,
	KNIFE_2 = 183,
	
	PICKAXE_1 = 184,
	PICKAXE_2 = 185,
	
	BOMB_1 = 194,
	BOMB_2 = 195,
	
	BLOCK_1 = 196,
	BLOCK_2 = 197,
	
	
	# --- ABSTRACT SYMBOLS --- #
	
	THORNS = 220,
	TWINS = 221,
	
	TEMPEST = 229,
	
	
	# --- SINGULAR SYMBOLS --- #
	
	SHIELD_1 = 260,
	SHIELD_2 = 261,
	SHIELD_3 = 262,
	DODGE_1 = 263,
	
	ULTRAVISION = 266,
	ARITHMETIC = 267,
	CANDELA_1 = 268,
	CANDELA_2 = 269,
}

func _ready() -> void:
	load_items_from_folder("res://items/")

func load_items_from_folder(path: String) -> void:
	var dir = DirAccess.open(path)
	if not dir: return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and not file_name.begins_with("."):
			load_items_from_folder(path + "/" + file_name) # 👈 Recurse
		elif file_name.ends_with(".tres"):
			var data: ItemData = load(path + "/" + file_name)
			if data:
				catalog[data.ID] = data
		file_name = dir.get_next()
	dir.list_dir_end()


# 🚀 renombrada
func get_item(id: int) -> ItemData:
	return catalog.get(id, null)
