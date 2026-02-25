#ghostrail_common_spectre.gd:

extends Node2D

@export var fade_time := 0.5
var sprite: Sprite2D

func _ready():
	sprite = $Sprite2D

	var flicker = create_tween()
	flicker.set_loops()
	flicker.set_trans(Tween.TRANS_SINE)
	flicker.set_ease(Tween.EASE_IN_OUT)
	flicker.tween_property(sprite, "modulate:a", 0.1, 0.12)
	flicker.tween_property(sprite, "modulate:a", 0.4, 0.12)

	var vanish = create_tween()
	vanish.tween_interval(fade_time)
	vanish.tween_property(sprite, "modulate:a", 0.0, 0.2)
	vanish.tween_callback(queue_free)
