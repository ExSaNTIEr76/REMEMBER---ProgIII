#TextPopup.gd (escena autoload):

extends CanvasLayer

@onready var credits_popup: PanelContainer = %CreditsPopup
@onready var item_popup: PanelContainer = %ItemPopup
@onready var symbol_popup: PanelContainer = %SymbolPopup
@onready var enemy_popup: PanelContainer = %EnemyPopup

@onready var item_texture: TextureRect = %ItemTexture
@onready var item_name: Label = %ItemName
@onready var item_xlabel: Label = %ItemXlabel
@onready var item_quantity: Label = %ItemQuantity

@onready var credits_label: Label = %CreditsLabel
@onready var credits_quantity: Label = %CreditsQuantity

@onready var symbol_texture: TextureRect = %SymbolTexture
@onready var symbol_name: Label = %SymbolName
@onready var symbol_xlabel: Label = %SymbolXlabel
@onready var symbol_quantity: Label = %SymbolQuantity

@onready var enemy_name: Label = %EnemyName

@onready var item_popup_animations: AnimationPlayer = %ItemPopupAnimations
@onready var credits_popup_animations: AnimationPlayer = %CreditsPopupAnimations
@onready var symbol_popup_animations: AnimationPlayer = %SymbolPopupAnimations
@onready var enemy_popup_animations: AnimationPlayer = %EnemyPopupAnimations

@warning_ignore("unused_private_class_variable")
var _last_enemy_name: String = ""

var _object_timer: Timer
var _credits_timer: Timer
var _symbol_timer: Timer
var _enemy_timer: Timer
var _enemy_memory_timer: Timer


func _ready():
	_object_timer = Timer.new()
	_credits_timer = Timer.new()
	_symbol_timer = Timer.new()
	_enemy_timer = Timer.new()
	_enemy_memory_timer = Timer.new()

	_enemy_memory_timer.timeout.connect(_on_enemy_memory_timeout)

	_object_timer.one_shot = true
	_credits_timer.one_shot = true
	_symbol_timer.one_shot = true
	_enemy_timer.one_shot = true
	_enemy_memory_timer.one_shot = true

	_enemy_memory_timer.wait_time = 8.0  # ⏳ Se olvida a los 30s

	add_child(_object_timer)
	add_child(_credits_timer)
	add_child(_symbol_timer)
	add_child(_enemy_timer)
	add_child(_enemy_memory_timer)



# ---------------------------
# 📦 POPUP PARA ITEMS
# ---------------------------
@warning_ignore("shadowed_variable_base_class")
func show_item_popup(name: String, quantity: int, item_type: int, texture: Texture2D):
	item_name.text = name
	item_xlabel.text = "x"
	item_quantity.text = str(quantity)

	# 🖼 Mostrar la textura del item
	if texture:
		item_texture.texture = texture
	else:
		item_texture.texture = null

	# 🎨 Apply stylebox
	var sb := _get_item_stylebox(item_type)
	if sb:
		item_popup.add_theme_stylebox_override("panel", sb)

	item_popup_animations.play("fade_in")

	_object_timer.stop()
	_object_timer.start(5.0)

	await _object_timer.timeout
	item_popup_animations.play("fade_out")




# ---------------------------
# 💲 POPUP PARA CREDITS
# ---------------------------
@warning_ignore("shadowed_variable_base_class")
func show_credits_popup(credits_amount: int):
	credits_label.text = "C"
	credits_quantity.text = str(credits_amount)

	credits_popup_animations.play("fade_in")

	_credits_timer.stop()
	_credits_timer.start(4.0)

	await _credits_timer.timeout
	credits_popup_animations.play("fade_out")



# ---------------------------
# 🔮 POPUP PARA SÍMBOLOS
# ---------------------------
@warning_ignore("shadowed_variable_base_class")
func show_symbol_popup(name: String, quantity: int, item_type: int, texture: Texture2D):
	symbol_name.text = name
	symbol_xlabel.text = "x"
	symbol_quantity.text = str(quantity)

	# 🖼 Mostrar la textura del item
	if texture:
		symbol_texture.texture = texture
	else:
		symbol_texture.texture = null

	# 🎨 Apply stylebox
	var sb := _get_symbol_stylebox(item_type)
	if sb:
		symbol_popup.add_theme_stylebox_override("panel", sb)

	symbol_popup_animations.play("fade_in")

	_symbol_timer.stop()
	_symbol_timer.start(5.0)

	await _symbol_timer.timeout
	symbol_popup_animations.play("fade_out")



# ---------------------------
# 👻 POPUP PARA ENEMIGOS
# ---------------------------
var _enemy_popup_active_id := 0

func _on_enemy_memory_timeout():
	_last_enemy_name = ""

@warning_ignore("shadowed_variable_base_class")
func show_enemy_popup(name: String):
	name = name.strip_edges()

	_enemy_popup_active_id += 1
	var my_id = _enemy_popup_active_id

	var is_same_enemy := (
		name == _last_enemy_name
		and enemy_popup_animations.current_animation != "fade_out"
	)

	enemy_name.text = name

	# Reiniciar memoria SIEMPRE
	_enemy_memory_timer.start()

	# Fade-in sólo si es enemigo distinto
	if not is_same_enemy:
		enemy_popup_animations.play("fade_in")

	_last_enemy_name = name

	# Timer del popup solo si es enemigo distinto
	if not is_same_enemy:
		_enemy_timer.stop()
		_enemy_timer.start(5.0)

	# Esperar timeout solo si somos la llamada válida
	await _enemy_timer.timeout

	if my_id == _enemy_popup_active_id:
		enemy_popup_animations.play("fade_out")



# ---------------------------
# 🎨 STYLEBOX HELPERS
# ---------------------------

func _get_item_stylebox(item_type: int) -> StyleBox:
	var base_path := "res://UI/Menu/styleboxes/"

	match item_type:
		ItemData.ItemType.CONSUMABLE:
			return load(base_path + "popup_item_consumable.tres")
		ItemData.ItemType.KEY:
			return load(base_path + "popup_item_key.tres")
		ItemData.ItemType.MATERIAL:
			return load(base_path + "popup_item_material.tres")
		ItemData.ItemType.MISCELLANEOUS:
			return load(base_path + "popup_item_miscellaneous.tres")

		# 🛡 Equipables → usan el mismo stylebox
		ItemData.ItemType.DEF1, ItemData.ItemType.DEF2, ItemData.ItemType.SPECIAL:
			return load(base_path + "popup_item_equipable.tres")

		_:
			return null


func _get_symbol_stylebox(item_type: int) -> StyleBox:
	var base_path := "res://UI/Menu/styleboxes/"

	match item_type:
		ItemData.ItemType.CONCRETE:
			return load(base_path + "popup_symbol_concrete.tres")
		ItemData.ItemType.ABSTRACT:
			return load(base_path + "popup_symbol_abstract.tres")
		ItemData.ItemType.SINGULAR:
			return load(base_path + "popup_symbol_singular.tres")

		_:
			return null
