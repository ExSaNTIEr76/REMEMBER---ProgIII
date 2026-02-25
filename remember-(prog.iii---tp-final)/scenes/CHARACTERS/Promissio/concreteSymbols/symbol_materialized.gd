@icon( "res://addons/proyect_icons/symbo_materializedl_proyect_icon.png" )

@tool    class_name SymbolMaterialized    extends CharacterBody2D

@onready var symbol_background: AnimatedSprite2D = %SymbolBackground
@onready var symbol_blur: AnimatedSprite2D = %SymbolBlur
@onready var symbol: AnimatedSprite2D = %Symbol

@onready var background_rotation: AnimationPlayer = %BackgroundRotation
@onready var symbol_animations: AnimationPlayer = %SymbolAnimations
@onready var symbol_sound: AudioStreamPlayer2D = %SymbolSound

@export var symbol_name: String:
	set(value):
		symbol_name = value
		_update_symbol()


func _ready() -> void:
	# Asegura que también funcione al cargar la escena
	_update_symbol()


func _update_symbol() -> void:
	if symbol_name.is_empty():
		return

	if not is_instance_valid(symbol):
		return  # evita errores en editor antes de que cargue todo

	# -------------------------
	# 1. Detectar prefijo
	# -------------------------
	var prefix := ""
	if symbol_name.contains("_"):
		prefix = symbol_name.split("_")[0] + "_"
	else:
		push_warning("symbol_name no tiene prefijo válido: " + symbol_name)
		return

	var background_anim := prefix + "background"

	# -------------------------
	# 2. Aplicar animaciones
	# -------------------------
	_play_if_exists(symbol, symbol_name)
	_play_if_exists(symbol_blur, symbol_name)
	_play_if_exists(symbol_background, background_anim)

	# -------------------------
	# 3. Opcional: efectos
	# -------------------------
	if background_rotation:
		background_rotation.play("background_idle")

	if symbol_animations:
		symbol_animations.play("symbol_spawn")


func _play_if_exists(sprite: AnimatedSprite2D, anim_name: String) -> void:
	if not sprite or not sprite.sprite_frames:
		return

	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	else:
		push_warning(
			"%s no tiene la animación '%s'" % [sprite.name, anim_name]
		)
