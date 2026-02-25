@icon("res://addons/proyect_icons/promissio_state_proyect_icon.png")

class_name PromissioStateSleeping   extends PromissioStateBase

func start():
	controlled_node.animation_player.play(animations.Sleeping)
