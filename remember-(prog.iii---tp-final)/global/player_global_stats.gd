extends Node

#-----------------------------------------------------------------------------#

@export var MAX_HP: int = 100
@export var MAX_CP: int = 50
@export var MAX_EP: int = 10

@export var x : String = "-------------------------"

#-----------------------------------------------------------------------------#

@export var CURRENT_HP: int = 100
@export var CURRENT_CP: int = 50
@export var CURRENT_EP: int = 10

@export var CURRENT_ALTERED_STATE: DamageData.StatusEffect = DamageData.StatusEffect.PURE

@export var x_ : String = "-------------------------"

#-----------------------------------------------------------------------------#

@export var cp_regen_rate: int = 5 # CP por segundo
@export var cp_regen_interval: int = 1 # Cada cuánto tiempo se recupera

@export var x__ : String = "-------------------------"

#-----------------------------------------------------------------------------#

@export var ATK: int = 0
@export var STR: int = 0
@export var DEF: int = 0
@export var CON: int = 0
@export var ESP: int = 0
@export var LCK: int = 0

@export var x___ : String = "-------------------------"

#-----------------------------------------------------------------------------#

@export var MAX_LEVEL: int = 99
@export var CURRENT_LEVEL: int = 1

@export var XP: int = 0
@export var NEXT_XP: int = 10

@export var CREDITS: int = 0

@export var X : String = "-------------------------"

#-----------------------------------------------------------------------------#

@export var speed: float = 40.0
@export var running_speed_multiplier: float = 2.5

#-----------------------------------------------------------------------------#

signal stats_changed

func set_current_hp(value: int) -> void:
	CURRENT_HP = clamp(value, 0, MAX_HP)
	notify_changed()

func set_current_cp(value: int) -> void:
	CURRENT_CP = clamp(value, 0, MAX_CP)
	notify_changed()

func set_current_ep(value: int) -> void:
	CURRENT_EP = clamp(value, 0, MAX_EP)
	notify_changed()

func set_status(value: DamageData.StatusEffect) -> void:
	CURRENT_ALTERED_STATE = value
	notify_changed()

func set_credits(value: int) -> void:
	CREDITS = max(0, value)
	notify_changed()

func notify_changed() -> void:
	emit_signal("stats_changed")

#-----------------------------------------------------------------------------#

# -----------------------
# Save / Load helpers (plana, compatible con GlobalPlayerStatsState)
# -----------------------

func get_save_data() -> Dictionary:
	var data := {}
	for p in get_property_list():
		if p.name.begins_with("_"):
			continue
		data[p.name] = get(p.name)
	return data

func parse_save_data(data: Dictionary) -> void:
	# data: Dictionary { prop_name: value, ... }
	for key in data.keys():
		# comprobamos que la propiedad exista antes de setear
		@warning_ignore("shadowed_variable")
		var props = get_property_list().map(func(x): return x.name)
		if key in props:
			set(key, data[key])
