# affinity_entry.gd

class_name AffinityEntry    extends Resource

enum Affinity { NONE, WEAK, RESISTANT, IMMUNE }

enum TargetType { ATTRIBUTE, ELEMENT, STATUS }

@export var target_type: TargetType = TargetType.ATTRIBUTE

@export var attribute: DamageData.AttributeType = DamageData.AttributeType.NONE
@export var element: DamageData.ElementType = DamageData.ElementType.NONE
@export var status: DamageData.StatusEffect = DamageData.StatusEffect.NONE

@export var affinity: Affinity = Affinity.NONE


func matches_attack(attack_data: DamageData) -> bool:
	match target_type:
		TargetType.ATTRIBUTE:
			return attack_data.attribute == attribute
		TargetType.ELEMENT:
			return attack_data.element == element
		TargetType.STATUS:
			return attack_data.status_effect == status
		_:
			return false
