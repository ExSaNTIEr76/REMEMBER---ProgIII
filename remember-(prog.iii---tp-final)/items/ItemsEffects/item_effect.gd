class_name ItemEffect    extends Resource

@export var use_description : String

func can_use() -> bool:
	return true  # por defecto, usable siempre

func use() -> void:
	pass
