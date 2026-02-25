@icon( "res://addons/proyect_icons/door_proyect_icon.png" )
@tool

class_name LevelTransitionInteract    extends LevelTransition

signal interaction_started

@export var auto_trigger: bool = false
@export var one_time: bool = false

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = ""

var triggered := false


func _ready() -> void:
	_update_area()
	if Engine.is_editor_hint():
		return

	super()

	monitoring = false
	_place_player()

	await LevelManager.level_loaded
	await get_tree().physics_frame
	await get_tree().physics_frame

	monitoring = true

	# ✅ Solo conectamos si aún no está conectado
	if not body_entered.is_connected( Callable( self, "_on_body_entered" ) ):
		body_entered.connect( Callable(self, "_on_body_entered" ) )


func _on_body_entered( body: Node ) -> void:
	if triggered and one_time:
		return
	if body.is_in_group( "players" ):
		_run_interaction()


func get_offset() -> Vector2:
	var offset: Vector2 = Vector2.ZERO
	var player_pos := PlayerManager.player.global_position

	if side == SIDE.LEFT or side == SIDE.RIGHT:
		if center_player:
			offset.y = 0
		else:
			offset.y = player_pos.y - global_position.y
		offset.x = 16
		if side == SIDE.LEFT:
			offset.x *= -1
	else:
		if center_player:
			offset.x = 0
		else:
			offset.x = player_pos.x - global_position.x
		offset.y = 16
		if side == SIDE.TOP:
			offset.y *= -1

	return offset


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed( "ui_interact" ) and _player_in_area():
		_run_interaction()


func _run_interaction() -> void:
	if triggered and one_time:
		return

	interaction_started.emit()

	if dialogue_resource:
		DialogueManager.show_dialogue_balloon(dialogue_resource, dialogue_start)
		await DialogueManager.dialogue_ended

	triggered = true

	# 🧠 Seteamos la zona de cámara para el siguiente nivel
	if initial_camera_zone != -1:
		GameManager.camera_zones_by_scene["__override__"] = initial_camera_zone

	# 🧠 Primero seteamos el target_transition correctamente
	LevelManager.target_transition = target_transition_area
	LevelManager.position_offset = get_offset()

	# 💡 Luego recién cargamos el nivel (esto ejecutará el _ready del nuevo LevelTransition)
	await get_tree().process_frame

	LevelManager.load_new_level(level, target_transition_area, LevelManager.position_offset)
	set_monitoring(false)

	AudioManager.play_sfx(SFX_IN, pitch, volume_db)


func _player_in_area() -> bool:
	var bodies = get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group( "players" ):
			return true
	return false


func action():
	_run_interaction()


func _update_area() -> void:
	super()
	collision_shape.shape.size = Vector2( 32, 32 )
