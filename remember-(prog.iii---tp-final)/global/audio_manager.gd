#audio_manager.gd (autoload):

extends Node

var _original_bus_volumes := {}
var _startup_muted := false

# 🎵 Música
var music_audio_player_count: int = 2
var current_music_player: int = 0
var music_players: Array[ AudioStreamPlayer ] = []
var music_bus: String = "Music"

# Música default del nivel (persistente mientras dure el nivel)
var default_music_stream: AudioStream = null
var default_music_volume: float = 0.0
var default_music_pitch: float = 1.0

var _paused_music_stream: AudioStream = null
var _paused_music_position: float = 0.0
var music_fade_duration: float = 1.0

var _paused_music_volume: float = 0.0
var _paused_music_pitch: float = 1.0

var default_music_position: float = 0.0

# 🎫 Ambiente
var ambient_audio_player_count: int = 2
var current_ambient_player: int = 0
var ambient_players: Array[ AudioStreamPlayer ] = []
var ambient_bus: String = "Ambient"
var ambient_fade_duration: float = 0.5

# ✨ SFX
var sfx_players: Array[AudioStreamPlayer] = []
var sfx_bus: String = "SFX"
var sfx_max_count: int = 4

# 🗣️ Voces
var voice_players: Array[AudioStreamPlayer] = []
var voice_bus: String = "Voices"
var voice_max_count: int = 4

var mute_next_hover := false
var mute_next_press := false

var is_in_combat: bool = false

#---------------------------------------------------------------------------------------------------------------------#


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# 🎵 MÚSICA
	for i in music_audio_player_count:
		var music_player = AudioStreamPlayer.new()
		music_player.bus = music_bus
		music_player.volume_db = -40
		add_child(music_player)
		music_players.append(music_player)

	# 🎫 Ambient
	for i in ambient_audio_player_count:
		var ambient_player = AudioStreamPlayer.new()
		ambient_player.bus = ambient_bus
		ambient_player.volume_db = -40
		add_child(ambient_player)
		ambient_players.append(ambient_player)

	# ✨ SFX
	for i in sfx_max_count:
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = sfx_bus
		sfx_player.volume_db = 0
		add_child(sfx_player)
		sfx_players.append(sfx_player)

	# 🗣️ Voices
	for i in voice_max_count:
		var voice_player = AudioStreamPlayer.new()
		voice_player.bus = voice_bus
		voice_player.volume_db = 0
		add_child(voice_player)
		voice_players.append(voice_player)


#---------------------------------------------------------------------------------------------------------------------#


# MÚSICA
func play_music(audio: AudioStream, pitch: float = 1.0, volume_db: float = 0.0, allow_layer: bool = false) -> void:
	if not allow_layer:
		for music_player in music_players:
			if music_player.playing and music_player.stream != audio:
				fade_out_and_stop(music_player, music_fade_duration)

	# Buscar si ya existe ese track sonando (para evitar duplicados exactos)
	for music_player in music_players:
		if music_player.stream == audio and music_player.playing:
			music_player.pitch_scale = pitch
			var tween := create_tween()
			tween.tween_property(music_player, "volume_db", volume_db, music_fade_duration)
			return

	# Buscar un slot libre
	for music_player in music_players:
		if not music_player.playing:
			_configure_and_play(music_player, audio, pitch, volume_db)
			return

	if allow_layer:
		# Modo layering
		var temp_player := AudioStreamPlayer.new()
		temp_player.bus = music_bus
		add_child(temp_player)
		_configure_and_play(temp_player, audio, pitch, volume_db)
		temp_player.finished.connect(func(): temp_player.queue_free())
	else:
		# Modo clásico crossfade
		current_music_player = (current_music_player + 1) % music_audio_player_count
		var new_player := music_players[current_music_player]
		var old_player := music_players[(current_music_player + 1) % music_audio_player_count]
		new_player.stream = audio
		new_player.pitch_scale = pitch
		new_player.volume_db = -40
		play_and_fade_in(new_player, volume_db, music_fade_duration)
		fade_out_and_stop(old_player, music_fade_duration)


func pause_current_music():
	var current_player := music_players[current_music_player]
	if current_player.playing:
		_paused_music_stream = current_player.stream
		_paused_music_position = current_player.get_playback_position()
		_paused_music_volume = current_player.volume_db
		_paused_music_pitch = current_player.pitch_scale
		current_player.stop()


func resume_previous_music():
	if _paused_music_stream:
		var new_player := music_players[current_music_player]
		new_player.stream = _paused_music_stream
		new_player.pitch_scale = _paused_music_pitch
		new_player.play(_paused_music_position)
		new_player.volume_db = -40

		var tween := create_tween()
		tween.tween_property(
			new_player,
			"volume_db",
			_paused_music_volume,
			music_fade_duration
		)

		# Limpieza solo parcial: mantenemos el "default" del Level si corresponde
		_paused_music_stream = null
		_paused_music_position = 0.0
		_paused_music_volume = 0.0
		_paused_music_pitch = 1.0


func fade_out_current_music(duration: float = 0.8) -> void:
	var current_player := music_players[current_music_player]
	if current_player.playing:
		var tween := create_tween()
		tween.tween_property(current_player, "volume_db", -40, duration)
		tween.connect("finished", Callable(self, "_on_fade_out_music_finished").bind(current_player))


func fade_out_and_pause_current_music(duration: float = 1.0) -> void:
	var current_player := music_players[current_music_player]
	if current_player.playing:
		_paused_music_stream = current_player.stream
		_paused_music_position = current_player.get_playback_position()
		_paused_music_volume = current_player.volume_db
		_paused_music_pitch = current_player.pitch_scale

		var tween := create_tween()
		tween.tween_property(current_player, "volume_db", -40, duration)
		await tween.finished
		current_player.stop()


func play_music_path(path: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var audio = load(path)
	if audio is AudioStream:
		play_music(audio, pitch, volume_db)


func fade_out_music_path(path: String, duration: float = 0.5) -> void:
	var target_audio := load(path)
	if not (target_audio is AudioStream):
		push_warning("❌ El recurso '%s' no es un AudioStream válido." % path)
		return

	for music_player in music_players:
		if music_player.stream == target_audio and music_player.playing:
			var tween := create_tween()
			tween.tween_property(music_player, "volume_db", -40, duration)
			tween.connect("finished", Callable(self, "_on_fade_out_finished").bind(music_player))
			print("🌙 Fade out iniciado para:", path)

#---------------------------------------------------------------------------------------------------------------------#


# 🎫 AMBIENTE
func play_ambient(audio: AudioStream, pitch: float = 1.0, volume_db: float = 0.0, allow_layer: bool = false) -> void:
	if not allow_layer:
		for ambient_player in ambient_players:
			if ambient_player.playing and ambient_player.stream != audio:
				fade_out_and_stop(ambient_player, ambient_fade_duration)

	# Buscar si ya existe ese track sonando (para evitar duplicados exactos)
	for ambient_player in ambient_players:
		if ambient_player.stream == audio and ambient_player.playing:
			ambient_player.pitch_scale = pitch
			var tween := create_tween()
			tween.tween_property(ambient_player, "volume_db", volume_db, ambient_fade_duration)
			return

	# Buscar un slot libre
	for ambient_player in ambient_players:
		if not ambient_player.playing:
			_configure_and_play(ambient_player, audio, pitch, volume_db)
			return

	if allow_layer:
		# Modo layering
		var temp_player := AudioStreamPlayer.new()
		temp_player.bus = ambient_bus
		add_child(temp_player)
		_configure_and_play(temp_player, audio, pitch, volume_db)
		temp_player.finished.connect(func(): temp_player.queue_free())
	else:
		# Modo clásico crossfade
		current_ambient_player = (current_ambient_player + 1) % ambient_audio_player_count
		var new_player := ambient_players[current_ambient_player]
		var old_player := ambient_players[(current_ambient_player + 1) % ambient_audio_player_count]
		new_player.stream = audio
		new_player.pitch_scale = pitch
		new_player.volume_db = -40
		play_and_fade_in(new_player, volume_db, ambient_fade_duration)
		fade_out_and_stop(old_player, ambient_fade_duration)


func fade_out_current_ambient(duration: float = 0.5) -> void:
	var current_player := ambient_players[current_ambient_player]
	if current_player.playing:
		var tween := create_tween()
		tween.tween_property(current_player, "volume_db", -40, duration)
		tween.connect("finished", Callable(self, "_on_fade_out_ambient_finished").bind(current_player))


func play_ambient_path(path: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var audio = load(path)
	if audio is AudioStream:
		play_ambient(audio, pitch, volume_db)

#---------------------------------------------------------------------------------------------------------------------#


# ✨ SFX
func play_sfx(audio: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not audio:
		return

	# Busca un player libre en el pool
	for sfx_player in sfx_players:
		if not sfx_player.playing:
			_configure_and_play(sfx_player, audio, pitch, volume_db)
			return

	# Si no hay libres, crea un player temporal "fire and forget"
	var temp_player := AudioStreamPlayer.new()
	temp_player.bus = sfx_bus
	add_child(temp_player)
	_configure_and_play(temp_player, audio, pitch, volume_db)

	# Cuando termina el sonido, se borra solo
	temp_player.finished.connect(func():
		temp_player.queue_free()
	)


func play_sfx_path(path: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var audio = load(path)
	if audio is AudioStream:
		play_sfx(audio, pitch, volume_db)


func fade_out_sfx_path(path: String, duration: float = 0.5) -> void:
	var target_audio := load(path)
	if not (target_audio is AudioStream):
		push_warning("❌ El recurso '%s' no es un AudioStream válido." % path)
		return

	for sfx_player in sfx_players:
		if sfx_player.stream == target_audio and sfx_player.playing:
			var tween := create_tween()
			tween.tween_property(sfx_player, "volume_db", -40, duration)
			tween.connect("finished", Callable(self, "_on_fade_out_finished").bind(sfx_player))
			print("🌙 Fade out iniciado para:", path)


func stop_sfx_path(path: String) -> void:
	var target_audio := load(path)
	if not (target_audio is AudioStream):
		push_warning("❌ El recurso '%s' no es un AudioStream válido." % path)
		return

	for sfx_player in sfx_players:
		if sfx_player.stream == target_audio and sfx_player.playing:
			sfx_player.stop()
			sfx_player.stream = null
			print("🔇 SFX detenido:", path)


func mute_hover_once():
	mute_next_hover = true


func _consume_hover_mute() -> bool:
	if mute_next_hover:
		mute_next_hover = false
		return true
	return false


func mute_press_once():
	mute_next_press = true


func _consume_press_mute() -> bool:
	if mute_next_press:
		mute_next_press = false
		return true
	return false

#---------------------------------------------------------------------------------------------------------------------#


# 🗣️ VOCES
func play_voice(audio: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not audio:
		return

	for voice_player in voice_players:
		if not voice_player.playing:
			_configure_and_play(voice_player, audio, pitch, volume_db)
			return

	var temp_player := AudioStreamPlayer.new()
	temp_player.bus = voice_bus
	add_child(temp_player)
	_configure_and_play(temp_player, audio, pitch, volume_db)
	temp_player.finished.connect(func():
		temp_player.queue_free()
	)


func play_voice_path(path: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	var audio = load(path)
	if audio is AudioStream:
		play_voice(audio, pitch, volume_db)


func stop_voice_path(path: String) -> void:
	var target_audio := load(path)
	if not (target_audio is AudioStream):
		push_warning("❌ El recurso '%s' no es un AudioStream válido." % path)
		return
	for voice_player in voice_players:
		if voice_player.stream == target_audio and voice_player.playing:
			voice_player.stop()
			voice_player.stream = null
			print("🔇 VOICE detenido:", path)


func fade_out_voice_path(path: String, duration: float = 0.5) -> void:
	var target_audio := load(path)
	if not (target_audio is AudioStream):
		push_warning("❌ El recurso '%s' no es un AudioStream válido." % path)
		return
	for voice_player in voice_players:
		if voice_player.stream == target_audio and voice_player.playing:
			var tween := create_tween()
			tween.tween_property(voice_player, "volume_db", -40, duration)
			tween.connect("finished", Callable(self, "_on_fade_out_finished").bind(voice_player))
			print("🌙 Fade out iniciado para VOICE:", path)


#---------------------------------------------------------------------------------------------------------------------#


# ⚙️ UTILIDADES

func mute_all_buses():
	if _startup_muted:
		return
	
	_original_bus_volumes.clear()
	
	var buses := ["Music", "Ambient", "SFX", "Voices"]
	
	for bus_name in buses:
		var index := AudioServer.get_bus_index(bus_name)
		if index != -1:
			_original_bus_volumes[bus_name] = AudioServer.get_bus_volume_db(index)
			AudioServer.set_bus_volume_db(index, -80)
	
	_startup_muted = true


func unmute_all_buses(duration: float = 1.5):
	if not _startup_muted:
		return
	
	for bus_name in _original_bus_volumes.keys():
		var index := AudioServer.get_bus_index(bus_name)
		var target_volume = _original_bus_volumes[bus_name]
		
		if index != -1:
			var tween := create_tween()
			tween.tween_method(
				func(v): AudioServer.set_bus_volume_db(index, v),
				-80,
				target_volume,
				duration
			)
	
	_startup_muted = false


func play_and_fade_in(player: AudioStreamPlayer, target_volume: float, duration: float) -> void:
	player.play(0)
	var tween := create_tween()
	tween.tween_property(player, "volume_db", target_volume, duration)


func fade_out_and_stop(player: AudioStreamPlayer, duration: float) -> void:
	var old_stream := player.stream
	var tween := create_tween()
	tween.tween_property(player, "volume_db", -40, duration)
	await tween.finished
	if player.stream == old_stream:
		player.stop()


func _on_fade_out_music_finished(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null


func _on_fade_out_ambient_finished(player: AudioStreamPlayer) -> void:
	player.stop()
	player.stream = null


func _on_fade_out_finished(sfx_player: AudioStreamPlayer) -> void:
	sfx_player.stop()
	sfx_player.stream = null


func _configure_and_play(player: AudioStreamPlayer, audio: AudioStream, pitch: float, volume_db: float) -> void:
	player.stream = audio
	player.pitch_scale = pitch
	player.volume_db = volume_db
	player.play()


# 🎚️ Limpieza total de audio al cambiar de escena
func fade_out_all(duration: float = 1.0) -> void:
	# Música
	for music_player in music_players:
		if music_player.playing:
			var tween := create_tween()
			tween.tween_property(music_player, "volume_db", -40, duration)
			tween.connect("finished", Callable(self, "_on_fade_out_music_finished").bind(music_player))

	# Ambientes
	for ambient_player in ambient_players:
		if ambient_player.playing:
			var tween := create_tween()
			tween.tween_property(ambient_player, "volume_db", -40, duration)
			tween.connect("finished", Callable(self, "_on_fade_out_ambient_finished").bind(ambient_player))

	# Voces
	for voice_player in voice_players:
		if voice_player.playing:
			var tween := create_tween()
			tween.tween_property(voice_player, "volume_db", -40, duration)
			tween.connect("finished", Callable(self, "_on_fade_out_finished").bind(voice_player))

	# SFX
	for sfx_player in sfx_players:
		if sfx_player.playing:
			var tween := create_tween()
			tween.tween_property(sfx_player, "volume_db", -40, duration)
			tween.connect("finished", Callable(self, "_on_fade_out_finished").bind(sfx_player))
