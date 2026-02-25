# direction_helper.gd (autoload)

extends Node

## Devuelve un string con la dirección según un vector
func get_direction_name(input_vector: Vector2) -> String:
	if input_vector == Vector2.ZERO:
		return "Idle"

	var angle := input_vector.angle()
	var deg := rad_to_deg(angle)

	var dir := ""

	if deg >= -22.5 and deg < 22.5:
		dir = "Right"
	elif deg >= 22.5 and deg < 67.5:
		dir = "DownRight"
	elif deg >= 67.5 and deg < 112.5:
		dir = "Down"
	elif deg >= 112.5 and deg < 157.5:
		dir = "DownLeft"
	elif deg >= 157.5 or deg < -157.5:
		dir = "Left"
	elif deg >= -157.5 and deg < -112.5:
		dir = "UpLeft"
	elif deg >= -112.5 and deg < -67.5:
		dir = "Up"
	elif deg >= -67.5 and deg < -22.5:
		dir = "UpRight"

	return dir
