@icon( "res://addons/proyect_icons/simple_puzzle_proyect_icon.png" )

class_name SimpleBlocksPuzzle    extends Node2D

@export var puzzle_name : String = "puzzle_1"

@export var total_attempts : int = 0
@export var correct_algorithm : Array[int] = []
@export var current_algorithm : Array[int] = []

@export var is_puzzle_active : bool = false
@export var is_algorithm_completed : bool = false

@onready var blocks := get_children().filter(func(c): return c is FloatingBlock)
@onready var barriers := get_children().filter(func(c): return c is Barrier)


func _ready():
	add_to_group("puzzles")

	if not Engine.is_editor_hint():
		if not GlobalPuzzlesState.is_connected("state_restored", Callable(self, "sync_with_global")):
			GlobalPuzzlesState.state_restored.connect(Callable(self, "sync_with_global"))

		# Sincronizar inmediatamente
		sync_with_global()


func _start_puzzle():
	current_algorithm.clear()
	total_attempts = correct_algorithm.size()
	is_puzzle_active = true
	_close_barriers()


func register_block_press(block_num: int) -> void:
	if not is_puzzle_active or is_algorithm_completed:
		return
	
	current_algorithm.append(block_num)
	total_attempts -= 1

	print("🧮 Entrada actual del puzzle:", current_algorithm)
	print("🎯 Objetivo del puzzle:", correct_algorithm)

	if current_algorithm.size() == correct_algorithm.size():
		_check_algorithm()
	elif total_attempts <= 0:
		_reset_puzzle()


func _check_algorithm():
	if current_algorithm == correct_algorithm:
		is_algorithm_completed = true
		is_puzzle_active = false
		GlobalPuzzlesState.puzzles_completed[puzzle_name] = true
		AudioManager.play_sfx_path("res://audio/SFX/Ambient SFX/Sfx_Fight_Completed.ogg", 1.5, -12.0)
		CinematicManager._wait(0.2)
		AudioManager.play_sfx_path("res://audio/SFX/Ambient SFX/Sfx_Puzzle_Completed.ogg", 1.0, -7.0)
		_open_barriers()

		for block in blocks:
			if block.has_method("mark_as_resolved"):
				block.mark_as_resolved()

		print("✅ Puzzle resuelto, bajando barreras...")
	else:
		_reset_puzzle()
		print("❌ Combinación incorrecta. Inténtalo de nuevo...")


func _close_barriers():
	for barrier in barriers:
		if barrier.has_method("puzzle_barrier_on"):
			barrier.puzzle_barrier_on()


func _open_barriers():
	for barrier in barriers:
		if barrier.has_method("puzzle_barrier_off"):
			barrier.puzzle_barrier_off()


func no_barriers():
	for barrier in barriers:
		if barrier.has_method("no_barriers"):
			barrier.no_barriers()


func _reset_puzzle():
	current_algorithm.clear()
	total_attempts = correct_algorithm.size()

	for block in blocks:
		if block.has_method("reset_state"):
			block.reset_state()

	# Podés sumar animaciones acá si querés


func sync_with_global() -> void:
	if GlobalPuzzlesState.puzzles_completed.has(puzzle_name):
		is_algorithm_completed = true
		is_puzzle_active = false
		no_barriers()

		for block in blocks:
			if block.has_method("puzzle_completed"):
				block.puzzle_completed()

		print("📌 Puzzle restaurado como COMPLETADO:", puzzle_name)
	else:
		# 👇 Forzar reset visual y lógico de los bloques
		for block in blocks:
			if block.has_method("reset_state"):
				pass

		_start_puzzle()
		print("📌 Puzzle restaurado como NO resuelto:", puzzle_name)


## En GlobalPuzzlesStates.gd solo para debug
#func _input(event):
	#if event.is_action_pressed("debug_reset_puzzles"):
		#puzzles_completed.clear()
		#print("🧼 Todos los puzzles han sido reseteados.")
