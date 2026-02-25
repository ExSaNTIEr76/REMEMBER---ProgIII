@icon("res://addons/proyect_icons/promissio_state_proyect_icon.png")

class_name PromissioStateBase extends StateBase

var promissio:Promissio:
	set (value):
		controlled_node = value
	get:
		return controlled_node

var animations := PromissioAnimations.new()
var states := PromissioStateNames.new()
