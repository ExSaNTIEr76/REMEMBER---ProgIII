class_name SucreStateBase    extends StateBase

var sucre: Sucre:
	set(value): controlled_node = value
	get: return controlled_node

var animations: PlayerAnimations = PlayerAnimations.new()
