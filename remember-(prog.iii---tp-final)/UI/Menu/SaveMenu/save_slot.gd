class_name SaveSlot    extends Panel

@onready var slot_button: Button = $SlotButton
@onready var player_name_panel: PanelContainer = $HBoxContainer/PlayerNamePanel
@onready var zone_panel: PanelContainer = $HBoxContainer/ZonePanel

@onready var createsave: Label = $HBoxContainer/CreateSave
@onready var slot_number: Label = $HBoxContainer/SlotNumber

@onready var player_name: Label = $HBoxContainer/PlayerNamePanel/PlayerNameHBoxContainer/PlayerName
@onready var level_name: Label = $HBoxContainer/ZonePanel/ZoneHBoxContainer/LevelName
@onready var zone_name: Label = $HBoxContainer/ZonePanel/ZoneName

@onready var save_slot_animations: AnimationPlayer = %SaveSlotAnimations

var _save_data: Dictionary = {}

@export var press_sfx: AudioStream
@export_range(-80, 0) var press_volume_db := -18.0
@export_range(0.5, 2.0) var press_pitch := 1.5

@export var blocked_sfx: AudioStream
@export_range(-80, 0) var blocked_volume_db := -5.0
@export_range(0.5, 2.0) var blocked_pitch := 1.0


var save_data: Dictionary = {}:
	get:
		return _save_data
	set(value):
		_save_data = value if value != null else {}
		_update_display()
		if not _save_data.is_empty():
			createsave.hide()
			player_name_panel.show()
			zone_panel.show()
		else:
			createsave.show()
			player_name_panel.hide()
			zone_panel.hide()

signal pressed(panel)


func _ready() -> void:
	slot_button.grab_focus()
	
	# Setear número visible
	if slot_number:
		slot_number.text = str(get_index() + 1)
	
	# Configuración inicial
	if _save_data.is_empty():
		createsave.show()
		player_name_panel.hide()
		zone_panel.hide()
	else:
		createsave.hide()
		_update_display()

	slot_button.pressed.connect(_on_slot_button_pressed)


func _on_slot_button_pressed() -> void:
	pressed.emit(self)


func _on_mouse_entered() -> void:
	slot_button.grab_focus()


func _update_display() -> void:
	if _save_data.is_empty():
		createsave.show()
		if player_name: player_name.text = "???"
		if level_name: level_name.text = "???"
		if zone_name: zone_name.text = "???"
		return

	#print("🧠 SLOT ", get_index(), " TAGS: ", _save_data)

	player_name.text = str(_save_data.get("player_name", "???"))
	level_name.text = str(_save_data.get("level_name", "???"))
	zone_name.text = str(_save_data.get("zone_name", "???"))


func activate() -> void:
	if _save_data.is_empty():
		_slot_pressed()
		save_slot_animations.play("slot_pressed")
		player_name_panel.hide()
		zone_panel.hide()
		createsave.show()
	else:
		_slot_pressed()
		save_slot_animations.play("slot_pressed")
		player_name_panel.show()
		zone_panel.show()
		createsave.hide()

func activate_load() -> void:
	if _save_data.is_empty():
		_slot_blocked()
		save_slot_animations.play("slot_blocked")
		player_name_panel.hide()
		zone_panel.hide()
		createsave.show()
	else:
		_slot_pressed()
		save_slot_animations.play("slot_pressed")
		player_name_panel.show()
		zone_panel.show()
		createsave.hide()


func deactivate() -> void:
	if _save_data.is_empty():
		player_name_panel.hide()
		zone_panel.hide()
		createsave.show()
	else:
		player_name_panel.show()
		zone_panel.show()
		createsave.hide()


func _slot_pressed():
	AudioManager.play_sfx(press_sfx, press_pitch, press_volume_db)

func _slot_blocked():
	AudioManager.play_sfx(blocked_sfx, blocked_pitch, blocked_volume_db)
