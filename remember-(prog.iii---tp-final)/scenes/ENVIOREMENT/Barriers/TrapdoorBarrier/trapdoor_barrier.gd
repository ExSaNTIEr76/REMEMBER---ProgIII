class_name TrapdoorBarrier    extends StaticBody2D

@onready var trapdoor_barrier_animations: AnimatedSprite2D = $BarrierAnimatedSprite
@onready var trapdoor_barrier_collision: CollisionShape2D = $BarrierCollision


func puzzle_trapdoor_barrier_on() -> void:
	trapdoor_barrier_collision.disabled = false
	trapdoor_barrier_animations.play("blue_s_barrier_on")
	await trapdoor_barrier_animations.animation_finished
	trapdoor_barrier_animations.play("blue_s_barrier_idle")


func puzzle_trapdoor_barrier_off() -> void:
	trapdoor_barrier_animations.play("blue_s_barrier_off")
	await trapdoor_barrier_animations.animation_finished
	trapdoor_barrier_collision.disabled = true


func no_trapdoor_barriers() -> void:
	trapdoor_barrier_animations.play("no_barriers")
	trapdoor_barrier_collision.disabled = true
