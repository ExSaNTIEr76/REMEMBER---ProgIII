# GameManager.gd
extends Node

# Guarda la zona de cámara activa por escena
var camera_zones_by_scene: Dictionary = {}

#var save_data := {
	#"player_name": PlayerManager.player.character_id,
	#"player_stats": {
		#"hp": PlayerManager.player.stats.CURRENT_HP,
		#"cp": PlayerManager.player.stats.CURRENT_CP,
		#"level": PlayerManager.player.stats.CURRENT_LEVEL
	#},
	#"zone_tag": LevelManager.current_zone,
	#"position": PlayerManager.player.global_position,
	#"time_played": TimeManager.total_seconds,
	#"inventory": InventoryManager.serialize(),
	#"quests": QuestManager.serialize()
#}
