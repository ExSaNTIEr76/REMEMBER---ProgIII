# damage_numbers.gd:

extends Node

var custom_font := preload("res://UI/Fonts/Remember.ttf")

func display_number(value: int, position: Vector2, is_player: bool = false, is_critical: bool = false):
	var number = Label.new()
	number.global_position = position
	number.text = str(value)
	number.z_index = 5

	var settings = LabelSettings.new()
	settings.font = custom_font
	settings.font_size = 5

	#COLOR
	var color = "#F90"
	
	if is_player:
		color = "#F20"
	if is_critical:
		color = "#FFF"
	if value == 0:
		color = "#FFF8"

	# OUTLINE
	settings.font_color = color
	settings.font_size = 11
	settings.outline_color = "#000"
	settings.outline_size = 4

	number.label_settings = settings

	# SOMBRA
	settings.shadow_color = Color(0, 0, 0, 0.8)
	settings.shadow_offset = Vector2(2, 2)
	settings.shadow_size = 3

	call_deferred("add_child", number)

	await number.resized
	number.pivot_offset = Vector2(number.size / 2)

	# ANIMACIÓN:
	number.scale = Vector2(0.7, 0.7)

	var tween = get_tree().create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	# Aparición con rebote suave
	tween.tween_property(number, "scale", Vector2(1.1, 1.1), 0.1)
	tween.tween_property(number, "scale", Vector2(1, 1), 0.05)

	# Movimiento hacia arriba con flotación
	tween.parallel().tween_property(number, "position:y", number.position.y - 28, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Escalado hacia desaparición
	tween.tween_interval(0.2)
	tween.parallel().tween_property(number, "scale", Vector2(0.0, 0.0), 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(number, "modulate:a", 0.0, 0.25) # Desvanecimiento

	await tween.finished
	number.queue_free()
