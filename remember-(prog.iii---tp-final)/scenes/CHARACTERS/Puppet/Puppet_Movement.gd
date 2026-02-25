extends Node2D

class_name PuppetMovement

@onready var puppet: Puppet = get_parent() # Referencia al script global Puppet
@onready var sprite = get_parent().get_node("Ciro")
@onready var animation_tree = get_parent().get_node("PuppetAnimationTree") # Nodo AnimationTree
@onready var animation_state = animation_tree.get("parameters/playback") # Acceso al state_machine
@onready var actionable_finder = get_parent().get_node("Direction/ActionableFinder")

@onready var previous_direction: String = "Down"

func _unhandled_input(_event: InputEvent) -> void:
	if not puppet.input_enabled:
		return

	# Movimiento
	puppet.move_direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	puppet.is_running = Input.is_action_pressed("ui_run")
	puppet.current_speed = puppet.speed * (puppet.run_speed_multiplier if puppet.is_running else 1)
	puppet.velocity = puppet.move_direction * puppet.current_speed

	# Acción interactiva
	if Input.is_action_just_pressed("ui_interact"):
		var actionables = actionable_finder.get_overlapping_areas()
		if actionables.size() > 0:
			actionables[0].action()

func _physics_process(_delta: float) -> void:
	if not puppet.input_enabled:
		return

	# Movimiento
	puppet.move_and_slide()

	# Actualización de la animación
	update_animation()

func update_animation():
	var direction = "Down"

	# Determinar la dirección del movimiento
	if puppet.velocity.x < 0:
		direction = "Left"
	elif puppet.velocity.x > 0:
		direction = "Right"
	elif puppet.velocity.y < 0:
		direction = "Up"
	elif puppet.velocity.y > 0:
		direction = "Down"

	# Reproducir animaciones según el estado
	if puppet.velocity.length() == 0:
		animation_state.travel("Idle" + previous_direction)
	else:
		var animation_name = "Walk" if not puppet.is_running else "Run"
		animation_state.travel(animation_name + direction)
		previous_direction = direction
