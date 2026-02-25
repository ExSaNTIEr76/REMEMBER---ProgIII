class_name SaveSlotData    extends Control


@onready var empty_data_label: Label = %EmptyDataLabel

@export var zone_portrait_atlas: Texture2D
@onready var zone_portrait: TextureRect = $ZonePortrait

@onready var month: Label = $STATS/DATEBoxContainer/MONTH
@onready var day: Label = $STATS/DATEBoxContainer/DAY
@onready var year: Label = $STATS/DATEBoxContainer/YEAR

@onready var player_name: Label = $STATS/STATSContainer/PLAYERContainer/PlayerName
@onready var level_number: Label = $STATS/STATSContainer/LEVELContainer/levelNumber

@onready var hours: Label = $STATS/STATS2Container/TIMEHBoxContainer/HOURS
@onready var minutes: Label = $STATS/STATS2Container/TIMEHBoxContainer/MINUTES
@onready var seconds: Label = $STATS/STATS2Container/TIMEHBoxContainer/SECONDS

@onready var map_number: Label = $STATS/STATS2Container/MAPContainer/mapNumber
@onready var credits_number: Label = $STATS/STATS2Container/CREDITSContainer/creditsNumber

@onready var stats_container: VBoxContainer = $STATS/STATSContainer
@onready var stats_2_container: VBoxContainer = $STATS/STATS2Container
@onready var date_box_container: HBoxContainer = $STATS/DATEBoxContainer

@onready var slot_data_animations: AnimationPlayer = %SlotDataAnimations


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


func _ready() -> void:
	# Ocultar secciones de stats al inicio
	stats_container.hide()
	stats_2_container.hide()
	date_box_container.hide()


func update_zone_portrait():
	var level = get_tree().current_scene
	if level is Level and level.zone_tag != "":
		var tag = level.zone_tag
		if portrait_coords.has( tag ):
			var coord = portrait_coords[ tag ]
			
			var atlas := preload( "res://UI/Menu/sprites/mainMenu_portraits.png" )
			var region := Rect2( coord * Vector2(68, 74), Vector2( 68, 74 ) )
			
			var atlas_texture := AtlasTexture.new()
			atlas_texture.atlas = zone_portrait_atlas
			atlas_texture.region = Rect2( coord * Vector2( 68, 74 ), Vector2(68, 74 ) )
			zone_portrait.texture = atlas_texture

			# 🔓 Mostrar contenedores al cargar datos guardados
			stats_container.show()
			stats_2_container.show()
			date_box_container.show()

		else:
			push_warning( "⚠️ No hay coordenadas definidas para el zone_tag: %s" % tag )
	else:
		push_warning( "⚠️ No se encontró el nivel o no tiene zone_tag" )


func update_from_save_data(save_data: Dictionary) -> void:
	if save_data.is_empty():
		#push_warning("❌ No hay datos para cargar en este slot.")
		clear_display()
		return

	# 📸 Zona visual (usando zone_tag del save)
	var tag := str(save_data.get("zone_tag", "Empty"))
	if tag == "" or not portrait_coords.has(tag):
		# fallback a "Empty" si tag no existe o no está mapeado
		tag = "Empty"

	if portrait_coords.has(tag):
		var coord = portrait_coords[tag]
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = zone_portrait_atlas
		atlas_texture.region = Rect2(coord * Vector2(68, 74), Vector2(68, 74))
		zone_portrait.texture = atlas_texture
	else:
		# si no hay coords, usar la celda (0,0) como default
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = zone_portrait_atlas
		atlas_texture.region = Rect2(Vector2(0,0) * Vector2(68,74), Vector2(68,74))
		zone_portrait.texture = atlas_texture


	# 🗓️ Fecha (esperamos formato "YYYY-MM-DD HH:MM:SS")
	var raw_date = str(save_data.get("save_date", Time.get_datetime_string_from_system()))
	# Aceptamos formatos "YYYY-MM-DD", "YYYY-MM-DDTHH:MM:SS", "YYYY-MM-DD HH:MM:SS"
	var date_part = raw_date.split("T")[0].split(" ")[0]
	var parts = date_part.split("-")
	if parts.size() == 3:
		year.text = parts[0]
		month.text = parts[1]
		day.text = parts[2]
	else:
		year.text = "----"
		month.text = "--"
		day.text = "--"

	# 📛 Nombre del jugador
	player_name.text = str(save_data.get("player_name", "???"))

	# 🔢 Nivel
	level_number.text = str(save_data.get("player_level", 1))

	# ⏱️ Tiempo jugado
	var play_time = str(save_data.get("play_time", "00:00:00"))
	var time_parts = play_time.split(":")
	if time_parts.size() == 3:
		hours.text = time_parts[0]
		minutes.text = time_parts[1]
		seconds.text = time_parts[2]
	else:
		hours.text = "00"
		minutes.text = "00"
		seconds.text = "00"

	# 🗺️ Progreso del mapa descubierto
	map_number.text = str(save_data.get("map_discovered", 0))

	# 💰 Créditos
	credits_number.text = str(save_data.get("credits", 0))

	# ✅ Mostrar contenedores al cargar datos guardados
	stats_container.show()
	stats_2_container.show()
	date_box_container.show()

	empty_data_label.hide()
	#print("DEBUG slot details save_data:", save_data)
	#print("DEBUG zone_tag:", save_data.get("zone_tag", "NO_TAG"), "player_level:", save_data.get("player_level"), "credits:", save_data.get("credits"), "play_time:", save_data.get("play_time"))



func update_from_live_data():
	# 1️⃣ Zona y retrato
	if GlobalConditions.zone_tag in portrait_coords:
		var coord = portrait_coords[GlobalConditions.zone_tag]
		var atlas_texture := AtlasTexture.new()
		atlas_texture.atlas = zone_portrait_atlas
		atlas_texture.region = Rect2(coord * Vector2(68, 74), Vector2(68, 74))
		zone_portrait.texture = atlas_texture

	# 2️⃣ Nombre de jugador
	player_name.text = GlobalConditions.player_name if GlobalConditions.player_name != "" else "???"

	# 3️⃣ Nivel y créditos
	if PlayerManager.player and PlayerManager.player.stats:
		level_number.text = str(PlayerManager.player.stats.CURRENT_LEVEL)
		credits_number.text = str(PlayerManager.player.stats.CREDITS)
	else:
		level_number.text = "?"
		credits_number.text = "0"

	# 4️⃣ Tiempo jugado
	if has_node("/root/TimePanel"): # Si fuera un autoload, o si lo instancias en el HUD
		var tp = get_node("/root/TimePanel")
		hours.text = tp.hours.text
		minutes.text = tp.minutes.text
		seconds.text = tp.seconds.text
	else:
		hours.text = "00"
		minutes.text = "00"
		seconds.text = "00"

	# 5️⃣ Fecha actual del sistema
	var now = Time.get_datetime_dict_from_system()
	year.text = str(now.year)
	month.text = str(now.month).pad_zeros(2)
	day.text = str(now.day).pad_zeros(2)

	# 6️⃣ Mapa descubierto
	map_number.text = str(GlobalConditions.map_discovered)


func clear_display() -> void:

	empty_data_label.show()

	stats_container.hide()
	stats_2_container.hide()
	date_box_container.hide()

	zone_portrait.texture = null
	player_name.text = "---"
	level_number.text = "-"
	month.text = "--"
	day.text = "--"
	year.text = "----"
	hours.text = "00"
	minutes.text = "00"
	seconds.text = "00"
	map_number.text = "---"
	credits_number.text = "0"
