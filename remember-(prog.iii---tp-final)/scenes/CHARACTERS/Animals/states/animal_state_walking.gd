class_name AnimalStateWalking    extends AnimalStateBase

var directions := [
	Vector2.LEFT,
	Vector2.RIGHT,
	Vector2.UP,
	Vector2.DOWN
]

var move_duration := 1.7     # Cuánto tiempo camina por paso
var wait_duration := 2.0     # Cuánto espera entre pasos

var state_timer := 0.0
var is_moving := false
var move_speed := 15.0


func start():
	state_timer = 0.0
	is_moving = false
	_pick_valid_direction()
	animal.velocity = Vector2.ZERO
	animal.play_animation( animations.idle + animal.last_direction_name )


func on_physics_process( delta ):
	if animal.is_static:
		state_machine.change_to( states.Idle )
		return

	state_timer += delta

	if is_moving:
		animal.velocity = animal.current_direction * move_speed
		animal.move_and_slide()

		if state_timer >= move_duration:
			state_timer = 0.0
			is_moving = false
			animal.velocity = Vector2.ZERO
			animal.play_animation( animations.idle + animal.last_direction_name )
	else:
		if state_timer >= wait_duration:
			state_timer = 0.0
			_pick_valid_direction()
			is_moving = true
			animal.play_animation( animations.walk + animal.last_direction_name )


func _pick_valid_direction():
	var attempt_count := 0
	while attempt_count < 10:
		var new_dir = directions[ randi() % directions.size() ]
		var _name := DirectionHelper.get_direction_name( new_dir )

		animal.current_direction = new_dir
		animal.last_direction_name = _name

		# Reposicionar el AreaDetector en la nueva dirección
		if animal.area_detector:
			animal.area_detector.target_position = new_dir.normalized() * 16
			animal.area_detector.force_raycast_update()

			if not animal.is_area_blocked():
				break

		attempt_count += 1
