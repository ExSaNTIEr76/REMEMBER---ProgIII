extends Resource
class_name SaveData

@export var uuid: String
@export var title: String
@export var slot_index: int
@export var player_name: String
@export var player_level: String
@export var zone_name: String
@export var save_date: String
@export var play_time: String

# Datos del jugador
@export var player_position: Vector2
@export var player_stats: Dictionary

# Estado del mundo y juego
@export var world_state: Dictionary
@export var autoloads: Dictionary

func _init():
	uuid = _generate_unique_id()
	save_date = Time.get_datetime_string_from_system()

func _generate_unique_id() -> String:
	return str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000).pad_zeros(3)

func clone() -> SaveData:
	var new_save := SaveData.new()
	
	# Copiamos las propiedades exportadas
	for property in get_property_list():
		if property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var value = get(property.name)
			if value is Dictionary:
				new_save.set(property.name, value.duplicate(true))
			elif value is Array:
				new_save.set(property.name, value.duplicate(true))
			else:
				new_save.set(property.name, value)
	
	# Generamos nuevo ID único
	new_save.uuid = new_save._generate_unique_id()
	new_save.save_date = Time.get_datetime_string_from_system()
	
	return new_save
