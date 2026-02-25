class_name FootstepTilemap    extends TileMapLayer    #by DashNothing


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FootstepSoundManager.tilemaps.push_back( self )
