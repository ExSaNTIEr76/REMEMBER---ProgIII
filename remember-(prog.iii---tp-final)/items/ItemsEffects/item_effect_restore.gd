class_name ItemEffectHeal    extends ItemEffect

@export var heal_amount : int = 1
@export var target_stat : String = "HP" # Puede ser "HP", "CP" o "EP"

@export var audio : AudioStream
@export var audio_volume: float = -5.0
@export var audio_pitch : float = 1.0

func can_use() -> bool:
	var s := PlayerManager.get_stats_snapshot()

	match target_stat:
		"HP":
			return s["CURRENT_HP"] < s["MAX_HP"]
		"CP":
			return s["CURRENT_CP"] < s["MAX_CP"]
		"EP":
			return s["CURRENT_EP"] < s["MAX_EP"]

	return false


func use() -> void:
	if not can_use():
		AudioManager.play_sfx_path("res://audio/SFX/GUI SFX/menu/Sfx_Blocked.ogg", 1.0, 0.0)
		return

	PlayerManager.modify_stat(target_stat, heal_amount)
	AudioManager.play_sfx(audio, audio_pitch, audio_volume)
