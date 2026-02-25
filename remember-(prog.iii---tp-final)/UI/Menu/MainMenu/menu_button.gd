#menu_button.gd

extends Button

var init_mute_hover: bool = false

@export var press_cooldown := 0.30

@export var hover_sfx: AudioStream
@export_range(-80, 0) var hover_volume_db := -15.0
@export_range(0.5, 2.0) var hover_pitch := 1.5

@export var press_sfx: AudioStream
@export_range(-80, 0) var press_volume_db := -18.0
@export_range(0.5, 2.0) var press_pitch := 1.5

@export var blocked_sfx: AudioStream
@export_range(-80, 0) var blocked_volume_db := -15.0
@export_range(0.5, 2.0) var blocked_pitch := 1.5

@export var equiped_sfx: AudioStream
@export_range(-80, 0) var equiped_volume_db := -10.0
@export_range(0.5, 2.0) var equiped_pitch := 1.0

@export var unequiped_sfx: AudioStream
@export_range(-80, 0) var unequiped_volume_db := -15.0
@export_range(0.5, 2.0) var unequiped_pitch := 1.0

var _last_press_time := 0.0

var equip_requested := false
var suppress_press_sfx := false

var action_validator: Callable = Callable()
var press_sfx_validator: Callable = Callable()


func _ready() -> void:
	if init_mute_hover == true:
		AudioManager.mute_hover_once()
	
	if hover_sfx:
		mouse_entered.connect(_on_hover)
		focus_entered.connect(_on_hover)
	if press_sfx:
		pressed.connect(_on_press)
	
	init_mute_hover = false

func _on_hover():
	if disabled:
		return
	if AudioManager._consume_hover_mute():
		return
	AudioManager.play_sfx(hover_sfx, hover_pitch, hover_volume_db)


func _on_press():
	var now := Time.get_ticks_msec() / 1000.0

	# 🚫 BLOQUEADO
	if is_action_blocked():
		if now - _last_press_time < press_cooldown:
			return
		if blocked_sfx:
			_last_press_time = now
			AudioManager.play_sfx(blocked_sfx, blocked_pitch, blocked_volume_db)
		return

	# Silenciar press_sfx si fue mutado explícitamente
	if AudioManager._consume_press_mute():
		return

	# EQUIP (mismo nivel que BLOCKED)
	if equip_requested:
		equip_requested = false
		#AudioManager.mute_press_once()
		AudioManager.mute_hover_once()
		if equiped_sfx:
			AudioManager.play_sfx(equiped_sfx, equiped_pitch, equiped_volume_db)
		return

	# Decidir si este botón debe sonar o no
	if press_sfx_validator.is_valid() and not press_sfx_validator.call():
		return

	# Cooldown normal
	if now - _last_press_time < press_cooldown:
		return

	_last_press_time = now
	AudioManager.play_sfx(press_sfx, press_pitch, press_volume_db)


func is_action_blocked() -> bool:
	if disabled:
		return true

	if action_validator.is_valid():
		return not action_validator.call()

	return false


func play_blocked_sfx():
	AudioManager.mute_press_once()
	AudioManager.play_sfx(blocked_sfx, equiped_pitch, equiped_volume_db)


func play_equip_sfx():
	if equiped_sfx:
		AudioManager.mute_press_once()
		AudioManager.mute_hover_once()
		AudioManager.play_sfx(equiped_sfx, equiped_pitch, equiped_volume_db)


func play_unequip_sfx():
	if equiped_sfx:
		AudioManager.play_sfx(unequiped_sfx, unequiped_pitch, unequiped_volume_db)
