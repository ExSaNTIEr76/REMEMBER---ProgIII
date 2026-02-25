@icon("res://addons/proyect_icons/spectre_proyect_icon.png")

#common_spectre.gd:

class_name Enemy extends CharacterBody2D

var states: EnemyStateNames = EnemyStateNames.new()
var animations: EnemyAnimations = EnemyAnimations.new()
@export var stats: EnemyGlobalStats

var player: CharacterBody2D = null

@onready var state_machine: StateMachine = $"STATE MACHINE"

@onready var sprite: Sprite2D = $Sprite2D
@onready var enemy_animations: AnimationPlayer = $EnemyAnimations
@onready var enemy_effects: AnimationPlayer = $EnemyEffects

@onready var mark_animations: AnimationPlayer = $MarkAnimations
@onready var damage_numbers_origin: Node2D = $DamageNumbersOrigin
@onready var detection_area: Area2D = $DetectionArea
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var attack_area: Area2D = $AttackArea

@onready var ghost_timer: Timer = $TIMERS/GhostTimer
@onready var idle_timer: Timer = $TIMERS/IdleTimer
@onready var charging_timer: Timer = $TIMERS/ChargingTimer
@onready var onrushing_timer: Timer = $TIMERS/OnrushingTimer
@onready var crashing_timer: Timer = $TIMERS/CrashingTimer
@onready var cooldown_timer: Timer = $TIMERS/CooldownTimer

@export var start_with_spawn: bool = true
@export var speed := 50.0
var previous_direction: String = "Down"
var move_direction := Vector2.ZERO
var charge_direction: Vector2 = Vector2.ZERO
var cooldown_active := false
var is_committed_to_charge := false

var stunned_by_perfect_guard := false
var invulnerable := false


func _ready():
	if stats:
		stats = stats.duplicate()

	if sprite.material and sprite.material is ShaderMaterial:
		sprite.material = sprite.material.duplicate()

	# Si no se asignó player desde afuera, lo busca en el grupo
	if not player:
		for node in get_tree().get_nodes_in_group("players"):
			if node is Player:
				player = node
				break

	attack_area.body_entered.connect(_on_body_entered)
	attack_area.body_exited.connect(_on_body_exited)
	detection_area.body_entered.connect(_on_detected_player)
	detection_area.body_exited.connect(_on_lost_player)
	ghost_timer.timeout.connect(_on_trail_timer_timeout)

	# Override dinámico del estado inicial
	if start_with_spawn:
		state_machine.default_state = state_machine.get_node(states.Spawn)


func _on_detected_player(body):
	if body is Player and not is_committed_to_charge:
		speed = 75.0


func _on_lost_player(body):
	if body is Player and not is_committed_to_charge:
		speed = 50.0


var has_seen_player_recently := false
var forget_timer: Timer = null
var should_attack := false

func _on_body_entered(body):
	print("Entró algo al área de ataque: ", body)
	if body is Player:
		print("¡Es el player!")
		should_attack = true
		if forget_timer:
			forget_timer.stop()
		state_machine.change_to(states.Charging)


func _on_body_exited(body):
	if body is Player and not is_committed_to_charge:
		if not forget_timer:
			forget_timer = Timer.new()
			forget_timer.wait_time = 2.0
			forget_timer.one_shot = true
			forget_timer.timeout.connect(_on_forget_player)
			add_child(forget_timer)
		forget_timer.start()


func _on_forget_player():
	should_attack = false


var desired_velocity: Vector2 = Vector2.ZERO

func _physics_process(_delta):
	move_and_slide()


func on_hit() -> void:
	if stats.CURRENT_HP <= 0 or state_machine.current_state.name == "EnemyStateDead":
		return

	# Si está en estados especiales, sólo mostrar daño visual
	var current = state_machine.current_state.name
	if current == "EnemyStateCharging" or current == "EnemyStateOnrushing":
		enemy_effects.play(animations.hit_flash)
		return

	enemy_effects.play(animations.hit_flash)


func take_damage(amount: int, attack_data: DamageData = null) -> void:
	if not stats or stats.CURRENT_HP <= 0:
		return  

	stats.CURRENT_HP -= amount
	show_hit_numbers(amount)
	TextPopup.show_enemy_popup(stats.enemy_name)

	# Sonido de impacto automático
	if attack_data:
		ImpactSounds.play_from_attack(attack_data, stats)

	if stats.CURRENT_HP <= 0:
		_disable_combat_colliders()
		print("⚰️ Enemigo derrotado")
		state_machine.change_to(states.Dead)
	else:
		print("💢 Enemigo herido: ", stats.CURRENT_HP)
		on_hit()

	print("🎯 take_damage recibido. amount:", amount, "attack_data:", attack_data)


func on_perfect_guarded() -> void:
	if state_machine.current_state.name in [
		states.Dead,
		states.Stunned
	]:
		return

	stunned_by_perfect_guard = true
	state_machine.change_to(states.Stunned)


func _disable_combat_colliders():
	var hitbox = get_node_or_null("Hitbox")
	if hitbox:
		hitbox.monitoring = false
		hitbox.set_deferred("monitoring", false)

	attack_area.monitoring = false
	attack_area.set_deferred("monitoring", false)

	detection_area.monitoring = false
	detection_area.set_deferred("monitoring", false)


func show_hit_numbers(damage: int) -> void:
	DamageNumbers.display_number(damage, damage_numbers_origin.global_position)


func get_damage_amount() -> int:
	return stats.ATK


func _on_trail_timer_timeout():
	_spawn_ghost_trail()


# Instanciar el ghostrail
func _spawn_ghost_trail():
	var ghost_scene = preload("res://scenes/ENEMIES/Spectres/common_spectre/ghostrail/ghostrail_common_spectre.tscn")
	var ghost = ghost_scene.instantiate()
	get_parent().add_child(ghost)
	ghost.global_position = global_position
	ghost.z_index = z_index - 1

	var ghost_sprite = ghost.get_node("Sprite2D")
	ghost_sprite.texture = sprite.texture
	ghost_sprite.frame = sprite.frame
	var original_color = sprite.modulate
	ghost_sprite.modulate = Color(original_color.r, original_color.g, original_color.b, 0.3)

	# Tween para que se desvanezca brevemente
	var fade = ghost.create_tween()
	fade.tween_property(ghost_sprite, "modulate:a", 0.0, 0.5)
	fade.tween_callback(Callable(ghost, "queue_free"))


func vibrate_briefly():
	var orig_pos := position
	var tween = create_tween()
	tween.set_loops(2)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", orig_pos + Vector2(2, 0), 0.05)
	tween.tween_property(self, "position", orig_pos - Vector2(2, 0), 0.05)
	tween.tween_property(self, "position", orig_pos, 0.05)


func start_cooldown(duration: float) -> void:
	cooldown_active = true
	await get_tree().create_timer(duration).timeout
	cooldown_active = false 
