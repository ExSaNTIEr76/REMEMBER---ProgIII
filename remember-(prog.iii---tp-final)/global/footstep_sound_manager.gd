#FootstepSoundManager.gd (autoload) - by DashNothing

extends Node


var tilemaps: Array[TileMapLayer] = []

const footstep_sounds = {
	"metal": [
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_metal_1.ogg"),
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_metal_2.ogg"),
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_metal_3.ogg"),
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_metal_4.ogg"),
	],
	"stone": [
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_stone_1.ogg"),
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_stone_2.ogg"),
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_stone_3.ogg"),
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_stone_4.ogg"),
	],
	"puddle": [
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_puddle_1.ogg"),
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_puddle_2.ogg"),
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_puddle_3.ogg"),
		preload("res://audio/SFX/Puppet SFX/footsteps/Sfx_Footstep_puddle_4.ogg"),
	]
}

func play_footstep(position: Vector2):
	var valid_tilemaps: Array[TileMapLayer] = []

	for tilemap in tilemaps:
		if is_instance_valid(tilemap):
			valid_tilemaps.append(tilemap)

	tilemaps = valid_tilemaps

	var tile_data = []
	for tilemap in tilemaps:
		var tile_position = tilemap.local_to_map(position)
		var data = tilemap.get_cell_tile_data(tile_position)
		if data:
			tile_data.push_back(data)

	if tile_data.size() > 0:
		var tile_type = tile_data.back().get_custom_data("footstep_sound")

		if footstep_sounds.has(tile_type):
			var audio_player = AudioStreamPlayer2D.new()
			audio_player.stream = footstep_sounds[tile_type].pick_random()
			get_tree().root.add_child(audio_player)
			audio_player.global_position = position
			audio_player.play()
			await audio_player.finished
			audio_player.queue_free()
