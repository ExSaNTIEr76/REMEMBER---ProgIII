@icon( "res://addons/proyect_icons/level_proyect_icon.png" )

class_name Level    extends Node2D

@export var level_name : String = ""
@export var zone_name : String = ""
@export var allow_pause := true
@export var use_fade: bool = true

var init_load = false
var savestate: ThothGameState = ThothGameState

@export_category( "Level Tags" )

@export var zone_tag: String = ""
@export var transition_tag: String = ""

@export_category( "Music" )

@export var music : AudioStream
@export var music_volume: float = -5.0
@export var music_pitch : float = 1.0

@export_category( "Ambient" )

@export var ambient : AudioStream
@export var ambient_volume: float = -10.0
@export var ambient_pitch : float = 1.0

@onready var y_sort_node: Node2D = %"YSORT"
@onready var common_ghost_scene: PackedScene = preload( "res://scenes/ENEMIES/Spectres/common_spectre/common_spectre.tscn" )


@export_category( "Light Settings" )

@export var keep_light_between_rooms: bool = false


func _ready() -> void:
	self.y_sort_enabled = true

	PlayerManager.ensure_player()
	PlayerManager.set_as_parent( self )
	LevelManager.set_current_level( self )

	if not LevelManager.level_load_started.is_connected( _free_level ):
		LevelManager.level_load_started.connect( _free_level)
	if not LevelManager.level_loaded.is_connected( _on_level_loaded ):
		LevelManager.level_loaded.connect( _on_level_loaded, CONNECT_ONE_SHOT )

	print( "[LEVEL READY] loading_from_save =", savestate.loading_from_save )

	if savestate.loading_from_save:
		_handle_load_from_save()
	else:
		await get_tree().process_frame
		PlayerManager._on_level_loaded()

	await get_tree().process_frame
	get_tree().paused = false
	LevelManager.level_loaded.emit()

	# Fade opcional según el nivel
	if use_fade:
		await SceneTransition.fade_in( transition_tag )


func _process( _delta: float ) -> void:
	if init_load:
		return
	init_load = true

	# Si al terminar de cargar el nivel no existe player, respawnearlo
	if not PlayerManager.player or not is_instance_valid( PlayerManager.player ):
		print( "🧩 Player no encontrado tras carga, forzando respawn manual." )
		PlayerManager.respawn_player_after_load()
	get_tree().paused = true


func _on_level_loaded():
	if music:
		# Guarda la música del nivel como "default"
		AudioManager.default_music_stream = music
		AudioManager.default_music_volume = music_volume
		AudioManager.default_music_pitch = music_pitch
		AudioManager.default_music_position = 0.0

		# Solo se reproduce si no se está en combate
		if not AudioManager.is_in_combat:
			AudioManager.play_music( music, music_pitch, music_volume, false )
	else:
		AudioManager.fade_out_current_music( 0.6 )

	if ambient:
		AudioManager.play_ambient( ambient, ambient_pitch, ambient_volume, false )
	else:
		AudioManager.fade_out_current_ambient( 0.6 )


func _free_level() -> void:
	PlayerManager.unparent_player( self )
	queue_free()


# Maneja el caso de carga desde un save
func _handle_load_from_save() -> void:
	print( "[LOAD] Restaurando estado desde save..." )

	if savestate.visited_level( self ):
		savestate.unpack_level( self )

		var pos := savestate.get_player_position()
		if pos != Vector2.ZERO:
			PlayerManager.queue_restore_position( pos )
		else:
			print( "⚠️ No se encontró posición en el save, se usará spawn por defecto." )

		# Restaura globales
		savestate.get_game_variables( PlayerManager )
		savestate.get_game_variables( GlobalConditions)
		savestate.get_game_variables( GlobalInventoryState )
		GlobalInventoryState.apply_to_player()
		savestate.get_game_variables( GlobalChestsState )
		savestate.get_game_variables( GlobalCinematicsState )
		savestate.get_game_variables( GlobalPuzzlesState )
		savestate.get_game_variables( GlobalFightsState )

		# Sincroniza grupos
		for chest in get_tree().get_nodes_in_group( "chests" ):
			if chest.has_method( "sync_with_global" ):
				chest.sync_with_global()
		for puzzle in get_tree().get_nodes_in_group( "puzzles" ):
			if puzzle.has_method( "sync_with_global" ):
				puzzle.sync_with_global()

	await LevelManager.level_loaded
	savestate.loading_from_save = false
	print( "✅ LOAD finalizado, loading_from_save = false" )
