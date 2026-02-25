class_name PlayerCamera    extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready():
	LevelManager.tilemap_bounds_changed.connect( _update_limits )
	_update_limits( LevelManager.current_tilemap_bounds )
	pass # Replace with function body.


func _update_limits( bounds : Array[ Vector2 ] ) -> void:
	if bounds == []:
		return
	limit_left = int( bounds[0].x )
	limit_top = int( bounds[0].y )
	limit_right = int( bounds[1].x )
	limit_bottom = int( bounds[1].y )
	pass


func shake( duration := 0.2, base_strength := 6.0, damage := 1) :
	var tween := get_tree().create_tween()

	# ⚡ Escala la fuerza según el daño recibido
	var strength = clamp ( base_strength * ( damage / 20.0 ), 2.0, 8.0 )

	for i in range( int ( duration / 0.05 ) ):
		var offset_variation = Vector2(
			randf_range( -1.0, 1.0 ),
			randf_range( -1.0, 1.0 )
		) * strength

		tween.tween_property( self, "offset", offset_variation, 0.025).set_trans(Tween.TRANS_SINE )
		tween.tween_property( self, "offset", Vector2.ZERO, 0.025).set_trans(Tween.TRANS_SINE )

	await tween.finished
	offset = Vector2.ZERO
