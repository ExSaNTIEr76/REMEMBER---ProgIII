@icon("res://addons/proyect_icons/hitbox_proyect_icon.png")

class_name Hitbox    extends Area2D

var attack_data: DamageData = null

func _ready() -> void:
	monitoring = true
	connect("area_entered", Callable(self, "_on_area_entered"))

func _on_area_entered(area: Area2D) -> void:
	if area is not Hurtbox:
		return

	var target = area.get_parent()
	if not target:
		return


	# 1. CREAR attack_data SIEMPRE

	var source_damage := 0

	if owner and owner.has_method("get_damage_amount"):
		source_damage = owner.get_damage_amount()

		if owner.has_method("_create_damage_data"):
			attack_data = owner._create_damage_data()
		else:
			attack_data = DamageData.new()
			attack_data.base_damage = source_damage

	elif owner and owner.has_method("stats"):
		source_damage = owner.stats.min_atk
		attack_data = DamageData.new()
		attack_data.base_damage = source_damage
		attack_data.attribute = DamageData.AttributeType.STRIKE

	attack_data.source = owner


	# 2️. INVULNERABILIDAD

	if target.invulnerable:
		return


	# 3️. BLOQUEO

	if target.has_method("is_guarding") and target.is_guarding():
		if target.shield_area.try_block(attack_data):
			return # 🛡️ bloqueado


	# 4️. DAÑO REAL

	if target.has_method("take_damage"):
		target.take_damage(source_damage, attack_data)

	if target.has_method("on_hit"):
		target.on_hit()



func _create_attack_data() -> DamageData:
	var data := DamageData.new()

	if owner and owner.has_method("get_damage_amount"):
		data.base_damage = owner.get_damage_amount()
	else:
		data.base_damage = 1

	data.attribute = DamageData.AttributeType.STRIKE
	return data
