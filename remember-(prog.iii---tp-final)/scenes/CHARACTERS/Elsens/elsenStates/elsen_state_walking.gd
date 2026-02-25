@icon("res://addons/proyect_icons/elsen_state_proyect_icon.png")

class_name ElsenStateWalking    extends ElsenStateBase

var directions := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN
]

var move_duration := 1.8     # Cuánto tiempo camina por paso
var wait_duration := 2.0     # Cuánto espera entre pasos

var state_timer := 0.0
var is_moving := false
var move_speed := 15.0

func start():
	state_timer = 0.0
	is_moving = false
	_pick_valid_direction()
	elsen.velocity = Vector2.ZERO
	elsen.play_animation( animations.idle + elsen.last_direction_name )

func on_physics_process( delta ):
	if elsen.is_static:
		state_machine.change_to( states.Idle )
		return

	state_timer += delta

	if is_moving:
		elsen.velocity = elsen.current_direction * move_speed
		elsen.move_and_slide()

		if state_timer >= move_duration:
			state_timer = 0.0
			is_moving = false
			elsen.velocity = Vector2.ZERO
			elsen.play_animation( animations.idle + elsen.last_direction_name )
	else:
		if state_timer >= wait_duration:
			state_timer = 0.0
			_pick_valid_direction()
			is_moving = true
			elsen.play_animation( animations.walk + elsen.last_direction_name )

func _pick_valid_direction():
	var attempt_count := 0
	while attempt_count < 10:
		var new_dir = directions[ randi() % directions.size() ]
		var _name := DirectionHelper.get_direction_name( new_dir )

		elsen.current_direction = new_dir
		elsen.last_direction_name = _name

		# Reposicionar el AreaDetector en la nueva dirección
		if elsen.area_detector:
			elsen.area_detector.target_position = new_dir.normalized() * 16
			elsen.area_detector.force_raycast_update()

			if not elsen.is_area_blocked():
				break

		attempt_count += 1
