#level_manager.gd (escena autoload):

extends Node

signal level_load_started
signal level_loaded
signal tilemap_bounds_changed(bounds: Array[Vector2])

var pending_entry_position: Vector2 = Vector2.ZERO
var current_level_path: String
var current_level_node: Level
var current_tilemap_bounds: Array[Vector2]
var target_transition: String
var position_offset: Vector2
var current_level: String
var current_zone: String


func set_current_level(level: Level) -> void:
	current_level_node = level
	current_level_path = level.scene_file_path


func get_current_level() -> Level:
	return current_level_node


func get_current_level_path() -> String:
	return current_level_path


func get_current_zone() -> String:
	return current_zone


func set_current_zone(zone: String) -> void:
	current_zone = zone


func _ready() -> void:
	await get_tree().process_frame
	level_loaded.emit()


func change_tilemap_bounds(bounds: Array[Vector2]) -> void:
	current_tilemap_bounds = bounds
	tilemap_bounds_changed.emit(bounds)


## ✅ Nueva versión con opción de evitar el fade
func load_new_level(level_path: String, _target_transition: String, _position_offset: Vector2, use_fade: bool = true) -> void:
	get_tree().paused = true
	PlayerManager.player.freeze_movement()
	target_transition = _target_transition
	position_offset = _position_offset
	pending_entry_position = Vector2.ZERO

	var level_scene := ResourceLoader.load(level_path)
	var temp_level = level_scene.instantiate()
	var tag := "default"
	if temp_level is Level and temp_level.transition_tag != "":
		tag = temp_level.transition_tag
	temp_level.queue_free()

	# 🔸 Fade opcional
	if use_fade:
		await SceneTransition.fade_out(tag)

	level_load_started.emit()
	await get_tree().process_frame
	print("🚪 Entrando a change_scene_to_file, loading_from_save=", ThothGameState.loading_from_save)

	get_tree().change_scene_to_file(level_path)
	await get_tree().process_frame
	get_tree().paused = false
