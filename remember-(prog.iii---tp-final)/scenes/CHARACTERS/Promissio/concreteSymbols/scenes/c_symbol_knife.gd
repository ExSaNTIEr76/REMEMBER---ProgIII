@icon("res://addons/proyect_icons/concrete_symbol_proyect_icon.png")
#c_symbol_knife.gd

class_name cSymbolKnife extends Symbol

func _ready():
	if spawn_sound:
		spawn_sound.pitch_scale = spawn_pitch_base
