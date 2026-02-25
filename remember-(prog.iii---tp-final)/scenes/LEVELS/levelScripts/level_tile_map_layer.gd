class_name LevelTileMapLayer extends TileMapLayer

@export var tile_size : float = 32
@export var update_bounds : bool = true


func _ready():
	if update_bounds:
		LevelManager.change_tilemap_bounds(_get_tilemap_bounds())
	pass


func _get_tilemap_bounds() -> Array[ Vector2 ]:
	var bounds : Array[ Vector2 ] = []
	bounds.append(
		Vector2( get_used_rect().position * tile_size ) + position
	)
	bounds.append(
		Vector2( get_used_rect().end * tile_size ) + position
	)
	return bounds
