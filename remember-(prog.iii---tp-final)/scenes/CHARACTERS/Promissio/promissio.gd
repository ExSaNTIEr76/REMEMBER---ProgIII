@icon("res://addons/proyect_icons/promissio_proyect_icon.png")

class_name Promissio    extends CharacterBody2D

@onready var add_on: Sprite2D = $AddOn
@onready var transformation: Sprite2D = $Transformations
@onready var animation_player: AnimationPlayer = %AnimationPlayer

var states: PromissioStateNames = PromissioStateNames.new()
var animations: PromissioAnimations = PromissioAnimations.new()

@onready var state_machine: StateMachine = $"STATE MACHINE"

@onready var antici_consec_timer: Timer = %AnticiConsecTimer
@onready var attack_timer: Timer = %AttackTimer
@onready var combo_timer: Timer = %ComboTimer
@onready var recovery_timer: Timer = %RecoveryTimer
@onready var vanish_timer: Timer = %VanishTimer

var last_attack_type: String = ""

var entering_block_fresh := true
var perfect_guard_requested := false
var is_in_perfect_guard := false
var pending_perfect_guard := false


func on_perfect_guard():
	perfect_guard_requested = true


#region CONCRETE SYMBOLS
var current_symbol: Symbol = null

@export var concrete_symbol_a: PackedScene
@export var concrete_symbol_b: PackedScene
@export var abstract_symbol: PackedScene
#endregion


var player: Player = null
var attack_type := "A"

var previous_direction: String = "Right"


func _ready():
	add_to_group("promissio")

	# Vincular al player si existe
	for node in get_tree().get_nodes_in_group("players"):
		if node is Player:
			player = node
			break

	vanish_timer.timeout.connect(_on_idle_timeout)


func set_concrete_symbol(slot: String, symbol_scene: PackedScene) -> void:
	print("🧪 set_concrete_symbol:", slot, symbol_scene)

	match slot:
		"CONCRETO A":
			concrete_symbol_a = symbol_scene
		"CONCRETO B":
			concrete_symbol_b = symbol_scene
		"ABSTRACTO":
			abstract_symbol = symbol_scene

	print("➡ A:", concrete_symbol_a, " B:", concrete_symbol_b, " ABSTRACTO:", abstract_symbol)


func clear_concrete_symbol(slot: String) -> void:
	match slot:
		"CONCRETO A":
			concrete_symbol_a = null
		"CONCRETO B":
			concrete_symbol_b = null


func perform_attack( attack: String ):
	var symbol_scene = concrete_symbol_a if attack == "A" else concrete_symbol_b
	if symbol_scene:
		if current_symbol:
			current_symbol.queue_free()

		current_symbol = symbol_scene.instantiate()
		
		# Setea el tipo de ataque que se usará para determinar animación
		current_symbol.attack_type = attack
		current_symbol.execute_attack( global_position, previous_direction, get_parent() )
	else:
		print( "❌ No hay símbolo asignado al ataque", attack )


func _on_AttackTimer_timeout():
	last_attack_type = attack_type


func snap_to_attack_position(direction: String):
	var offset := Vector2.ZERO

	match direction:
		"Right":
			offset = Vector2( -16, -11 )
		"Left":
			offset = Vector2( 16, -11 )
		"Up":
			offset = Vector2( 0, -25 )
		"Down":
			offset = Vector2( 0, 0 )

		"UpRight":
			offset = Vector2( 0, -25 )
		"UpLeft":
			offset = Vector2( 0, -25 )
		"DownRight":
			offset = Vector2( 0, 0 )
		"DownLeft":
			offset = Vector2( 0, 0 )

	global_position = player.global_position + offset


func snap_to_guard_position():
	if not is_instance_valid(player):
		return

	global_position = player.global_position + Vector2(0, 0)


func _on_idle_timeout():
	if state_machine.current_state.name == states.Idle:
		if animation_player.current_animation != animations.Vanish:
			animation_player.play(animations.Vanish)


func apply_equipment_from_data(equipment_data: EquipmentData) -> void:
	if not equipment_data:
		return

	for slot in ["CONCRETO A", "CONCRETO B"]:
		var item := equipment_data.get_equipped(slot)

		if item is EquipableItemData and item.symbol_scene:
			set_concrete_symbol(slot, item.symbol_scene)

	print("🔄 Promissio rehidratado:", concrete_symbol_a, concrete_symbol_b)
