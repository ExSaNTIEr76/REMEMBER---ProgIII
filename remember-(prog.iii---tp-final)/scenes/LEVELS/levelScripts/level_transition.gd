@icon( "res://addons/proyect_icons/entrance_proyect_icon.png" )
@tool

class_name LevelTransition extends Area2D

signal entered_from_here

enum SIDE { LEFT, RIGHT, TOP, BOTTOM }

@export_file( "*.tscn" ) var level
@export var target_transition_area : String = "LevelTransition"
@export var center_player : bool = false

@export_category( "Sounds Settings" )

@export var SFX_IN: AudioStream
@export var SFX_OUT: AudioStream

@export_range(-80, 0) var volume_db := -15.0
@export_range(0.5, 2.0) var pitch := 1.5

@export_category( "Collision Area Settings" )

@export_range( 1, 12, 1, "or_greater") var size : int = 2 :
	set( _v ):
		size = _v
		_update_area()

@export var side: SIDE = SIDE.LEFT :
	set( _v ):
		side = _v
		_update_area()

@export var snap_to_grid : bool = false :
	set ( _v ):
		_snap_to_grid()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

@export_category( "Initial Cam Area Zone" )

@export var initial_camera_zone : int = 0


func _ready() -> void:
	_update_area()
	if Engine.is_editor_hint():
		return

	monitoring = false
	await LevelManager.level_loaded
	await _wait_for_player_ready()

	monitoring = true
	body_entered.connect(_player_entered)
	_place_player()


func _player_entered(_p: Node2D) -> void:
	if ThothGameState.loading_from_save:
		return

	if initial_camera_zone != -1:
		GameManager.camera_zones_by_scene["__override__"] = initial_camera_zone

	LevelManager.load_new_level(level, target_transition_area, get_offset())
	AudioManager.play_sfx(SFX_IN, pitch, volume_db)


func _place_player() -> void:
	# ⛔ NO reposicionar player si estamos cargando un save
	if ThothGameState.loading_from_save:
		print("⛔ LevelTransition ignorado durante LOAD:", name)
		return

	if name != LevelManager.target_transition:
		return

	await _wait_for_player_ready()

	var final_pos := global_position + LevelManager.position_offset
	PlayerManager.set_player_position(final_pos)
	PlayerManager.saved_position = final_pos

	var facing := get_facing_direction()
	PlayerManager.desired_facing_direction = facing
	PlayerManager.player.set_facing_direction(facing)

	print("🚪 Player colocado en transition destino:", name, "->", final_pos)
	entered_from_here.emit()
	AudioManager.play_sfx(SFX_OUT, pitch, volume_db)
	PlayerManager.player.restore_movement()



func get_facing_direction() -> Vector2:
	match side:
		SIDE.LEFT:
			return Vector2.RIGHT  # Entrás por la izquierda, mirás a la derecha
		SIDE.RIGHT:
			return Vector2.LEFT
		SIDE.TOP:
			return Vector2.DOWN
		SIDE.BOTTOM:
			return Vector2.UP
	return Vector2.DOWN


func get_offset() -> Vector2:
	var offset : Vector2 = Vector2.ZERO
	var player_pos = PlayerManager.player.global_position
	
	if side == SIDE.LEFT or side == SIDE.RIGHT:
		if center_player == true:
			offset.y = 0
		else:
			offset.y = player_pos.y - global_position.y
		offset.x = 32
		if side == SIDE.LEFT:
			offset.x *= -1
	else:
		if center_player == true:
			offset.x = 0
		else:
			offset.x = player_pos.x - global_position.x
		offset.y = 32
		if side == SIDE.TOP:
			offset.y *= -1

	return offset


func _update_area() -> void:
	var new_rect : Vector2 = Vector2( 32, 32 )
	var new_position : Vector2 = Vector2.ZERO
	
	if side == SIDE.TOP:
		new_rect.x *= size
		new_position.y -= 16
	elif side == SIDE.BOTTOM:
		new_rect.x *= size
		new_position.y += 16
	elif side == SIDE.LEFT:
		new_rect.y *= size
		new_position.x -= 16
	elif side == SIDE.RIGHT:
		new_rect.y *= size
		new_position.x += 16
	
	if collision_shape == null:
		collision_shape = get_node( "CollisionShape2D" )
	
	collision_shape.shape.size = new_rect
	collision_shape.position = new_position


func _snap_to_grid() -> void:
	position.x = round( position.x / 16 ) * 16
	position.y = round( position.y / 16 ) * 16


func _wait_for_player_ready() -> void:
	var max_attempts := 60  # ~1 seg de espera como máximo (60 FPS)
	var attempts := 0
	while (not PlayerManager.player or not is_instance_valid(PlayerManager.player)) and attempts < max_attempts:
		await get_tree().process_frame
		attempts += 1

	if not PlayerManager.player or not is_instance_valid(PlayerManager.player):
		push_warning("⚠️ Player aún no disponible después de esperar.")
