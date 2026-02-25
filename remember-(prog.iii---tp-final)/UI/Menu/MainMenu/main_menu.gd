@icon("res://addons/proyect_icons/main_menu_proyect_icon.png")

class_name MainMenu    extends MenuBase

@export_file("*.tscn") var title_screen_scene: String

# Estado lógico del submenú YES/NO
var is_confirm_open: bool = false

@export var zone_portrait_atlas: Texture2D
@onready var zone_portrait: TextureRect = %ZonePortrait

@export var face_portrait_atlas: Texture2D
@onready var face_portrait: TextureRect = %FacePortrait

const PORTRAIT_SIZE := Vector2(64, 64)

@export var nametag_atlas: Texture2D
@onready var nametag: TextureRect = %NameTag
const NAMETAG_SIZE := Vector2(35, 4)

@onready var equip_button: Button = %EQUIP
@onready var items_button: Button = %ITEMS
@onready var archives_button: Button = %ARCHIVES
@onready var enemies_button: Button = %ENEMIES
@onready var options_button: Button = %OPTIONS
@onready var quit_button: Button = %QUIT

@onready var none_button: Button = %NONE

@onready var no_button: Button = %NO
@onready var yes_button: Button = %YES

@onready var menu_animations: AnimationPlayer = $MenuAnimations


func _ready() -> void:
	PlayerManager.stats_changed.connect(_on_stats_changed)
	PlayerManager.ill_state_changed.connect(_update_portrait_from_stats)
	_update_portrait_from_stats()

	GlobalConditions.conditions_changed.connect(_update_nametag_from_conditions)

	if not LevelManager.level_loaded.is_connected(_on_level_loaded):
		LevelManager.level_loaded.connect(_on_level_loaded)

	get_tree().paused = false
	AudioManager.mute_hover_once()
	visible = false

	equip_button.pressed.connect(_on_equip_pressed)
	items_button.pressed.connect(_on_items_pressed)

	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	no_button.pressed.connect(_on_no_pressed)
	yes_button.pressed.connect(_on_yes_pressed)

	equip_button.grab_focus()
	hidden.emit()


func _on_visibility_changed():
	if visible:
		_update_nametag_from_conditions()
	if visible:
		if PlayerManager.player and has_node("StatsUpdater"):
			$StatsUpdater.setup(PlayerManager.stats)


func initialize_focus() -> void:
	if is_instance_valid(GlobalMenuHub.last_main_button):
		GlobalMenuHub.last_main_button.grab_focus()
	else:
		if is_instance_valid(equip_button):
			equip_button.grab_focus()


func _on_equip_pressed() -> void:
	GlobalMenuHub.last_main_button = equip_button
	GlobalMenuHub.show_pause_menu(GlobalMenuHub.equip_menu)


func _on_items_pressed() -> void:
	GlobalMenuHub.last_main_button = items_button
	GlobalMenuHub.show_pause_menu(GlobalMenuHub.items_menu)


func _on_options_pressed() -> void:
	GlobalMenuHub.last_main_button = options_button
	GlobalMenuHub.show_pause_menu(GlobalMenuHub.options_menu)


func _on_quit_pressed() -> void:
	GlobalMenuHub.last_main_button = quit_button
	AudioManager.mute_hover_once()

	# Abrimos el submenú y marcamos estado lógico
	is_confirm_open = true
	none_button.grab_focus()
	menu_animations.play("yesnoMenu_fade_in")
	await menu_animations.animation_finished
	no_button.grab_focus()


func _on_no_pressed() -> void:
	# Cerramos confirm y volvemos al estado base
	is_confirm_open = false
	no_button.grab_focus()
	GlobalMenuHub.last_main_button = quit_button
	AudioManager.mute_hover_once()
	menu_animations.play("yesnoMenu_fade_out")
	await menu_animations.animation_finished

	# opcional: asegurar estado base (por si fade_out no restablece todo)
	_reset_menu_visual_state()

	await CinematicManager._wait(0.2)
	quit_button.grab_focus()


func _on_yes_pressed() -> void:
	is_confirm_open = false
	none_button.grab_focus()
	AudioManager.mute_hover_once()
	await SceneTransition.fade_out_black()
	menu_animations.play("yesnoMenu_fade_out")
	GlobalMenuHub.hide_pause_menu()

	# 🧹 Apagar absolutamente todo el audio con fade suave
	@warning_ignore("redundant_await")
	await AudioManager.fade_out_all(1.0)
	await get_tree().process_frame

	# 🚪 Esperamos un poquito más para asegurarnos de silencio completo
	CinematicManager._wait(0.5)
	
	get_tree().change_scene_to_file(title_screen_scene)


func _on_none_pressed():
	pass

#PARA HACER FOCUS EN OTROS MENÚES:
#GlobalMenuHub.show_pause_menu(GlobalMenuHub.objects_menu)


#region PORTRAITS

var portrait_coords := {
	"Empty": Vector2(0, 0),
	"Z0_ext": Vector2(1, 0),
	"Z0_int": Vector2(2, 0),
	"Z0_basement": Vector2(3, 0),
	"Z0_secret_basement": Vector2(4, 0),
	"Z0_temple": Vector2(5, 0),
	"TheNothingness": Vector2(6, 0),
	"PureZone": Vector2(7, 0),

	"Z1_ext": Vector2(0, 1),
	"Z1_int": Vector2(1, 1),
	"Tram": Vector2(2, 1),
	"TramStation": Vector2(3, 1),
	"SmokeMines": Vector2(4, 1),
	"Barns": Vector2(5, 1),
	"Administrations": Vector2(6, 1),
	"---": Vector2(7, 1),

	"DeepMines": Vector2(0, 2),
	"FleshRivers": Vector2(1, 2),
	"Z1_int_flesh": Vector2(2, 2),
	"FleshFountains": Vector2(3, 2),
}


func update_zone_portrait():
	var level = get_tree().current_scene
	if level is Level and level.zone_tag != "":
		var tag = level.zone_tag
		if portrait_coords.has(tag):
			var coord = portrait_coords[tag]
			
			var atlas := preload("res://UI/Menu/sprites/mainMenu_portraits.png")
			var region := Rect2(coord * Vector2(68, 74), Vector2(68, 74))
			
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = zone_portrait_atlas
			atlas_texture.region = Rect2(coord * Vector2(68, 74), Vector2(68, 74))
			zone_portrait.texture = atlas_texture
			#print("🖼️ IMAGEN ACTUALIZADA")

		else:
			push_warning("⚠️ No hay coordenadas definidas para el zone_tag: %s" % tag)
	else:
		push_warning("⚠️ No se encontró el nivel o no tiene zone_tag")


func _on_level_loaded() -> void:
	update_zone_portrait()


func _set_nametag_region(pixel_coords: Vector2) -> void:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = nametag_atlas
	atlas_texture.region = Rect2(pixel_coords, NAMETAG_SIZE)
	nametag.texture = atlas_texture


func _update_nametag_from_conditions() -> void:
	if GlobalConditions.puppet_sucre:
		_set_nametag_region(Vector2(0, 16))
	elif GlobalConditions.puppet_name_revealed:
		_set_nametag_region(Vector2(0, 8))
	else:
		_set_nametag_region(Vector2(0, 0))


func _set_face_region(pixel_coords: Vector2) -> void:
	var atlas_texture := AtlasTexture.new()
	atlas_texture.atlas = face_portrait_atlas
	atlas_texture.region = Rect2(pixel_coords, PORTRAIT_SIZE)
	face_portrait.texture = atlas_texture


func _update_portrait_from_stats():
	var current_hp := PlayerManager.get_current_hp()
	var max_hp := PlayerManager.get_max_hp()

	if max_hp <= 0:
		return

	var hp_ratio := float(current_hp) / float(max_hp)

	# 🔥 PRIORIDAD 1
	if PlayerManager.is_ill:
		set_portrait_ill()
		return

	# PRIORIDAD 2
	if hp_ratio <= 0.2:
		set_portrait_critical()
		return

	# PRIORIDAD 3
	set_portrait_default()


func set_portrait_default():
	_set_face_region(Vector2(0, 0))

func set_portrait_critical():
	_set_face_region(Vector2(704, 0))

func set_portrait_ill():
	_set_face_region(Vector2(576, 192))


func _on_stats_changed():
	_update_portrait_from_stats()


#endregion





func on_cancel() -> bool:
	# Si el confirm está abierto, lo tratamos exactamente como NO
	if is_confirm_open:
		# Si hay una animación en curso, esperarla
		if menu_animations.is_playing():
			await menu_animations.animation_finished

		await _on_no_pressed()
		_reset_menu_visual_state()
		get_viewport().set_input_as_handled()
		return true

	# 🚫 Si no hay confirm abierto, NO manejamos nada aquí
	# Devolvemos false para que MenuBase decida si volver atrás
	return false


func _reset_menu_visual_state() -> void:
	# Detener cualquier animación en curso y forzar estado por defecto.
	if menu_animations.is_playing():
		menu_animations.stop()

	# Play 'RESET' to force pose base (asegurate de tener esta animación)
	if menu_animations.has_animation("RESET"):
		menu_animations.play("RESET")
		# opcional: si necesitás esperar a que termine:
		# await menu_animations.animation_finished

	# Asegurá foco en el botón principal correcto
	if is_instance_valid(GlobalMenuHub.last_main_button):
		GlobalMenuHub.last_main_button.grab_focus()
	else:
		equip_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if GlobalMenuHub.input_locked:
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_pause") and GlobalMenuHub._can_pause():
		# Si hay confirm abierto, lo limpiamos y luego salimos
		if is_confirm_open:
			is_confirm_open = false
			_reset_menu_visual_state()
		# Cerrar el menú por completo
		GlobalMenuHub.hide_pause_menu()
		get_viewport().set_input_as_handled()
		return

	# Cancel -> delegar a on_cancel
	if event.is_action_pressed("ui_cancel"):
		var handled = await on_cancel()
		if handled:
			get_viewport().set_input_as_handled()
			return

	super._unhandled_input(event)
