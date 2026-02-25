@icon("res://addons/proyect_icons/hurtbox_proyect_icon.png")

class_name Hurtbox    extends Area2D

# Receive damage:

func _ready():
	set_deferred( "monitorable", true )
