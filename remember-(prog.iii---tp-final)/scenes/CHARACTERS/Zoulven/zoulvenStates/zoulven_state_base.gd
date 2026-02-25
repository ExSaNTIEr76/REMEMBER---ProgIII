class_name ZoulvenStateBase    extends StateBase

var zoulven: Zoulven:
	set(value): controlled_node = value
	get: return controlled_node

var animations: PlayerAnimations = PlayerAnimations.new()
