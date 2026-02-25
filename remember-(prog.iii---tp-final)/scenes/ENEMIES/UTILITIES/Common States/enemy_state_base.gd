class_name EnemyStateBase extends StateBase

var enemy:Enemy:
	set (value):
		controlled_node = value
	get:
		return controlled_node

var states: EnemyStateNames = EnemyStateNames.new()
var animations: EnemyAnimations = EnemyAnimations.new()
