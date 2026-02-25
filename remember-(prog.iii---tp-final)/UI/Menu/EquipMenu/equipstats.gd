class_name EquipStatsPanel    extends Control

@onready var atk_number: Label = %atkNumber
@onready var atk_arrow: TextureRect = %atkArrow
@onready var atk_number_change: Label = %atkNumberChange

@onready var def_number: Label = %defNumber
@onready var def_arrow: TextureRect = %defArrow
@onready var def_number_change: Label = %defNumberChange

@onready var str_number: Label = %strNumber
@onready var str_arrow: TextureRect = %strArrow
@onready var str_number_change: Label = %strNumberChange

@onready var con_number: Label = %conNumber
@onready var con_arrow: TextureRect = %conArrow
@onready var con_number_change: Label = %conNumberChange

@onready var esp_number: Label = %espNumber
@onready var esp_arrow: TextureRect = %espArrow
@onready var esp_number_change: Label = %espNumberChange

@onready var lck_number: Label = %lckNumber
@onready var lck_arrow: TextureRect = %lckArrow
@onready var lck_number_change: Label = %lckNumberChange

const ARROW_ATLAS_COORDS := {
	"DOWN":    Vector2(0, 0),
	"EQUAL":  Vector2(1, 0),
	"UP": Vector2(2, 0)
}

const COLOR_UP := Color("ff9447ff")
const COLOR_DOWN := Color("47a8ffff")


func _ready() -> void:
	for arrow in [
		atk_arrow,
		def_arrow,
		str_arrow,
		con_arrow,
		esp_arrow,
		lck_arrow
	]:
		if arrow.texture:
			arrow.texture = arrow.texture.duplicate()


func _set_arrow(arrow: TextureRect, delta: int) -> void:
	if delta == 0:
		arrow.hide()
		return

	var dir := "UP" if delta > 0 else "DOWN"
	var coord = ARROW_ATLAS_COORDS[dir]

	var atlas := arrow.texture as AtlasTexture
	atlas.region.position = coord * atlas.region.size
	arrow.show()


func show_preview(current: Dictionary, preview: Dictionary) -> void:
	_render_stat("ATK", atk_number, atk_arrow, atk_number_change, current, preview)
	_render_stat("DEF", def_number, def_arrow, def_number_change, current, preview)
	_render_stat("STR", str_number, str_arrow, str_number_change, current, preview)
	_render_stat("CON", con_number, con_arrow, con_number_change, current, preview)
	_render_stat("ESP", esp_number, esp_arrow, esp_number_change, current, preview)
	_render_stat("LCK", lck_number, lck_arrow, lck_number_change, current, preview)


func _render_stat(
	key: String,
	value_label: Label,
	arrow: TextureRect,
	change_label: Label,
	current: Dictionary,
	preview: Dictionary
):
	# Siempre ocultamos por defecto
	arrow.hide()
	change_label.hide()
	change_label.modulate = Color.WHITE


	if not current.has(key):
		return

	var cur := int(current[key])
	var next := cur

	if preview.has(key):
		next = int(preview[key])

	var delta := next - cur

	# Valor base siempre visible
	value_label.text = str(cur)

	# Si no cambia → nada visible
	if delta == 0:
		return

	# Mostrar cambio
	change_label.text = str(next)

	if delta > 0:
		change_label.modulate = COLOR_UP
	elif delta < 0:
		change_label.modulate = COLOR_DOWN

	change_label.show()
	_set_arrow(arrow, delta)


func clear_preview():
	for arrow in [atk_arrow, def_arrow, str_arrow, con_arrow, esp_arrow, lck_arrow]:
		arrow.hide()

	for label in [
		atk_number_change,
		def_number_change,
		str_number_change,
		con_number_change,
		esp_number_change,
		lck_number_change
	]:
		label.hide()
