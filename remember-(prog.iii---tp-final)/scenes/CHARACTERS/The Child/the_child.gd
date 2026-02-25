@icon("res://addons/proyect_icons/the_child_proyect_icon.png")

class_name TheChild    extends CharacterBody2D

@onready var state_machine: StateMachine = $"STATE MACHINE"
@onready var animation_player: AnimationPlayer = %AnimationPlayer

@export var intro_animation: String = ""
@export var play_intro_on_ready: bool = false
@export var remove_after_cinematic_id: String = ""


func _ready():
	if remove_after_cinematic_id != "":
		if GlobalCinematicsState.has_cinematic(remove_after_cinematic_id):
			_disable_character()
			return

	if play_intro_on_ready and intro_animation != "" and animation_player.has_animation(intro_animation):
		animation_player.play(intro_animation)


func _enable_character():
	visible = true
	set_physics_process(true)
	set_process(true)
	
	# Desactivar colisión
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = false


func _disable_character():
	visible = false
	set_physics_process(false)
	set_process(false)
	
	# Desactivar colisión
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true
