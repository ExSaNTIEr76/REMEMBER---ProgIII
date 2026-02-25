#spawner.gd (escena autoload):
extends Node2D

var ysort_node: Node = null
@onready var common_ghost_scene: PackedScene = preload( "res://scenes/ENEMIES/Spectres/common_spectre/common_spectre.tscn" )


func _ready():
	self.y_sort_enabled = true
	PlayerManager.set_as_parent(self)

	# Buscamos el Y-SORT correctamente desde la escena actual
	var level := get_tree().current_scene
	if level:
		ysort_node = level.get_node_or_null("YSORT")
		if not ysort_node:
			push_error("❌ No se encontró el nodo YSORT en la escena actual.")
	else:
		push_error("❌ No hay escena actual cargada.")


func spawn_common_ghost() -> void:
	PlayerManager.restore_health_and_cp()
	set_spawn( Vector2( 750, 128 ) )
	
	#set_spawn( Vector2( 690, 170 ) )
	#set_spawn( Vector2( 980, 170 ) )
	#set_spawn( Vector2( 830, 355 ) )


func give_items() -> void:
	InventoryManager.give_all()
	GlobalConditions.special_2_slot_obtained = true
	GlobalConditions.first_symbol_count = 2

func give_enough_items() -> void:
	InventoryManager.give(1, 5)
	InventoryManager.give(3, 5)
	
	InventoryManager.give(180, 1)
	InventoryManager.give(182, 1)
	InventoryManager.give(184, 1)
	
	GlobalConditions.first_symbol_count = 2


func set_spawn(_position: Vector2) -> void:
	if not ysort_node:
		push_warning("⚠️ Y-SORT aún no está listo, no se puede spawnear.")
		return

	var common_ghost = common_ghost_scene.instantiate()
	ysort_node.add_child(common_ghost)
	common_ghost.global_position = _position
