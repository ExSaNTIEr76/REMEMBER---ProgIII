#teleport_manager.gd:

extends Node

enum SIDE { BOTTOM, RIGHT, LEFT, TOP }

## Teleporta al jugador a una parte de la misma escena o carga una nueva.
func teleport_player(
	target_node_path: NodePath,
	offset: Vector2 = Vector2.ZERO,
	direction: SIDE = SIDE.BOTTOM,
	scene_path: String = "",
	use_fade: bool = true
) -> void:

	match direction:
		SIDE.BOTTOM:
			PlayerManager.desired_facing_direction = Vector2.DOWN
		SIDE.RIGHT:
			PlayerManager.desired_facing_direction = Vector2.RIGHT
		SIDE.LEFT:
			PlayerManager.desired_facing_direction = Vector2.LEFT
		SIDE.TOP:
			PlayerManager.desired_facing_direction = Vector2.UP

	PlayerManager.player.set_facing_direction(PlayerManager.desired_facing_direction)

	# 🔹 Si se teletransporta a otra escena
	if scene_path != "":
		LevelManager.target_transition = "DialogueDecisionVirtual"
		LevelManager.position_offset = offset

		await get_tree().process_frame
		await LevelManager.load_new_level(scene_path, LevelManager.target_transition, offset, use_fade)

		await get_tree().process_frame

		var transition_node := get_node_or_null(target_node_path)
		if transition_node and transition_node is LevelTransition:
			GameManager.camera_zones_by_scene["__override__"] = transition_node.initial_camera_zone
			AudioManager.play_sfx(transition_node.SFX_IN, transition_node.pitch, transition_node.volume_db)
		#else:
		#	push_warning("⚠️ Nodo de transición no encontrado: %s" % target_node_path)

	# 🔹 Si es en la misma escena
	var target := get_node_or_null(target_node_path)
	if target == null:
		push_warning("🔍 Nodo de destino no encontrado: %s" % target_node_path)
		return

	PlayerManager.set_player_position(target.global_position + offset)
	print("📦 Player teleportado a: ", target.global_position + offset)
