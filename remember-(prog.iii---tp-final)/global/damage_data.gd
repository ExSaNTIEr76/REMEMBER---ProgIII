class_name DamageData    extends Resource

enum AttributeType { NONE, SLASH, STRIKE, SOL, LUNA }
enum ElementType { NONE, SMOKE, METAL, PLASTIC, MEAT, SUGAR }
enum StatusEffect { NONE, PURE, POISON, PARALYSIS, BLINDNESS, MIGRAINE, FRAILTY, INVINCIBLE, VIGOR }

@export var attribute: AttributeType = AttributeType.NONE
@export var element: ElementType = ElementType.NONE
@export var status_effect: StatusEffect = StatusEffect.PURE

var source: Node = null
@export var base_damage: int = 0
@export var status_strength: int = 0

static func get_colored_status_name(effect: StatusEffect) -> String:
	match effect:
		StatusEffect.PURE: return "[color=white]PURE[/color]"
		StatusEffect.POISON: return "[color=lawn_green]POISON[/color]"
		StatusEffect.PARALYSIS: return "[color=orange]PARALYSIS[/color]"
		StatusEffect.BLINDNESS: return "[color=purple]BLINDNESS[/color]"
		StatusEffect.MIGRAINE: return "[color=magenta]MIGRAINE[/color]"
		StatusEffect.FRAILTY: return "[color=dark_gray]FRAILTY[/color]"
		StatusEffect.INVINCIBLE: return "[color=aqua]INVINCIBLE[/color]"
		StatusEffect.VIGOR: return "[color=green]VIGOR[/color]"
		_: return "[color=white]NONE[/color]"
