@icon("res://addons/proyect_icons/player_spawner_proyect_icon.png")

class_name PlayerSpawn extends Node2D

@export var spawn_promissio: bool = false

@onready var promissio_instance := $Promissio as Promissio

func _ready() -> void:
	if ThothGameState.loading_from_save:
		return

	add_to_group( "player_spawn" )
	visible = false

	#Si estamos cargando desde un save, ignorar el spawn
	var saved_pos := ThothGameState.get_player_position()
	if ThothGameState.loading_from_save and saved_pos != Vector2.ZERO:
		print( "🌱 PlayerSpawn ignorado (se respawneará desde PlayerManager):", saved_pos )
		return

	#Esperar hasta que el Player esté instanciado y en el árbol
	await _wait_for_player_ready()

	#Posicionar player si no hubo save previo
	if not PlayerManager.player_spawned:
		PlayerManager.set_player_position( global_position )
		PlayerManager.player_spawned = true

	#Manejar Promissio
	if spawn_promissio and promissio_instance:
		PlayerManager.attach_promissio_from_spawn( promissio_instance )

		if PlayerManager.EQUIPMENT_DATA:
			promissio_instance.apply_equipment_from_data(
				PlayerManager.EQUIPMENT_DATA
			)
	elif promissio_instance:
		promissio_instance.queue_free()


func _wait_for_player_ready() -> void:
	var attempts := 0
	while ( not PlayerManager.player or not is_instance_valid( PlayerManager.player ) or not PlayerManager.player.is_inside_tree()) and attempts < 60:
		await get_tree().process_frame
		attempts += 1
	if not PlayerManager.player or not is_instance_valid( PlayerManager.player ):
		push_warning( "⚠️ PlayerSpawn: Player nunca se inicializó completamente." )
