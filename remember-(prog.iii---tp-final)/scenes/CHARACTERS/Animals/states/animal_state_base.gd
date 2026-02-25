class_name AnimalStateBase    extends StateBase

var animal:Animal:
	set (value):
		controlled_node = value
	get:
		return controlled_node

var states: AnimalStateNames = AnimalStateNames.new()
var animations: AnimalAnimations = AnimalAnimations.new()
