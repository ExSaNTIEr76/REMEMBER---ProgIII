class_name ElsenStateBase    extends StateBase

var elsen:Elsen:
	set (value):
		controlled_node = value
	get:
		return controlled_node

var states: ElsenStateNames = ElsenStateNames.new()
var animations: ElsenAnimations = ElsenAnimations.new()
