@icon( "res://addons/proyect_icons/simple_barrier_proyect_icon.png" )

class_name Barrier    extends StaticBody2D

@onready var barrier_animations: AnimatedSprite2D = $BarrierAnimatedSprite
@onready var barrier_collision: CollisionShape2D = $BarrierCollision


func puzzle_barrier_on() -> void:
	barrier_collision.disabled = false
	barrier_animations.play("blue_s_barrier_on")
	await barrier_animations.animation_finished
	barrier_animations.play("blue_s_barrier_idle")

func puzzle_barrier_off() -> void:
	barrier_animations.play("blue_s_barrier_off")
	await barrier_animations.animation_finished
	barrier_collision.disabled = true



func combat_barrier_on() -> void:
	barrier_collision.set_deferred("disabled", false)
	barrier_animations.play("red_s_barrier_on")
	await barrier_animations.animation_finished
	barrier_animations.play("red_s_barrier_idle")

func combat_barrier_off() -> void:
	barrier_animations.play("red_s_barrier_off")
	await barrier_animations.animation_finished
	barrier_collision.set_deferred("disabled", true)



func no_barriers() -> void:
	barrier_animations.play("no_barriers")
	barrier_collision.set_deferred("disabled", true)
