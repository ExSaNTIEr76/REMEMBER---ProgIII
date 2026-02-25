class_name TheNothingness    extends Node2D

@onready var zones := [
	$Zone0, $Zone1, $Zone2, $Zone3, $Zone4, $Zone5
]
@onready var areas := [
	$"../ZONES/Area0", $"../ZONES/Area1", $"../ZONES/Area2", $"../ZONES/Area3", $"../ZONES/Area4", $"../ZONES/Area5"
]
@onready var area_collisions := [
	$"../ZONES/Area0/AreaCollision0", $"../ZONES/Area1/AreaCollision1", $"../ZONES/Area2/AreaCollision2", $"../ZONES/Area3/AreaCollision3", $"../ZONES/Area4/AreaCollision4", $"../ZONES/Area5/AreaCollision5"
]
@onready var labels := [
	$"../ZoneLabels/Zone0", $"../ZoneLabels/Zone1", $"../ZoneLabels/Zone2", $"../ZoneLabels/Zone3", $"../ZoneLabels/Zone4", $"../ZoneLabels/Zone5"
]

@onready var map_level_animations: AnimationPlayer = %MapLevelAnimations

var player: Node = null


func _ready():
	AudioManager.fade_out_all(0.8)
	await _wait_for_player()
	_hide_all_elements()

	if GlobalConditions.welcome_home == true:
		map_level_animations.play("HOME")
	else:
		map_level_animations.play("UNKNOWN")

	_update_zone_visibility()
	_update_zone_animations()
	await _play_flower_growth_if_needed()
	await _update_inner_whispers()


func _wait_for_player() -> void:
	var max_wait_frames := 120
	while (PlayerManager.player == null or not PlayerManager.player.is_inside_tree()) and max_wait_frames > 0:
		await get_tree().process_frame
		max_wait_frames -= 1

	player = PlayerManager.player
	if not player:
		push_error("❗ No se pudo encontrar al jugador.")


func _hide_all_elements() -> void:
	for i in range(1, 6):
		areas[i].hide()
		area_collisions[i].hide()
		labels[i].hide()
		areas[i].collision_layer &= ~(1 << 2)  # Desactiva layer 3 (bit 2)

	# Zona 0 (siempre visible e interactuable)
	labels[0].hide()
	areas[0].collision_layer |= (1 << 2)  # Activa layer 3 (bit 2)


func _play_flower_growth_if_needed() -> void:
	var card_count := GlobalConditions.zodiac_key_cards
	var flower_count := GlobalConditions.zone_flowers


	if card_count == flower_count + 1 and flower_count < 5:
		GlobalConditions.zone_illness += 1
		map_level_animations.play("RESET")
		await CinematicManager._wait(0.6)
		PlayerManager.player.freeze_movement()
		AudioManager.play_sfx_path("res://audio/SFX/Ambient SFX/Sfx_Heartbeat.ogg", 1.0, -5.0)
		SceneTransition.black_flash()
		await CinematicManager._wait(2.0)  # Espera 3 segundos
		AudioManager.play_sfx_path("res://audio/SFX/Ambient SFX/Sfx_Heartbeat.ogg", 1.0, -5.0)
		SceneTransition.black_flash()
		await CinematicManager._wait(2.0)  # Espera 3 segundos
		AudioManager.play_sfx_path("res://audio/SFX/Ambient SFX/Sfx_Heartbeat.ogg", 1.0, -5.0)
		SceneTransition.black_flash()
		await CinematicManager._wait(1.0)  # Espera 3 segundos
		AudioManager.play_sfx_path("res://audio/SFX/Ambient SFX/Sfx_Heartbeat.ogg", 1.0, -5.0)
		SceneTransition.black_flash()
		await CinematicManager._wait(1.0)  # Espera 3 segundos
		AudioManager.play_sfx_path("res://audio/SFX/Ambient SFX/Sfx_Competence_Flash.ogg", 1.5, -15.0)
		SceneTransition.white_flash()
		await CinematicManager._wait(1.5)  # Espera 3 segundos
		var zone_anim: AnimatedSprite2D = zones[flower_count + 1]
		zone_anim.play("Zone%d_growing" % (flower_count + 1))
		AudioManager.play_sfx_path("res://audio/SFX/Ambient SFX/Sfx_Flower_Zone_Growing.ogg", 0.9, -5.0)
		await zone_anim.animation_finished
		GlobalConditions.zone_flowers += 1
		PlayerManager.player.restore_movement()

		if GlobalConditions.welcome_home == true:
			map_level_animations.play("HOME_NEW")
		else:
			map_level_animations.play("UNKNOWN_NEW")


func _update_zone_visibility() -> void:
	for i in range(1, GlobalConditions.zone_flowers + 1):
		areas[i].show()


func _update_zone_animations() -> void:
	for i in range(1, GlobalConditions.zone_flowers + 1):
		if i < 6:
			zones[i].play("Zone%d_flower" % i)


func _update_inner_whispers() -> void:
	await CinematicManager._wait(0.1)
	if GlobalConditions.zone_illness == 1:
		AudioManager.play_music_path("res://audio/music/Escucha (first call).ogg", 1.0, -12.0)
	if GlobalConditions.zone_illness == 2:
		AudioManager.play_music_path("res://audio/music/Escucha (second call).ogg", 1.0, -10.0)
	if GlobalConditions.zone_illness == 3:
		AudioManager.play_music_path("res://audio/music/Escucha (third call).ogg", 1.0, -8.0)
	if GlobalConditions.zone_illness == 4:
		AudioManager.play_music_path("res://audio/music/Escucha (fourth call).ogg", 1.0, -5.0)
	if GlobalConditions.zone_illness >= 0:
		pass


# Señales de entrada/salida para mostrar labels y colisiones
func _on_area_0_body_entered(_player): labels[0].show()
func _on_area_0_body_exited(_player): labels[0].hide()

func _on_area_1_body_entered(_player): _toggle_zone_ui(1, true)
func _on_area_1_body_exited(_player): _toggle_zone_ui(1, false)

func _on_area_2_body_entered(_player): _toggle_zone_ui(2, true)
func _on_area_2_body_exited(_player): _toggle_zone_ui(2, false)

func _on_area_3_body_entered(_player): _toggle_zone_ui(3, true)
func _on_area_3_body_exited(_player): _toggle_zone_ui(3, false)

func _on_area_4_body_entered(_player): _toggle_zone_ui(4, true)
func _on_area_4_body_exited(_player): _toggle_zone_ui(4, false)

func _on_area_5_body_entered(_player): _toggle_zone_ui(5, true)
func _on_area_5_body_exited(_player): _toggle_zone_ui(5, false)

func _toggle_zone_ui(index: int, _show: bool) -> void:
	if GlobalConditions.zone_flowers >= index:
		areas[index].visible = _show
		labels[index].visible = _show
	
	if GlobalConditions.zone_flowers >= index:
		areas[index].visible = _show
		labels[index].visible = _show
		if _show:
			areas[index].collision_layer |= (1 << 2)  # Habilita interacción
