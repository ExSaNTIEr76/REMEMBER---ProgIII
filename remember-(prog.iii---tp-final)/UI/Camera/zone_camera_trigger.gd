#extends Area2D
#
#@export var target_camera_path: NodePath
#@onready var target_camera: Camera2D = null
#
#func _ready():
	#target_camera = get_node_or_null(target_camera_path)
#
#func _on_area_entered(body):
	#if body.is_in_group("player") and target_camera:
		#var manager = get_tree().get_first_node_in_group("CameraManagers")
		#if manager:
			#manager.transition_to(target_camera)
