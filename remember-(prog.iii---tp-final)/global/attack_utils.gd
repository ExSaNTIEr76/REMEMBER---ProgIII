# attack_utils.gd

static func orient_attack(anchor: Node2D, direction: String, hitbox: Node2D, knife: Node2D) -> void:
	var angle = {
		"Right": 0.0,
		"Left": 0.0,  # No rotamos, sólo espejamos visualmente
		"Up": -PI / 2,
		"Down": PI / 2
	}.get(direction, 0.0)

	anchor.rotation = angle
	hitbox.rotation = angle
	knife.rotation = angle

	# Aplicar flip para la izquierda
	if direction == "Left":
		knife.scale.x = -1
		hitbox.scale.x = -1
	else:
		knife.scale.x = 1
		hitbox.scale.x = 1
