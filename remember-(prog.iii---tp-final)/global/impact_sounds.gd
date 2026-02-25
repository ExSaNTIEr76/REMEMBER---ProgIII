extends Node

# 🎵 Diccionario maestro de sonidos por tipo y reacción
@export var impact_sounds := {
	# === Atributos ===
	"slash": {
		"normal": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Slash_Normal.ogg"),
		"weak": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Meat_Normal.ogg"),
		"resistant": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Slash_Resistant.ogg"),
		"immune": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Slash_Resistant.ogg"),
	},
	"strike": {
		"normal": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
		"weak": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
		"resistant": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
		"immune": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
	},
	"sol": {
		"normal": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
		"weak": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
		"resistant": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
		"immune": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
	},
	"luna": {
		"normal": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
		"weak": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
		"resistant": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
		"immune": preload("res://audio/SFX/Promissio SFX/impact/Sfx_Strike_Normal.ogg"),
	},

	# === Elementos ===
	#"smoke": {
		#"normal": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Smoke_Hit.ogg"),
		#"weak": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Smoke_Weak.ogg"),
		#"resistant": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Smoke_Resist.ogg"),
		#"immune": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Smoke_Immune.ogg"),
	#},
	#"metal": {
		#"normal": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Hit.ogg"),
		#"weak": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Weak.ogg"),
		#"resistant": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Resist.ogg"),
		#"immune": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Immune.ogg"),
	#},
	#"plastic": {
		#"normal": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Hit.ogg"),
		#"weak": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Weak.ogg"),
		#"resistant": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Resist.ogg"),
		#"immune": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Immune.ogg"),
	#},
	#"meat": {
		#"normal": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Flesh_Hit.ogg"),
		#"weak": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Flesh_Weak.ogg"),
		#"resistant": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Flesh_Resist.ogg"),
		#"immune": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Flesh_Immune.ogg"),
	#},
	#"sugar": {
		#"normal": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Hit.ogg"),
		#"weak": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Weak.ogg"),
		#"resistant": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Resist.ogg"),
		#"immune": preload("res://audio/SFX/Promissio SFX/elements/Sfx_Metal_Immune.ogg"),
	#},
#
	## === Estados alterados ===
	#"poison": {
		#"normal": preload("res://audio/SFX/Promissio SFX/status/Sfx_Poison.ogg"),
		#"weak": preload("res://audio/SFX/Promissio SFX/status/Sfx_Poison_Weak.ogg"),
		#"resistant": preload("res://audio/SFX/Promissio SFX/status/Sfx_Poison_Resist.ogg"),
		#"immune": preload("res://audio/SFX/Promissio SFX/status/Sfx_Poison_Immune.ogg"),
	#},
	#"paralysis": {
		#"normal": preload("res://audio/SFX/Promissio SFX/status/Sfx_Shock.ogg"),
		#"weak": preload("res://audio/SFX/Promissio SFX/status/Sfx_Shock_Weak.ogg"),
		#"resistant": preload("res://audio/SFX/Promissio SFX/status/Sfx_Shock_Resist.ogg"),
		#"immune": preload("res://audio/SFX/Promissio SFX/status/Sfx_Shock_Immune.ogg"),
	#},
}

# 🔊 Volumen y pitch base
@export_range(-80, 0) var volume_db := -15.0
@export_range(0.5, 2.0) var pitch := 1.0
@export var pitch_variation := 0.05  # Pequeña variación aleatoria


# === Funciones principales ===
func play_impact(attack_type: String, defense_type: String = "normal") -> void:
	var sounds_by_defense = impact_sounds.get(attack_type)
	if sounds_by_defense == null:
		push_warning("[ImpactSounds] Tipo no encontrado: %s" % attack_type)
		return
	var sound: AudioStream = sounds_by_defense.get(defense_type)
	if sound == null:
		push_warning("[ImpactSounds] Defensa no encontrada: %s/%s" % [attack_type, defense_type])
		return

	var final_pitch := pitch + randf_range(-pitch_variation, pitch_variation)
	print("[ImpactSounds] Play %s/%s (pitch %.2f)" % [attack_type, defense_type, final_pitch])
	AudioManager.play_sfx(sound, final_pitch, volume_db)


func play_from_attack(attack_data: DamageData, target_stats) -> void:
	var attack_type := _map_attack_to_type(attack_data)
	var defense_type := "normal"

	# --- ENEMIGOS ---
	if target_stats is EnemyGlobalStats:
		if target_stats.CURRENT_SHIELD > 0:
			defense_type = "immune"
		else:
			defense_type = _affinity_to_string(
				target_stats.get_affinity_for_attack(attack_data)
			)

		match target_stats.type:
			EnemyGlobalStats.EnemyType.SPECTRE:
				if defense_type == "resistant":
					defense_type = "normal"
			EnemyGlobalStats.EnemyType.SNOOPER:
				defense_type = "normal"

	# --- PLAYER (usa Dictionary) ---
	elif typeof(target_stats) == TYPE_DICTIONARY:
		var def_value := int(target_stats.get("DEF", 0))
		if def_value >= 999:
			defense_type = "resistant"

	play_impact(attack_type, defense_type)



func _affinity_to_string(affinity: AffinityEntry.Affinity) -> String:
	match affinity:
		AffinityEntry.Affinity.WEAK: return "weak"
		AffinityEntry.Affinity.RESISTANT: return "resistant"
		AffinityEntry.Affinity.IMMUNE: return "immune"
		_: return "normal"


# === Mappers ===
func _map_attack_to_type(attack_data: DamageData) -> String:
	# prioridad: atributo > elemento > estado
	if attack_data.attribute != DamageData.AttributeType.NONE:
		return _map_attribute_to_type(attack_data.attribute)
	elif attack_data.element != DamageData.ElementType.NONE:
		return _map_element_to_type(attack_data.element)
	elif attack_data.status_effect != DamageData.StatusEffect.NONE:
		return _map_status_to_type(attack_data.status_effect)
	else:
		return "strike"  # default fallback


func _map_attribute_to_type(attr: DamageData.AttributeType) -> String:
	match attr:
		DamageData.AttributeType.SLASH: return "slash"
		DamageData.AttributeType.STRIKE: return "strike"
		DamageData.AttributeType.SOL, DamageData.AttributeType.LUNA: return "magic"
		_: return "strike"


func _map_element_to_type(elem: DamageData.ElementType) -> String:
	match elem:
		DamageData.ElementType.SMOKE: return "smoke"
		DamageData.ElementType.METAL: return "metal"
		DamageData.ElementType.PLASTIC: return "plastic"
		DamageData.ElementType.MEAT: return "meat"
		DamageData.ElementType.SUGAR: return "sugar"
		_: return "strike"


func _map_status_to_type(status: DamageData.StatusEffect) -> String:
	match status:
		DamageData.StatusEffect.POISON: return "poison"
		DamageData.StatusEffect.PARALYSIS: return "paralysis"
		_: return "sol"  # default: usa sonidos mágicos
