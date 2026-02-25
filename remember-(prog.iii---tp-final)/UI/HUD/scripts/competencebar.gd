class_name Competencebar    extends TextureProgressBar

@export var tweenTime : float = 0.1

@export var preview_bar: TextureProgressBar
@export var preview_color := Color(0.3, 1.0, 0.3, 0.8)
var preview_tween: Tween


func setUp(maxValue: float) -> void:
	if max_value != maxValue:
		max_value = maxValue


func updateValue(_newValue : float) -> void:
	create_tween().set_trans(Tween.TRANS_QUAD)\
	.tween_property(self, "value", _newValue, tweenTime)
	
	if PlayerManager.player and has_node("StatsUpdater"):
		$StatsUpdater.setup(PlayerManager.player.stats)


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
		1.0,
		0.6
	)
	preview_tween.tween_property(
		preview_bar,
		"self_modulate:a",
		0.30,
		0.6
	)


func clear_preview() -> void:
	if preview_tween:
		preview_tween.kill()
		preview_tween = null

	if preview_bar:
		preview_bar.visible = false
