@icon( "res://addons/proyect_icons/mandatory_combat_proyect_icon.png" )

class_name MandatoryCombat    extends Area2D

@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var combat_tag: RichTextLabel = $Control/CombatTag

@export var fight_name : String = "fight_1"
@export var waves : Array[WaveData] = []
@export var enemy_list: Resource

var current_wave : int = 0
var active_enemies : Array = []

@onready var barriers := get_children().filter(func(c): return c is Barrier)

@export_category( "Music" )

@export var combat_music : AudioStream
@export var combat_music_volume: float = -25.0
@export var combat_music_pitch : float = 1.0

func _ready():
	if GlobalFightsState.fights_completed.has(fight_name):
		print("✔️ Combate ya completado: %s" % fight_name)
		no_barriers()
	else:
		# 🔒 Esperamos a que el player entre en el área
		body_entered.connect(_on_body_entered)


func _start_combat():
	AudioManager.is_in_combat = true

	if combat_music:
		await AudioManager.fade_out_and_pause_current_music(1.0)
		AudioManager.play_music(combat_music, combat_music_pitch, combat_music_volume, false)
	else:
		AudioManager.fade_out_current_music(1.0)

	current_wave = 0
	_close_barriers()
	_spawn_wave()


func _spawn_wave():
	if PlayerManager.game_over:
		return
	
	if not is_inside_tree():
		return

	if current_wave >= waves.size():
		_end_combat()
		return

	print("⚔️ Spawneando oleada %d" % (current_wave + 1))

	for spawn_data in waves[current_wave].enemies:
		var enemy = spawn_data.enemy_scene.instantiate()
		enemy.global_position = spawn_data.position
		enemy.rotation = spawn_data.rotation
		add_child(enemy)

		# 💡 Pasamos el Player directamente desde PlayerManager
		if PlayerManager.player:
			enemy.player = PlayerManager.player

		enemy.connect("tree_exited", Callable(self, "_on_enemy_defeated").bind(enemy))
		active_enemies.append(enemy)


func _on_enemy_defeated(enemy):
	if PlayerManager.game_over:
		return

	if enemy in active_enemies:
		active_enemies.erase(enemy)

	if active_enemies.is_empty():
		current_wave += 1
		_spawn_wave()


func _end_combat():
	print("🏆 Combate terminado: %s" % fight_name)
	SceneTransition.white_flash()
	AudioManager.play_sfx_path("res://audio/SFX/Ambient SFX/Sfx_Fight_Completed.ogg", 1.5, -12.0)
	animations.play("enemies_overcome")
	GlobalFightsState.fights_completed[fight_name] = true
	_open_barriers()

	# 🔇 Solo fade-out del combat_music (sin limpiar el player)
	var current_player := AudioManager.music_players[AudioManager.current_music_player]
	if current_player.playing:
		var tween := AudioManager.create_tween()
		tween.tween_property(current_player, "volume_db", -40, 1.0)
		await tween.finished
		current_player.stop()

	# 🔄 Ahora retomamos
	if AudioManager._paused_music_stream:
		AudioManager.resume_previous_music()
	else:
		if AudioManager.default_music_stream:
			AudioManager.play_music(
				AudioManager.default_music_stream,
				AudioManager.default_music_pitch,
				AudioManager.default_music_volume,
				false
			)

	AudioManager.is_in_combat = false


func _close_barriers():
	for barrier in barriers:
		if barrier.has_method("combat_barrier_on"):
			barrier.combat_barrier_on()

func _open_barriers():
	for barrier in barriers:
		if barrier.has_method("combat_barrier_off"):
			barrier.combat_barrier_off()

func no_barriers():
	for barrier in barriers:
		if barrier.has_method("no_barriers"):
			barrier.no_barriers()

func _on_body_entered(body: Node) -> void:
	if body is Player and not GlobalFightsState.fights_completed.has(fight_name):
		call_deferred("_start_combat")
		body_entered.disconnect(_on_body_entered)
