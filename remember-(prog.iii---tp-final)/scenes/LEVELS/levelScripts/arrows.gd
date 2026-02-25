class_name Arrows    extends TileMapLayer

@onready var arrows: Arrows = $"."

var passport = GlobalConditions.tramPassport

func _ready():
	show_arrows()

func show_arrows() -> void:
	if passport >= 1:
		arrows.show()
	else:
		arrows.hide()
