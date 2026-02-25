@icon("res://addons/proyect_icons/player_hud_proyect_icon.png") 
#PlayerHUD.gd:

extends CanvasLayer

@onready var root := $HUDRoot
@onready var hud_animations: AnimationPlayer = $HUDRoot/HUDAnimations

@onready var healthbar: Healthbar = $HUDRoot/HealthbarDelay/Healthbar
@onready var healthbar_delay: HealthbarDelay = $HUDRoot/HealthbarDelay

@onready var competencebar: Competencebar = $HUDRoot/CompetencebarDelay/Competencebar
@onready var competencebar_delay: CompetencebarDelay = $HUDRoot/CompetencebarDelay

@onready var espritbar: Espritbar = $HUDRoot/EspritbarDelay/Espritbar
@onready var espritbar_delay: EspritbarDelay = $HUDRoot/EspritbarDelay

var damage_visible_time := 30.0
var damage_timer: Timer = null

static var _persistent_visible: bool = false
static var _persistent_waiting_cp_full: bool = false

var hud_visible := false
var hide_timer = null
var waiting_cp_full := false

var critical_hp := false

func _ready():
	var pm := PlayerManager

	pm.hp_changed.connect(_on_hp_changed)
	pm.cp_changed.connect(_on_cp_changed)
	pm.ep_changed.connect(_on_ep_changed)

	init_bars(pm.get_stats_snapshot())

	healthbar.critical_started.connect(_on_critical_started)
	healthbar.critical_ended.connect(_on_critical_ended)

	# 🟢 MOSTRAR HUD AL INICIO, PERO NO PERSISTENTE
	await get_tree().process_frame
	show_temporarily(5.0)


func _on_hp_changed(value: int):
	healthbar.updateValue(value)
	healthbar_delay.updateValue(value)

func _on_cp_changed(value: int):
	competencebar.updateValue(value)
	competencebar_delay.updateValue(value)

	if value < PlayerManager.get_max_cp():
		wait_until_cp_full()


func _on_ep_changed(value: int):
	espritbar.updateValue(value)
	espritbar_delay.updateValue(value)


# init_bars ahora acepta Dictionary o Resource (lo más flexible)
func init_bars(stats):
	# stats puede ser PlayerGlobalStats (resource) o Dictionary (snapshot)
	var max_hp := 100
	var cur_hp := 100
	var max_cp := 50
	var cur_cp := 50
	var max_ep := 10
	var cur_ep := 10

	if typeof(stats) == TYPE_DICTIONARY:
		max_hp = int(stats.get("MAX_HP", max_hp))
		cur_hp = int(stats.get("CURRENT_HP", cur_hp))
		max_cp = int(stats.get("MAX_CP", max_cp))
		cur_cp = int(stats.get("CURRENT_CP", cur_cp))
		max_ep = int(stats.get("MAX_EP", max_ep))
		cur_ep = int(stats.get("CURRENT_EP", cur_ep))
	elif stats != null:
		# suponemos resource con propiedades públicas
		max_hp = int(stats.MAX_HP)
		cur_hp = int(stats.CURRENT_HP)
		max_cp = int(stats.MAX_CP)
		cur_cp = int(stats.CURRENT_CP)
		max_ep = int(stats.MAX_EP)
		cur_ep = int(stats.CURRENT_EP)

	healthbar.setUp(max_hp)
	healthbar_delay.setUp(max_hp)
	competencebar.setUp(max_cp)
	competencebar_delay.setUp(max_cp)
	espritbar.setUp(max_ep)
	espritbar_delay.setUp(max_ep)

	# valores actuales
	healthbar.updateValue(cur_hp)
	healthbar_delay.updateValue(cur_hp)
	competencebar.updateValue(cur_cp)
	competencebar_delay.updateValue(cur_cp)
	espritbar.updateValue(cur_ep)
	espritbar_delay.updateValue(cur_ep)


func on_player_damaged():
	# 1️⃣ Asegurar visibilidad
	if not hud_visible:
		hud_visible = true
		hud_animations.play("hud_fade_in")

	# 2️⃣ Feedback
	vibrate()

	# 3️⃣ Si está crítico, NO programar ocultado
	if critical_hp:
		return

	# 4️⃣ Timer de 30s (resettable)
	if damage_timer == null:
		damage_timer = Timer.new()
		damage_timer.one_shot = true
		damage_timer.timeout.connect(_on_damage_timer_timeout)
		add_child(damage_timer)
	else:
		damage_timer.stop()

	damage_timer.wait_time = damage_visible_time
	damage_timer.start()


func _on_damage_timer_timeout():
	if critical_hp or waiting_cp_full:
		return

	hud_visible = false
	hud_animations.play("hud_fade_out")


func _on_critical_started():
	critical_hp = true

	if not hud_visible:
		hud_visible = true
		hud_animations.play("hud_fade_in")

	if damage_timer:
		damage_timer.stop()


func _on_critical_ended():
	critical_hp = false

	# Volvemos al comportamiento normal post-daño
	on_player_damaged()


func vibrate():
	if not root:
		return

	var tween := create_tween()
	var original_pos: Vector2 = root.position  # Solo si HUDRoot es un Control
	var strength := 4.0

	for i in range( 3 ):
		var shake_offset := Vector2(randf_range( -1, 1 ), randf_range( -1, 1 ) ) * strength
		tween.tween_property( root, "position", original_pos + shake_offset, 0.025 )
		tween.tween_property( root, "position", original_pos, 0.025 )


func show_temporarily(duration := 2.5) -> void:
	if not hud_visible:
		hud_animations.play("hud_fade_in")
		hud_visible = true
		_persistent_visible = true

	# ⚡ si estamos esperando CP full, NO arrancar timer
	if waiting_cp_full:
		return

	if hide_timer:
		hide_timer.stop()
	else:
		hide_timer = Timer.new()
		hide_timer.one_shot = true
		hide_timer.timeout.connect(_on_hide_timer_timeout)
		add_child(hide_timer)

	hide_timer.wait_time = duration
	hide_timer.start()


func _on_hide_timer_timeout() -> void:
	if waiting_cp_full or critical_hp:
		return  # ❌ NO ocultar si CP o HP crítico

	hud_visible = false
	hud_animations.play("hud_fade_out")


func wait_until_cp_full() -> void:
	if waiting_cp_full:
		return

	if PlayerManager.get_current_cp() >= PlayerManager.get_max_cp():
		return

	waiting_cp_full = true
	_persistent_waiting_cp_full = true

	if hide_timer:
		hide_timer.stop()

	_check_cp_full()


func _check_cp_full() -> void:
	if PlayerManager.get_current_cp() >= PlayerManager.get_max_cp():
		waiting_cp_full = false
		_persistent_waiting_cp_full = false
		_on_hide_timer_timeout()
		return

	await get_tree().create_timer(0.1).timeout

	if not is_instance_valid(self):
		return

	_check_cp_full()
