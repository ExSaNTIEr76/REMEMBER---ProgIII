class_name EquipableItemModifier extends Resource

enum Type { HEALTH, ENERGY, COMPETENCE, ATTACK, DEFENSE, STRENGTH, CONSTITUTION, ESPRIT, LUCK, SPEED }
@export var type : Type = Type.HEALTH
@export var value : int = 1
