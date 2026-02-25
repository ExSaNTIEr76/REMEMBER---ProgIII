extends Node

## Mapeo por nombre de entidad (ej. "Player") a conjunto de estados desbloqueados
var unlocked_states := {}
var learned_states := {}        # Estados aprendidos permanentemente
var temporary_locked := {}      # Bloqueos temporales (cinematic, illness, etc.)


func _ready():
	print("🧩 StateUnlockManager listo.")


func learn_state(character: String, state: String) -> void:
	if not learned_states.has(character):
		learned_states[character] = {}
	learned_states[character][state] = true


func lock_temporarily(character: String, state: String) -> void:
	if not temporary_locked.has(character):
		temporary_locked[character] = {}
	temporary_locked[character][state] = true


func unlock_temporarily(character: String, state: String) -> void:
	if temporary_locked.has(character):
		temporary_locked[character][state] = false


## Devuelve true si el estado está desbloqueado
func is_unlocked(character: String, state: String) -> bool:
	var learned = learned_states.get(character, {}).get(state, false)
	var temp_locked = temporary_locked.get(character, {}).get(state, false)

	return learned and not temp_locked


## Desbloquea un estado para un personaje
func unlock(character_name: String, state_name: String) -> void:
	if not unlocked_states.has(character_name):
		unlocked_states[character_name] = {}
	unlocked_states[character_name][state_name] = true
	#print("🔓 Estado desbloqueado:", character_name, state_name)


## Desbloquea múltiples estados
func unlock_states(character_name: String, states: Array[String]) -> void:
	for state_name in states:
		unlock(character_name, state_name)


## Bloquea un estado para un personaje
func lock(character_name: String, state_name: String) -> void:
	if unlocked_states.has(character_name):
		unlocked_states[character_name][state_name] = false
		#print("⛔ Estado bloqueado:", character_name, state_name)


## Bloquea múltiples estados
func lock_states(character_name: String, states: Array[String]) -> void:
	for state_name in states:
		lock(character_name, state_name)


func reset_states(character_id: String) -> void:
	if unlocked_states.has(character_id):
		unlocked_states[character_id] = []


func get_unlocked_states(character_id: String) -> Array[String]:
	return unlocked_states.get(character_id, [])
