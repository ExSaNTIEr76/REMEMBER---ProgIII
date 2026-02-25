@icon("res://addons/proyect_icons/floating_box_proyect_icon.png")

class_name FloatingBox    extends CharacterBody2D

enum BoxType { YELLOW, RED, GREEN, BLUE }

@export_enum( "yellow", "red", "green", "blue" ) var box_type : String = "yellow"
@export var magic_shadow : String = "white"
@export var is_lost : bool = false

@export var snap_to_grid : bool = false:
	set(_v):
		_snap_to_grid()

@onready var box_animations: AnimationPlayer = $BoxAnimations
@onready var box_utility: Area2D = $BoxUtility

# Guarda el último estado para no repetir la misma animación innecesariamente
var last_state := -1


func _ready():
	if Engine.is_editor_hint():
		return
	if not has_node( "BoxAnimations" ):
		push_error( "❌ Esta caja no tiene un BoxAnimations hijo." )
		return

	box_animations = $BoxAnimations

	if not Engine.is_editor_hint():
		update_animation_from_state()
		set_box_dialogue_start()



func _process(_delta: float) -> void:
	update_animation_from_state()


func _snap_to_grid() -> void:
	position.x = round( position.x / 16 ) * 16
	position.y = round( position.y / 16 ) * 16


# ✅ FUNCIONES DE ANIMACIÓN SEGÚN ESTADO GLOBAL
func update_animation_from_state() -> void:
	var current_state := GlobalConditions.floating_box_state

	if current_state == last_state:
		return

	last_state = current_state

	match current_state:
		0:
			_play_box_animation( "%s_box_idle" % box_type )
		1:
			_play_box_animation( "%s_box_open" % box_type )
		2:
			_play_box_animation( "%s_box_close" % box_type )
			await CinematicManager._wait( 0.4 )
			GlobalConditions.floating_box_state = 0
		_:
			push_warning( "⚠️ Estado de caja desconocido: %s" % str( current_state ))


func _play_box_animation( anim_name: String ) -> void:
	if box_animations == null:
		push_error( "❌ No se encontró el AnimationPlayer en esta caja." )
		return

	if box_animations.has_animation( anim_name ):
		box_animations.play( anim_name )
	else:
		push_warning( "⚠️ Animación no encontrada: " + anim_name )


func set_box_dialogue_start() -> void:
	if not box_utility or not box_utility.has_method( "set" ):
		push_warning( "⚠️ No se encontró el nodo BoxUtility o no es válido." )
		return

	match box_type:
		"yellow":
			box_utility.dialogue_start = "yellowBox"
		"red":
			box_utility.dialogue_start = "redBox"
		"green":
			box_utility.dialogue_start = "greenBox"
		"blue":
			box_utility.dialogue_start = "blueBox"
		_:
			push_warning( "❗ box_type desconocido: %s" % box_type )
