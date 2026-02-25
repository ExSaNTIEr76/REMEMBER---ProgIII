extends Node2D

@onready var ysort_node := $"Y-SORT"
@onready var common_ghost_scene: PackedScene = preload("res://scenes/ENEMIES/Spectres/common_spectre/common_spectre.tscn")

func _ready():
	spawn_common_ghost(Vector2(75, 120))
	spawn_common_ghost(Vector2(400, 200))

@warning_ignore("shadowed_variable_base_class")
func spawn_common_ghost(position: Vector2):
	var common_ghost = common_ghost_scene.instantiate()
	ysort_node.add_child(common_ghost)  # 👈 ahora se agrega dentro del YSort
	common_ghost.global_position = position
