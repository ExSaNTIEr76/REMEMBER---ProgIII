class_name Animal    extends CharacterBody2D

@export var is_static: bool = false
@export var start_facing_direction: String = "Down"

@onready var state_machine: StateMachine = $"STATE MACHINE"
@onready var area_detector: RayCast2D = $AreaDetector
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var states: AnimalStateNames = AnimalStateNames.new()
var animations: AnimalAnimations = AnimalAnimations.new()

var current_direction: Vector2 = Vector2.ZERO
var last_direction_name: String = "Down"


func _ready():
	last_direction_name = start_facing_direction
	play_animation( animations.idle + last_direction_name )


func play_animation( anim_name: String ):
	if has_node( "AnimationPlayer" ):
		$AnimationPlayer.play( anim_name )


func is_area_blocked() -> bool:
	return area_detector.is_colliding()
