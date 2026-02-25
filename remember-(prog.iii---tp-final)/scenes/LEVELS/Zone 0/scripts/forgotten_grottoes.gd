class_name Z0ForgottenGrottoes    extends Node2D


@onready var shadow_stalker: Sprite2D = %ShadowStalker
@onready var shadow_stalker_animations: AnimationPlayer = %ShadowStalkerAnimations

@onready var neverending_whispers: AudioStreamPlayer2D = %NeverendingWhispers
@onready var static_sound: AudioStreamPlayer2D = %StaticSound

@onready var level_animations: AnimationPlayer = %LevelAnimations

@onready var layer_5__background_: LevelTileMapLayer = $"NORMALWORLD/Layer 5 (Background)"
var level_tile_map_layer = load("res://scenes/LEVELS/levelScripts/level_tile_map_layer.gd")

@onready var wall_closed: TileMapLayer = $NORMALWORLD/WallClosed
@onready var wall_closed_2: TileMapLayer = $NORMALWORLD/WallClosed2
@onready var wall_closed_3: TileMapLayer = $NORMALWORLD/WallClosed3


func _ready() -> void:
	shadow_stalker.hide()


func start_migraine() -> void:
	AudioManager.play_music_path("res://audio/music/Migraine.ogg", 1.0, -5.0)
	level_animations.play("migraine_canvas")


func start_whispers() -> void:
	neverending_whispers.play()


func start_otherworld() -> void:
	level_animations.play("otherworld_canvas")


func start_shadow_embrace() -> void:
	shadow_stalker_animations.play("shadows_approaching")


func _on_shadow_aparition_area_body_entered(body: Node2D) -> void:
	if body is Player:
		shadow_stalker.show()
		shadow_stalker_animations.play("fade_in")


func start_sentence() -> void:
	neverending_whispers.stop()
	shadow_stalker_animations.play("sentence")
