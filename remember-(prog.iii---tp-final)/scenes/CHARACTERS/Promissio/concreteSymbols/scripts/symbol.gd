# symbol.gd

class_name Symbol    extends Node2D

@export var damage: int = 1
@export var attack_range: float = 50.0
@export var attack_speed: float = 1.0
@export var cp_cost: int = 1
@export var attack_class: String = "Strike"
@export var attack_type: String = "A"
@export var base_animation_name: String = ""
@export var hitbox_scene: PackedScene

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var symbol_effects: AnimationPlayer = $SymbolEffects

@export var symbol_prefix: String = "Knife"

@onready var spawn_sound: AudioStreamPlayer2D = %SpawnSound
@export_range(0.5, 2.0) var spawn_pitch_base := 1.0
@export_range(0.0, 0.2) var spawn_pitch_variation := 0.05


# Si el attack_class var es Physic, los espectros no sufren reset. Si es Magic, sí.

func execute_attack(_position: Vector2, direction: String, parent: Node) -> void:
	global_position = _position
	parent.add_child(self)

	_play_spawn_sfx()

	var full_animation_name = symbol_prefix + attack_type + "_" + direction
	if animation_player.has_animation(full_animation_name):
		animation_player.play(full_animation_name)
	else:
		push_warning("⚠️ No se encontró animación: " + full_animation_name)

	if hitbox_scene:
		var hitbox: Area2D = hitbox_scene.instantiate()
		hitbox.global_position = _position
		add_child(hitbox)
		if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			hitbox.area_entered.connect(_on_hitbox_area_entered)

		# Conexión para aplicar daño al detectar hurtboxes
		if not hitbox.area_entered.is_connected(_on_hitbox_area_entered):
			hitbox.area_entered.connect(_on_hitbox_area_entered)

	if animation_player.is_playing():
		await animation_player.animation_finished
		queue_free()
	else:
		await get_tree().create_timer(0.5).timeout
		queue_free()

	spawn_sound.finished.connect(func():
		spawn_sound.pitch_scale = spawn_pitch_base
	, CONNECT_ONE_SHOT)




func _create_damage_data() -> DamageData:
	var data: DamageData = DamageData.new()

	match attack_class.to_lower():
		"slash":
			data.attribute = DamageData.AttributeType.SLASH
		"strike":
			data.attribute = DamageData.AttributeType.STRIKE
		"sol":
			data.attribute = DamageData.AttributeType.SOL
		"luna":
			data.attribute = DamageData.AttributeType.LUNA
		_:
			data.attribute = DamageData.AttributeType.NONE
	data.base_damage = damage
	return data


func _on_hitbox_area_entered(area: Area2D) -> void:
	print("📡 area_entered detectado:", area)
	if area.is_in_group("hurtboxes"):
		var target = area.get_parent()
		if target and target.has_method("take_damage"):
			var attack_data: DamageData = _create_damage_data()
			print("💥 Hit detectado contra:", target, "con attack_data:", attack_data.attribute)
			target.take_damage(damage, attack_data)


func get_damage_amount() -> int:
	return damage


func _play_spawn_sfx():
	if not spawn_sound:
		return
	if not spawn_sound.stream:
		return
	if spawn_sound.playing:
		return

	var variation := randf_range(-spawn_pitch_variation, spawn_pitch_variation)
	spawn_sound.pitch_scale = spawn_pitch_base + variation
	spawn_sound.play()
