@icon("res://addons/proyect_icons/elsen_proyect_icon.png")

class_name Elsen    extends CharacterBody2D

@export var elsen_type: String = "normal"
@export var is_static: bool = false
@export var start_facing_direction: String = "Down"

@onready var state_machine: StateMachine = $"STATE MACHINE"
@onready var elsen_sprite: Sprite2D = $ElsenSprite
@onready var area_detector: RayCast2D = $AreaDetector
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var states: ElsenStateNames = ElsenStateNames.new()
var animations: ElsenAnimations = ElsenAnimations.new()

var current_direction: Vector2 = Vector2.ZERO
var last_direction_name: String = "Down"

func _ready():
	_update_spritesheet_by_type()
	last_direction_name = start_facing_direction
	play_animation( animations.idle + last_direction_name )

func _update_spritesheet_by_type():
	var path := "res://scenes/CHARACTERS/Elsens/sprites/"
	var tex := load(path + "Elsen_" + elsen_type + "_spritesheet.png")
	
	if tex:
		elsen_sprite.texture = tex

		# 💡 Desplazamiento especial si es un Elsen con paraguas
		if elsen_type.begins_with("umbrella"):
			elsen_sprite.offset.y = -31
		else:
			elsen_sprite.offset.y = -23  # Reset por si no es de paraguas
	else:
		push_error("❌ Spritesheet no encontrada para elsen_type: " + elsen_type)


func play_animation( anim_name: String ):
	if has_node( "AnimationPlayer" ):
		$AnimationPlayer.play( anim_name )

func is_area_blocked() -> bool:
	return area_detector.is_colliding()
