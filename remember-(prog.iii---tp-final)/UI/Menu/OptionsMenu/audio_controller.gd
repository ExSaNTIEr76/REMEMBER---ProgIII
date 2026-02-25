class_name AudioController    extends HSlider

@export var audio_bus_name : String

@export var hover_sfx: AudioStream
@export_range(-80, 0) var hover_volume_db := -15.0
@export_range(0.5, 2.0) var hover_pitch := 1.5

var audio_bus_id

func _ready():
	AudioManager.mute_hover_once()

	if hover_sfx:
		mouse_entered.connect(_on_hover)
		focus_entered.connect(_on_hover)

	audio_bus_id = AudioServer.get_bus_index(audio_bus_name)


@warning_ignore("shadowed_variable_base_class")
func _on_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_id, db)


func _gui_input(event):
	if event is InputEventMouseMotion:
		grab_focus()


func _on_hover():
	if AudioManager._consume_hover_mute():
		return

	AudioManager.play_sfx(hover_sfx, hover_pitch, hover_volume_db)
