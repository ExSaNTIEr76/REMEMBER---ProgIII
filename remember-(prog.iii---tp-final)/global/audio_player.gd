extends Node

func box_open() -> void:
	AudioManager.play_sfx_path("res://audio/SFX/GUI SFX/menu/Sfx_Box_Open.ogg", 0.5, -10.0)

func box_close() -> void:
	AudioManager.play_sfx_path("res://audio/SFX/GUI SFX/menu/Sfx_Box_Close.ogg", 0.5, -7.0)

func go_to_nothingness() -> void:
	AudioManager.play_sfx_path("res://audio/SFX/Enviorement/transitions/sfx_Go_To_The_Nothingness.ogg", 1.0, -12.0)
