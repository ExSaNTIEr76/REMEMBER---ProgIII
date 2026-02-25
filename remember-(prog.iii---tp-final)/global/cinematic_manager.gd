#cinematic_manager.gd (autoload):

extends Node

# 🔹 Direcciones, por compatibilidad con el player
enum SIDE { LEFT, RIGHT, UP, DOWN }

# 🔹 Diccionario para llevar control de entidades bloqueadas
var _cinematic_entities := {}


# ===================================
# 🎬 INICIO DE CINEMÁTICA
# ===================================

func start_cinematic(entity: Node = null):
	if entity == null:
		entity = PlayerManager.get_player()
	if not entity: 
		return

	# Ya está en cinemática → ignoramos
	if _cinematic_entities.has(entity):
		return

	# Bloqueamos movimiento si tiene método propio
	if entity.has_method("disable"):
		entity.disable()
	elif entity.has_method("freeze_movement"):
		entity.freeze_movement()

	# Guardamos su estado para restaurar luego
	_cinematic_entities[entity] = {
		"was_disabled": true
	}

	# Si tiene state_machine → forzamos Cinematic si existe
	if entity.has_node("STATE MACHINE"):
		var sm := entity.get_node("STATE MACHINE")
		if sm and sm.has_method("change_to") and "states" in entity:
			var states = entity.states
			if "Cinematic" in states:
				sm.call_deferred("change_to", states.Cinematic)


	#print("🎬 Cinemática iniciada para:", entity.name)


# ===================================
# ▶️ REPRODUCIR ANIMACIÓN
# ===================================

func play_cinematic(entity_ref, anim_name: String, wait: bool = false) -> void:
	# Resolvemos la entidad (acepta Node, NodePath o String)
	var entity := _resolve_entity_ref(entity_ref)
	if not entity:
		push_warning("⚠️ Entidad no encontrada para play_cinematic: %s" % str(entity_ref))
		return

	# Buscar AnimationPlayer o fallback
	var anim_player: AnimationPlayer = null
	if entity.has_node("AnimationPlayer"):
		anim_player = entity.get_node("AnimationPlayer")
	elif entity.has_node("PuppetAnimations"):
		anim_player = entity.get_node("PuppetAnimations")

	if not anim_player:
		push_warning("⚠️ No se encontró AnimationPlayer en %s" % entity.name)
		return

	start_cinematic(entity)

	if not anim_player.has_animation(anim_name):
		push_warning("⚠️ %s no tiene la animación '%s'" % [entity.name, anim_name])
		return

	anim_player.play(anim_name)

	if wait:
		# esperar a que termine la animación
		await anim_player.animation_finished

	# No liberamos aquí automáticamente, para poder encadenar animaciones


# ===================================
# ⏸️ IDLE CINEMÁTICO (solo player)
# ===================================

func cinematic_idle():
	var player = PlayerManager.get_player()
	if not player:
		return

	player.state_machine.call_deferred("change_to",player.states.Cinematic)

	player.play_animation(player.animations.cinematic_idle + player.previous_direction)
	player.puppet_animations.seek(0.0, true)


# ===================================
# 🏁 FIN DE CINEMÁTICA
# ===================================

func end_cinematic(entity: Node = null):
	if entity == null:
		entity = PlayerManager.get_player()
	if not entity:
		return

	if not _cinematic_entities.has(entity):
		return

	@warning_ignore("unused_variable")
	var info = _cinematic_entities[entity]
	_cinematic_entities.erase(entity)

	# 🔓 Rehabilitar input y movimiento
	if entity.has_method("enable"):
		entity.enable()
	elif entity.has_method("restore_movement"):
		entity.restore_movement()

	# 🎬 Si tiene state_machine y está en Cinematic → ejecutar end() y volver a Idle
	if entity.has_node("STATE MACHINE"):
		var sm := entity.get_node("STATE MACHINE")
		if sm and sm.has_method("change_to") and sm.current_state and "states" in entity:
			var states = entity.states
			if sm.current_state.name == states.Cinematic:
				# ✅ Si el estado actual tiene un método end(), lo ejecutamos manualmente
				if sm.current_state.has_method("end"):
					sm.current_state.end()

				# ✅ Luego cambiamos a Idle de forma limpia
				if "Idle" in states:
					sm.change_to(states.Idle)
					print("🔁 Restaurado estado Idle desde Cinematic para", entity.name)

	# 🎨 Restaurar animación visual Idle
	if entity.has_method("play_animation"):
		if "animations" in entity and "previous_direction" in entity:
			var anims = entity.animations
			var dir = entity.previous_direction
			if "idle" in anims:
				entity.play_animation(anims.idle + dir)

	print("🏁 Cinemática finalizada para:", entity.name)


func end_cinematic_idle():
	var player = PlayerManager.get_player()
	if not player:
		return
	end_cinematic(player)


# ===================================
# 🎬 MOVER ENTIDAD COMO EN RPG MAKER
# ===================================

func move_entity(entity_ref, direction: Vector2, distance: int = 16, speed: float = 60.0):
	var entity := _resolve_entity_ref(entity_ref)
	if not entity:
		push_warning("⚠️ Entidad no encontrada para move_entity: %s" % str(entity_ref))
		return

	start_cinematic(entity)

	var start_pos = entity.global_position
	var target_pos = start_pos + direction.normalized() * distance
	var duration = distance / speed

	if entity.has_method("play_animation"):
		var dir_name = DirectionHelper.get_direction_name(direction)
		if "animations" in entity:
			entity.play_animation(entity.animations.walk + dir_name)

	var tween = entity.create_tween()
	tween.tween_property(entity, "global_position", target_pos, duration).set_trans(Tween.TRANS_LINEAR)
	await tween.finished

	# Idle al terminar
	if entity.has_method("play_animation"):
		if "animations" in entity and "last_direction_name" in entity:
			var dir = entity.last_direction_name
			entity.play_animation(entity.animations.idle + dir)



# ===================================
# ⏱️ Espera genérica
# ===================================

func _wait(duration: float) -> void:
	await get_tree().create_timer(duration).timeout


# --- Añadir estas helpers en cinematic_manager.gd ---

# Resuelve un "entity_ref" que puede ser: Node, NodePath, String (nombre o ruta) o null.
func _resolve_entity_ref(entity_ref) -> Node:
	if entity_ref == null:
		return null
	if entity_ref is Node:
		return entity_ref

	# Si es NodePath -> intentar resolver en la escena actual
	if entity_ref is NodePath:
		var scene = get_tree().current_scene
		if scene:
			return scene.get_node_or_null(entity_ref)

	# Si es String -> primer intento: interpretar como ruta relativa/absoluta en la escena
	if typeof(entity_ref) == TYPE_STRING:
		var scene = get_tree().current_scene
		var sref: String = str(entity_ref)
		if scene:
			# 1️⃣ Intentar como NodePath
			var node := scene.get_node_or_null(sref)
			if node:
				return node

			# 2️⃣ Buscar por nombre (recursivamente) dentro de la escena
			node = scene.find_child(sref, true, false) # ✅ Godot 4 usa find_child
			if node:
				return node

		# 3️⃣ Fallback: buscar en el root y autoloads
		var root := get_tree().root
		if root:
			var n := root.get_node_or_null(sref)
			if n:
				return n

			n = root.find_child(sref, true, false) # ✅ también acá
			if n:
				return n

	# No encontrado
	return null



#------------- EJEMPLOS

## Player mira hacia abajo
#await CinematicManager.play_cinematic(PlayerManager.player, "LookDown", true)

## Elsen reacciona sorprendido
#await CinematicManager.play_cinematic($Elsen, "Surprised_Down", true)

## Ambos terminan la cinemática
#CinematicManager.end_cinematic(PlayerManager.player)
#CinematicManager.end_cinematic($Elsen)

##MOVER NPC
#await CinematicManager.move_entity($Elsen, Vector2.RIGHT, 48, 40.0)
#await CinematicManager.play_cinematic($Elsen, "IdleRight")

##MOVER OBJETO
#var box := $MysteryBox
#await CinematicManager.play_cinematic(box, "Open", true)
#CinematicManager.end_cinematic(box)
