class_name AnnexMines2    extends Node2D

@onready var addon: AnimatedSprite2D = %Addon

func _ready() -> void:
	if GlobalConditions.first_symbol_count == 0:
		addon.play("awakening")
	else:
		addon.play("nothing")

func addon_idle() -> void:
	addon.play("idle")

func addon_linked() -> void:
	PlayerManager.learn_combat()
	addon.play("nothing")
