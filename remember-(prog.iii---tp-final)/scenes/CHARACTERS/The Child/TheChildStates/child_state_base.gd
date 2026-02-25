class_name ChildStateBase    extends StateBase

var the_child: TheChild:
	set(value): controlled_node = value
	get: return controlled_node

var animations: PlayerAnimations = PlayerAnimations.new()
