#PlayerManager.gd (escena autoload):

extends Node

const PLAYER_SCENE := preload("res://scenes/CHARACTERS/Puppet/Puppet.tscn")
var INVENTORY_DATA := InventoryData.new()
@export var EQUIPMENT_DATA: EquipmentData

var skin: String = "default"
var is_ill: bool = false

signal camera_shook(trauma: float)
signal interact_pressed
signal stats_changed
signal player_created(player)
signal ill_state_changed

var interact_handled: bool = true
var player: Player = null
var player_spawned: bool = false
var saved_position: Vector2 = Vector2.ZERO
var desired_facing_direction: Vector2 = Vector2.ZERO
var saved_direction: Vector2 = Vector2.DOWN

var _pending_position: Vector2 = Vector2.ZERO
var pending_respawn := false

var current_level: String = ""

var locked_enemy: Enemy = null

var light_persistent: bool = false

const PROMISSIO_SCENE := preload("res://scenes/CHARACTERS/Promissio/promissio.tscn")

# --- Campos serializables para saves / UI ---
var CURRENT_LEVEL: int = 1
var CREDITS: int = 0

var stats: Dictionary =  {
	"MAX_HP": 100,
	"MAX_CP": 50,
	"MAX_EP": 10,

	"CURRENT_HP": 100,
	"CURRENT_CP": 50,
	"CURRENT_EP": 10,

	"cp_regen_rate": 5,
	"cp_regen_interval": 1,

	"ATK": 0,
	"DEF": 3,
	"STR": 5,
	"CON": 3,
	"ESP": 5,
	"LCK": 2,

	"MAX_LEVEL": 99,
	"CURRENT_LEVEL": 1,
	"XP": 0,
	"NEXT_XP": 10,

	"CREDITS": 0,

	"speed": 40.0,
	"running_speed_multiplier": 2.5,

	"CURRENT_ALTERED_STATE": DamageData.StatusEffect.PURE,
}

var base_stats_snapshot: Dictionary = {}

signal hp_changed(value: int)
signal cp_changed(value: int)
signal ep_changed(value: int)

signal player_died
var game_over := false


func _ready() -> void:
	if Engine.has_singleton("LevelManager"):
		var LM = Engine.get_singleton("LevelManager")
		if not LM.level_loaded.is_connected(Callable(self, "_on_level_loaded")):
			LM.level_loaded.connect(Callable(self, "_on_level_loaded"))

	ensure_player()
	await get_tree().create_timer(0.2).timeout
	player_spawned = true

	if EQUIPMENT_DATA:
		EQUIPMENT_DATA.equipment_changed.connect(recalculate_equipment_stats)

	if base_stats_snapshot.is_empty():
		cache_base_stats()

	print("🧠 EquipmentData instance:", EQUIPMENT_DATA.get_instance_id())



#region PLAYER POSITION

# -----------------------
#  Creación / Asegurar player
# -----------------------
func ensure_player() -> void:
	if player and is_instance_valid(player):
		#print("PlayerManager: player already exists.")
		return

	create_player()
	player_spawned = true
	print("PlayerManager: player creado por ensure_player().")


func create_player() -> void:
	if player and not is_instance_valid(player):
		player = null

	player = PLAYER_SCENE.instantiate()
	emit_signal("player_created", player)
	print("PlayerManager: player instanciado (sin parent).")


# -----------------------
#  Level loaded callback
# -----------------------
func _on_level_loaded() -> void:
	print("🧭 PlayerManager: _on_level_loaded")

	var level := get_tree().current_scene
	if not level:
		push_error("❌ No hay nivel actual")
		return

	# 1. Parentar correctamente
	var ysort := level.get_node_or_null("YSORT")
	if ysort:
		if player.get_parent() != ysort:
			if player.get_parent():
				player.get_parent().remove_child(player)
			ysort.add_child(player)
	else:
		if player.get_parent() != level:
			if player.get_parent():
				player.get_parent().remove_child(player)
			level.add_child(player)

	# 3. Determinar posición FINAL
	var final_position: Vector2
	@warning_ignore("unused_variable")
	var used_saved := false

	# Validar saved_position
	if saved_position != Vector2.ZERO and saved_position.y >= 0:
		final_position = saved_position
		used_saved = true
		print("📍 Usando saved_position:", saved_position)
	else:
		var spawns := get_tree().get_nodes_in_group("player_spawn")
		if spawns.size() > 0:
			final_position = spawns[0].global_position
			print("📍 Usando PlayerSpawn:", final_position)
		else:
			final_position = Vector2.ZERO
			print("⚠️ No hay PlayerSpawn, usando (0,0)")

	player.global_position = final_position

	# 3. Limpiar estado
	if not ThothGameState.loading_from_save:
		saved_position = Vector2.ZERO
	pending_respawn = false
	player_spawned = true

	# 4. Facing direction pendiente
	if desired_facing_direction != Vector2.ZERO:
		player.set_facing_direction(desired_facing_direction)
		desired_facing_direction = Vector2.ZERO

	print("✅ Player correctamente restaurado")





# -----------------------
#  API pública para respawn diferido (usada por Level)
# -----------------------
func queue_restore_position(pos: Vector2) -> void:
	saved_position = pos
	pending_respawn = true
	print("PlayerManager: queue_restore_position:", pos)

	if Engine.has_singleton("LevelManager"):
		var LM = Engine.get_singleton("LevelManager")
		if not LM.level_loaded.is_connected(Callable(self, "_on_level_loaded")):
			LM.level_loaded.connect(Callable(self, "_on_level_loaded"), CONNECT_ONE_SHOT)
	else:
		call_deferred("_on_level_loaded")


# -----------------------
#  Teletransporte instantáneo
# -----------------------
func set_player_position(pos: Vector2) -> void:
	if ThothGameState.loading_from_save:
		print("⛔ set_player_position ignorado durante LOAD:", pos)
		return

	player.global_position = pos

#endregion



func get_player() -> Player:
	return player


func add_player_instance() -> void:
	player = PLAYER_SCENE.instantiate()
	emit_signal("player_created", player)
	add_child(player)
	await get_tree().process_frame


func _on_level_loaded_for_respawn() -> void:
	print("🚪 Nivel completamente cargado. Respawn en curso...")
	respawn_player_after_load()
	if saved_direction != Vector2.ZERO:
		player.set_facing_direction(saved_direction)
		print("👁️ Dirección restaurada:", saved_direction)



func _apply_pending_position() -> void:
	if not player or not is_instance_valid(player):
		return
	if _pending_position == Vector2.ZERO:
		return

	player.global_position = _pending_position
	print("📦 Posición restaurada tras LevelLoaded:", _pending_position)
	_pending_position = Vector2.ZERO


func respawn_player_after_load():
	if not ThothGameState.loading_from_save:
		return

	print("🌀 Respawn del player tras carga de partida...")

	# 1. Limpiar player previo
	if player and is_instance_valid(player):
		if CPRegenerator.is_registered(player):
			CPRegenerator.unregister(player)
		player.queue_free()
		await get_tree().process_frame

	# 2. Instanciar nuevo player
	player = PLAYER_SCENE.instantiate()
	emit_signal("player_created", player)


	# 3. Reasignar resource de stats si existe en globals
	# Intentar obtener PlayerGlobalStats top-level primero
	var saved_stats: PlayerGlobalStats = null
	if ThothGameState.game_state.globals.has("PlayerGlobalStats"):
		saved_stats = ThothGameState.game_state.globals["PlayerGlobalStats"]

	# Fallback: si no está top-level, intentar extraerlo desde PlayerManager serializado
	if not saved_stats and ThothGameState.game_state.globals.has("PlayerManager"):
		var pm_entry = ThothGameState.game_state.globals["PlayerManager"]
		if pm_entry.has("variables") and pm_entry["variables"].has("stats"):
			var stats_entry = pm_entry["variables"]["stats"]
			var tmp_stats = PlayerGlobalStats.new()
			ThothDeserializer._deserialize_object(stats_entry, tmp_stats)
			saved_stats = tmp_stats

	if saved_stats:
		player.stats = saved_stats
		print("✅ Stats restauradas ->", player.stats.CREDITS, "cr, Lv.", player.stats.CURRENT_LEVEL)
	else:
		print("⚠️ No se encontró PlayerGlobalStats en el save; usando resource local del player.")


	# 4. Parentar en el nivel actual
	var level := get_tree().current_scene
	if not level:
		push_error("❌ No hay nivel actual durante respawn.")
		return

	var ysort := level.get_node_or_null("YSORT")
	if ysort:
		ysort.add_child(player)
	else:
		level.add_child(player)

	await get_tree().process_frame

	# 5. Restaurar posición
	if saved_position != Vector2.ZERO:
		player.global_position = saved_position
		#print("📦 Player restaurado en posición:", saved_position)
	else:
		var spawns = get_tree().get_nodes_in_group("player_spawn")
		if spawns.size() > 0:
			player.global_position = spawns[0].global_position
			#print("📍 Player colocado en spawn por defecto:", spawns[0].name)
		#else:
			#print("⚠️ No se encontró posición guardada ni spawn.")

	player_spawned = true
	pending_respawn = false

	await get_tree().process_frame

	# 6. Reactivar HUD y CP
	if CPRegenerator.is_registered(player):
		CPRegenerator.unregister(player)
	CPRegenerator.register(player, player.stats.MAX_CP, player.stats.CURRENT_CP, player.stats.cp_regen_rate, 1.0, func(cp): player._on_cp_updated(cp))

	if player.hud:
		await get_tree().create_timer(0.3).timeout
		if player.hud.has_method("show_temporarily"):
			player.hud.show_temporarily(3.5)
		if player.hud.has_method("wait_until_cp_full"):
			player.hud.wait_until_cp_full()

	# 7. Confirmación visual/log
	print("✅ Player respawneado y stats restauradas ->", player.stats.CREDITS, "cr, Lv.", player.stats.CURRENT_LEVEL)




func set_as_parent(_p: Node2D) -> void:
	if not player or not is_instance_valid(player):
		return

	var current_parent = player.get_parent()
	if current_parent == _p:
		return

	if current_parent:
		current_parent.remove_child(player)

	_p.add_child(player)


func unparent_player(_p : Node2D) -> void:
	if not player or not is_instance_valid(player):
		return
	if player.get_parent() == _p:
		_p.remove_child(player)


func interact() -> void:
	interact_handled = false
	interact_pressed.emit()


func shake_camera(trauma: float = 1.0) -> void:
	camera_shook.emit(clamp(trauma, 0.0, 3.0))


func set_facing_direction(direction: Vector2) -> void:
	if direction == Vector2.LEFT:
		$Ciro.flip_h = true
	elif direction == Vector2.RIGHT:
		$Ciro.flip_h = false


func spawn_promissio_near_player():
	if not player or not is_instance_valid(player):
		push_warning("⚠️ No se puede spawnear Promissio: el jugador no está listo.")
		return

	var promissio := PROMISSIO_SCENE.instantiate()

	var level := get_tree().current_scene
	if not level:
		push_error("❌ No hay escena actual.")
		return

	var ysort := level.get_node_or_null("YSORT")
	if not ysort:
		push_error("❌ No se encontró el nodo YSORT en la escena actual.")
		return

	# Deferred para evitar conflictos con el árbol de nodos
	ysort.call_deferred("add_child", promissio)

	# Referencias cruzadas
	player.promissio = promissio
	promissio.player = player

	# Espera a que se agregue al árbol antes de moverlo
	await get_tree().process_frame
	promissio.snap_to_attack_position(player.previous_direction)


func attach_promissio_from_spawn(promissio: Promissio) -> void:
	if not player or not is_instance_valid(player):
		push_warning("⚠️ El jugador no está listo para vincular Promissio.")
		return

	if promissio.get_parent():
		promissio.get_parent().remove_child(promissio)

	var level := get_tree().current_scene
	if not level:
		push_error("❌ No hay escena actual.")
		return

	var ysort := level.get_node_or_null("YSORT")
	if not ysort:
		push_error("❌ No se encontró YSORT en la escena actual.")
		return

	ysort.call_deferred("add_child", promissio)

	player.promissio = promissio
	promissio.player = player

	await get_tree().process_frame
	_apply_equipment_to_promissio(promissio)
	promissio.snap_to_attack_position(player.previous_direction)


func _apply_equipment_to_promissio(promissio: Promissio) -> void:
	if not EQUIPMENT_DATA:
		return

	for slot in ["CONCRETO A", "CONCRETO B"]:
		var item := EQUIPMENT_DATA.get_equipped(slot)

		if item is EquipableItemData and item.symbol_scene:
			promissio.set_concrete_symbol(slot, item.symbol_scene)

	print("🔄 Promissio rehidratado:",
		promissio.concrete_symbol_a,
		promissio.concrete_symbol_b
	)


# [PlayerManager.gd] - Modo de enfoque (target lock) al enemigo más cercano

func toggle_target_lock():
	if locked_enemy and is_instance_valid(locked_enemy):
		if locked_enemy.has_node("MarkAnimations"):
			var anim := locked_enemy.get_node("MarkAnimations")
			if anim.has_animation("mark_off"):
				anim.play("mark_off")

		locked_enemy = null
		print("🔓 Enfoque desactivado")
		return

	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest_enemy: Enemy = null
	var closest_dist := INF

	for enemy in enemies:
		if not is_instance_valid(enemy): continue
		var dist := player.global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = enemy

	if closest_enemy:
		locked_enemy = closest_enemy
		print("🎯 Enfoque activado sobre:", locked_enemy.name)
		if locked_enemy.has_node("MarkAnimations"):
			var anim := locked_enemy.get_node("MarkAnimations")
			if anim.has_animation("mark_on"):
				anim.play("mark_on")


func get_locked_enemy() -> Enemy:
	return locked_enemy


func set_skin(new_skin: String):
	skin = new_skin
	if player and is_instance_valid(player):
		player.skin = new_skin
		player.apply_skin()



func set_ill_state(active: bool):
	is_ill = active
	ill_state_changed.emit()

	if player and is_instance_valid(player):
		player.set_ill_state(active)


func modify_stat(stat: String, amount: int) -> void:
	var pstats = PlayerManager

	if not player or not is_instance_valid(player):
		push_warning("⚠️ No se pudo modificar stat: el jugador no está presente.")
		return
	if not stats:
		push_error("❌ No se encontró el recurso de stats del jugador.")
		return

	match stat:
		"HP":
			pstats.set_current_hp(stats.CURRENT_HP + amount)
			player.emit_signal("health_updated", stats.CURRENT_HP)

		"CP":
			pstats.set_current_cp(stats.CURRENT_CP + amount)
			player.emit_signal("cp_updated", stats.CURRENT_CP)
			if CPRegenerator.is_registered(player):
				CPRegenerator.update_current_cp(player, stats.CURRENT_CP)

		"EP":
			pstats.set_current_ep(stats.CURRENT_EP + amount)
			player.emit_signal("ep_updated", stats.CURRENT_EP)

		_:
			push_warning("⚠️ Stat desconocida: %s" % stat)

	emit_signal("stats_changed")


func restore_health_and_cp() -> void:
	if not player or not is_instance_valid(player):
		push_warning("⚠️ No se pudo restaurar HP/CP: el jugador no está presente.")
		return

	var pstats = PlayerManager

	if not stats:
		push_error("❌ No se encontró el recurso de stats del jugador.")
		return

	# Restaurar HP y CP al máximo
	stats.CURRENT_HP = stats.MAX_HP
	stats.CURRENT_CP = stats.MAX_CP

	# Remover efectos de estado negativos
	var status = stats.CURRENT_ALTERED_STATE
	match status:
		DamageData.StatusEffect.POISON:
			clear_status()
		DamageData.StatusEffect.PARALYSIS:
			clear_status()
		DamageData.StatusEffect.BLINDNESS:
			clear_status()
		DamageData.StatusEffect.MIGRAINE:
			clear_status()
		DamageData.StatusEffect.FRAILTY:
			clear_status()
		_:
			pass

	# Refrescar regenerador de CP
	if CPRegenerator.is_registered(player):
		CPRegenerator.update_current_cp(player, stats.CURRENT_CP)

	# Emitir señales para actualizar HUDs
	pstats.set_current_hp(stats.MAX_HP)
	pstats.set_current_cp(stats.MAX_CP)
	player.emit_signal("health_updated", stats.CURRENT_HP)
	player.emit_signal("cp_updated", stats.CURRENT_CP)

	#print("💖 Salud y CP restaurados. El jugador está en estado PURE.")


func clear_status():
	if not player or not is_instance_valid(player):
		push_warning("⚠️ No se puede limpiar el estado: el jugador no está presente.")
		return

	var pstats = PlayerManager

	if not stats:
		push_error("❌ No se encontró el recurso de stats del jugador.")
		return

	#print("💬 Estado actual antes de limpiar:", stats.CURRENT_ALTERED_STATE)
	pstats.set_status(DamageData.StatusEffect.PURE)
	#print("✨ Estado alterado negativo eliminado.")


func set_hp(value: int):
	stats.CURRENT_HP = clamp(value, 0, stats.MAX_HP)
	emit_signal("stats_changed")


func set_cp(value: int):
	stats.CURRENT_CP = clamp(value, 0, stats.MAX_CP)
	emit_signal("stats_changed")


func set_ep(value: int):
	stats.CURRENT_EP = clamp(value, 0, stats.MAX_EP)
	emit_signal("stats_changed")


# ---------- Helpers para manejar el dict de stats ----------
func _ensure_key(key: String, default_value = null) -> void:
	if not stats.has(key):
		stats[key] = default_value


func get_stat(key: String):
	return stats.get(key, null)


func set_stat(key: String, value) -> void:
	stats[key] = value
	emit_signal("stats_changed")

# Getters especializados (por claridad / compatibilidad)
func get_max_hp() -> int: return int(get_stat("MAX_HP"))
func get_current_hp() -> int: return int(get_stat("CURRENT_HP"))
func get_max_cp() -> int: return int(get_stat("MAX_CP"))
func get_current_cp() -> int: return int(get_stat("CURRENT_CP"))
func get_max_ep() -> int: return int(get_stat("MAX_EP"))
func get_current_ep() -> int: return int(get_stat("CURRENT_EP"))
func get_cp_regen_rate() -> float: return float(get_stat("cp_regen_rate"))
func get_current_altered_state(): return get_stat("CURRENT_ALTERED_STATE")


# Setters especializados (usan set_stat para emitir)
func set_current_hp(value: int) -> void:
	stats.CURRENT_HP = clamp(value, 0, stats.MAX_HP)
	hp_changed.emit(stats.CURRENT_HP)
	stats_changed.emit()


func set_current_cp(value: int) -> void:
	stats.CURRENT_CP = clamp(value, 0, stats.MAX_CP)
	cp_changed.emit(stats.CURRENT_CP)
	stats_changed.emit()


func set_current_ep(value: int) -> void:
	stats.CURRENT_EP = clamp(value, 0, stats.MAX_EP)
	ep_changed.emit(stats.CURRENT_EP)
	stats_changed.emit()


func set_status(value: DamageData.StatusEffect) -> void:
	set_stat("CURRENT_ALTERED_STATE", value)


func set_credits(value: int) -> void:
	set_stat("CREDITS", max(0, int(value)))


func get_stats_snapshot() -> Dictionary:
	return stats.duplicate(true)


func _modifier_type_to_stat_key(t: EquipableItemModifier.Type) -> String:
	match t:
		EquipableItemModifier.Type.HEALTH:        return "MAX_HP"
		EquipableItemModifier.Type.ENERGY:        return "MAX_CP"
		EquipableItemModifier.Type.COMPETENCE:    return "MAX_EP"
		EquipableItemModifier.Type.ATTACK:        return "ATK"
		EquipableItemModifier.Type.DEFENSE:       return "DEF"
		EquipableItemModifier.Type.STRENGTH:      return "STR"
		EquipableItemModifier.Type.CONSTITUTION:  return "CON"
		EquipableItemModifier.Type.ESPRIT:        return "ESP"
		EquipableItemModifier.Type.LUCK:          return "LCK"
		EquipableItemModifier.Type.SPEED:         return "speed"
		_:
			return ""

func get_preview_stats(item: EquipableItemData, slot_name: String) -> Dictionary:
	if base_stats_snapshot.is_empty():
		cache_base_stats()

	# 1. Parte de stats base
	var preview := base_stats_snapshot.duplicate(true)

	# 2. Aplica equipment ACTUAL
	for slot in EQUIPMENT_DATA.equipped.keys():
		var equipped_item := EQUIPMENT_DATA.get_equipped(slot)
		if equipped_item is EquipableItemData:
			_apply_item_modifiers(preview, equipped_item)

	# 3. Quita lo que esté equipado en ese slot (si hay)
	var current := EQUIPMENT_DATA.get_equipped(slot_name)
	if current is EquipableItemData:
		_remove_item_modifiers(preview, current)

	# 4. Aplica el item hover
	_apply_item_modifiers(preview, item)

	return preview


@warning_ignore("shadowed_variable")
func _apply_item_modifiers(stats: Dictionary, item: EquipableItemData) -> void:
	for mod in item.modifiers:
		var key := _modifier_type_to_stat_key(mod.type)
		if key != "" and stats.has(key):
			stats[key] += mod.value


@warning_ignore("shadowed_variable")
func _remove_item_modifiers(stats: Dictionary, item: EquipableItemData) -> void:
	for mod in item.modifiers:
		var key := _modifier_type_to_stat_key(mod.type)
		if key != "" and stats.has(key):
			stats[key] -= mod.value


func recalculate_equipment_stats():
	if base_stats_snapshot.is_empty():
		cache_base_stats()

	# 1. Restaurar stats base
	stats = base_stats_snapshot.duplicate(true)

	# 2. Aplicar modifiers de todos los ítems equipados
	for slot in EQUIPMENT_DATA.equipped.keys():
		var item := EQUIPMENT_DATA.get_equipped(slot)
		if item is EquipableItemData:
			for mod in item.modifiers:
				var key := _modifier_type_to_stat_key(mod.type)
				if key != "" and stats.has(key):
					stats[key] += mod.value

	# 3. Clamp de valores actuales
	stats.CURRENT_HP = clamp(stats.CURRENT_HP, 0, stats.MAX_HP)
	stats.CURRENT_CP = clamp(stats.CURRENT_CP, 0, stats.MAX_CP)
	stats.CURRENT_EP = clamp(stats.CURRENT_EP, 0, stats.MAX_EP)

	stats_changed.emit()


# Copia/parsea un dict (por load)
func apply_stats_from_dict(d: Dictionary) -> void:
	if not d:
		return

	var INT_KEYS = [
		"MAX_HP","MAX_CP","MAX_EP",
		"CURRENT_HP","CURRENT_CP","CURRENT_EP",
		"ATK","STR","DEF","CON","ESP","LCK",
		"CURRENT_LEVEL","XP","NEXT_XP",
		"CREDITS","MAX_LEVEL",
	]

	for k in d.keys():
		var v = d[k]

		if k in INT_KEYS:
			stats[k] = int(v)
		else:
			stats[k] = v

	emit_signal("stats_changed")


func cache_base_stats():
	base_stats_snapshot = stats.duplicate(true)


func reset_stats() -> void:
	print("🔁 PlayerManager reset")

	saved_position = Vector2.ZERO
	desired_facing_direction = Vector2.ZERO
	saved_direction = Vector2.DOWN
	current_level = ""

	# Reset stats base
	stats = {
		"MAX_HP": 100,
		"MAX_CP": 50,
		"MAX_EP": 10,
		"CURRENT_HP": 100,
		"CURRENT_CP": 50,
		"CURRENT_EP": 10,
		"cp_regen_rate": 5,
		"cp_regen_interval": 1,
		"ATK": 0,
		"DEF": 3,
		"STR": 5,
		"CON": 3,
		"ESP": 5,
		"LCK": 2,
		"MAX_LEVEL": 99,
		"CURRENT_LEVEL": 1,
		"XP": 0,
		"NEXT_XP": 10,
		"CREDITS": 0,
		"speed": 40.0,
		"running_speed_multiplier": 2.5,
		"CURRENT_ALTERED_STATE": DamageData.StatusEffect.PURE,
	}

	stats_changed.emit()


func learn_combat() -> void:
	for state in [
		player.states.AttackA, player.states.AttackB,
		player.states.Blocking,
	]:
		StateUnlockManager.learn_state(player.character_id, state)


func on_player_died():
	if game_over:
		return
	if player and is_instance_valid(player):
		player.disable()

	game_over = true
	print( "💀 SWEET DREAMS..." )
	player_died.emit()
