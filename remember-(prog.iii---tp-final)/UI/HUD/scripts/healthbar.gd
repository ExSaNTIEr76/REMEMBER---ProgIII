class_name Healthbar    extends TextureProgressBar

@export var tweenTime: float = 0.1

signal critical_started
signal critical_ended

var is_critical := false
var heartbeat_tween: Tween = null

@export var preview_bar: TextureProgressBar
@export var preview_color := Color(0.3, 1.0, 0.3, 0.8)
var preview_tween: Tween


func setUp(maxValue: float) -> void:
	if max_value != maxValue:
		max_value = maxValue


func updateValue(_newValue: float) -> void:
	if _newValue < value:
		# 🔴 Flash rojo solo si bajó
		self_modulate = Color(1, 0.4, 0.4)
		create_tween().tween_property(self, "self_modulate", Color(1, 1, 1), 0.25)

	var hp_ratio := _newValue / max_value

	# ⚠️ Activar modo crítico con latidos
	if hp_ratio <= 0.2:
		if not is_critical:
			_start_heartbeat()
			is_critical = true
			critical_started.emit()
	else:
		if is_critical:
			_stop_heartbeat()
			is_critical = false
			self_modulate = Color.WHITE
			critical_ended.emit()


	# 🟢 Suaviza el valor siempre
	create_tween().set_trans(Tween.TRANS_QUAD)\
		.tween_property(self, "value", _newValue, tweenTime)


func _start_heartbeat():
	if heartbeat_tween:
		heartbeat_tween.kill()
	heartbeat_tween = create_tween()
	heartbeat_tween.set_loops()  # 🔁 infinito

	# ❤️ Ciclo de latido: rojo tenue -> normal -> rojo tenue...
	heartbeat_tween.tween_property(self, "self_modulate", Color(1, 0.6, 0.6), 0.3).set_trans(Tween.TRANS_SINE)
	heartbeat_tween.tween_property(self, "self_modulate", Color(1, 1, 1), 0.3).set_trans(Tween.TRANS_SINE)


func _stop_heartbeat():
	if heartbeat_tween:
		heartbeat_tween.kill()
		heartbeat_tween = null


func show_preview(target_value: float) -> void:
	if not preview_bar:
		return

	preview_bar.visible = true
	preview_bar.max_value = max_value
	preview_bar.value = clamp(target_value, value, max_value)

	# 🫀 Pulso suave
	if preview_tween:
		preview_tween.kill()

	preview_bar.self_modulate = Color(0.4, 1.0, 0.4, 0.7)
	preview_tween = create_tween()
	preview_tween.set_loops()
	preview_tween.set_trans(Tween.TRANS_SINE)
	preview_tween.set_ease(Tween.EASE_IN_OUT)

	preview_tween.tween_property(
		preview_bar,
		"self_modulate:a",
		0.35,
		0.6
	)
	preview_tween.tween_property(
		preview_bar,
		"self_modulate:a",
		0.7,
		0.6
	)


func clear_preview() -> void:
	if preview_tween:
		preview_tween.kill()
		preview_tween = null

	if preview_bar:
		preview_bar.visible = false
