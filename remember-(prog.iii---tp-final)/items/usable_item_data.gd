class_name UsableItemData    extends ItemData

@export var effects : Array[ ItemEffect ]

func use() -> bool:
	if effects.size() == 0:
		return false
	
	for e in effects:
		if e:
			e.use()
	return true
