class_name KletusStateBase    extends StateBase

var kletus: Kletus:
	set(value): controlled_node = value
	get: return controlled_node

var animations: PlayerAnimations = PlayerAnimations.new()
