@icon("res://addons/proyect_icons/chest_proyect_icon.png")

@tool    class_name TreasureChest    extends CharacterBody2D

@export var chest_name: String = ""
var chest_id: String = ""
var is_open: bool = false

@export var dialogue_resource: DialogueResource

@export_enum( "Yellow", "Lime", "Purple", "Mines", "Deep Mines", "Pink", "Blue" )
var chest_color: String = "Yellow" : set = _set_chest_color

@export_category( "Chest Padlock" )
@export var is_padlocked: bool = false

@export_enum( "NONE", "Simple", "Complex" )
var padlock_type: String = "NONE" : set = _set_padlock_type

const PADLOCK_FRAME_WIDTH := 192
const PADLOCK_FRAME_HEIGHT := 32

const PADLOCK_ROW := {
	"NONE": 0,
	"Simple": 1,
	"Complex": 2,
}

@export_category( "Chest Contents" )
@export var item_data: ItemData : set = _set_item_data
@export var quantity: int = 1 : set = _set_quantity

@export var gives_credits: bool = false
@export var credits_amount: int = 0

@onready var chest_sprite: Sprite2D = $Chest
@onready var padlock_sprite: Sprite2D = $Padlock
@onready var item_sprite: Sprite2D = $Item
@onready var quantity_label: Label = $Item/ItemQuantity
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var chest_area: Area2D = $ChestArea

const COLOR_ROW := {
	"Yellow": 0, "Lime": 1, "Purple": 2, "Mines": 3, "Deep Mines": 4,
	"Pink": 5, "Blue": 6,
}

const CHEST_FRAME_WIDTH := 192
const CHEST_FRAME_HEIGHT := 32


func _ready() -> void:
	# Poner el cofre en un grupo para poder actualizarlo centralmente
	add_to_group( "chests" )

	# ID único: usar scene_file_path si el Level lo provee
	var scene_obj := get_tree().current_scene
	var scene_id := "UnknownScene"
	if scene_obj:
		if "scene_file_path" in scene_obj:
			scene_id = scene_obj.scene_file_path
		else:
			scene_id = scene_obj.name

	@warning_ignore( "incompatible_ternary" )
	chest_id = scene_id + "/" + ( chest_name if chest_name != "" else name )

	# Conectar la señal para cuando el GlobalChestsState sea restaurado desde el save.
	if not Engine.is_editor_hint():
		if not GlobalChestsState.is_connected( "state_restored", Callable(self, "sync_with_global" )):
			GlobalChestsState.state_restored.connect( Callable(self, "sync_with_global" ))

	if not Engine.is_editor_hint():
		sync_with_global()

	# Visuales (update para edición en editor)
	_update_texture()
	_update_label()
	_update_chest_region()
	_update_padlock_region()

	if animation_player and not animation_player.is_connected( "animation_started", Callable(self, "_on_anim_started" )):
		animation_player.connect( "animation_started", Callable(self, "_on_anim_started" ))

	if not Engine.is_editor_hint():
		sync_with_global()

	set_chest_state()


func _apply_color_offset() -> void:
	if chest_sprite and COLOR_ROW.has( chest_color ):
		var row: int = COLOR_ROW[ chest_color ]
		var rect := chest_sprite.region_rect
		rect.position.y = row * CHEST_FRAME_HEIGHT
		chest_sprite.region_rect = rect


func _on_anim_started( _anim_name: String ) -> void:
	_apply_color_offset()



# --- INTERACCIÓN ---

func action() -> void:
	var player := get_tree().get_first_node_in_group( "players" ) as Player

	if is_open:
		return

	if is_padlocked:
		if not InventoryManager.has_key_for( padlock_type ):
			AudioManager.play_sfx_path( "res://audio/SFX/Enviorement/chests/Sfx_Chest.ogg", 0.5, -8.0 )
			if padlock_type == "Simple":
				DialogueManager.show_dialogue_balloon( dialogue_resource, "simpleLock" )
				return
			if padlock_type == "Complex":
				DialogueManager.show_dialogue_balloon( dialogue_resource, "complexLock" )
				return
			print( "🚫 Locked:", padlock_type )
		else:
			if InventoryManager.use_key_for( padlock_type ):
				PlayerManager.player.freeze_movement()
				print( "🔑 Chest unlocked with", padlock_type, "key!" )
				animation_player.play( "unlocking" )
				await animation_player.animation_finished
				is_padlocked = false
				padlock_sprite.visible = false
				PlayerManager.player.restore_movement()

	# Si no está bloqueado → abrir
	is_open = true
	animation_player.play( "opening")

	if player:
		player.state_machine.change_to( player.states.Interact )
		if player.state_machine.current_state.has_method( "using_block" ):
			await player.state_machine.current_state.using_block()

	# Dar ítems o créditos
	if gives_credits and credits_amount > 0:
		InventoryManager.add_credits( credits_amount )
		await CinematicManager._wait( 0.2 )
		TextPopup.show_credits_popup( credits_amount )
		print( "💰 Chest gave ", credits_amount, " credits!" )
	elif item_data and quantity > 0:
		PlayerManager.INVENTORY_DATA.add_item( item_data, quantity )
		await CinematicManager._wait( 0.2 )

		if item_data.type in [
			ItemData.ItemType.CONCRETE,
			ItemData.ItemType.ABSTRACT,
			ItemData.ItemType.SINGULAR
		]:
			# Es un símbolo
			TextPopup.show_symbol_popup( item_data.name, quantity, item_data.type, item_data.texture )
		else:
			# Es un item normal
			TextPopup.show_item_popup( item_data.name, quantity, item_data.type, item_data.texture )


	else:
		printerr( "No Contents in Chest! -> ", chest_id )

	GlobalChestsState.chests_triggered[chest_id] = true


func set_chest_state() -> void:
	if is_open:
		animation_player.play( "opened" )
	else:
		if is_padlocked:
			animation_player.play( "padlocked" )
		else:
			animation_player.play( "closed" )

	_apply_color_offset()
	padlock_sprite.visible = is_padlocked


# --- SETTERS ---

func _set_item_data( value: ItemData ) -> void:
	item_data = value
	_update_texture()


func _set_quantity(value: int) -> void:
	quantity = value
	_update_label()


func _set_chest_color(value: String) -> void:
	chest_color = value
	_update_chest_region()


func _set_padlock_type(value: String) -> void:
	padlock_type = value
	_update_padlock_region()


# --- HELPERS ---

func _update_texture() -> void:
	if gives_credits:
		# mostrar ícono de créditos
		return
	elif item_data and item_sprite:
		item_sprite.texture = item_data.texture


func _update_label() -> void:
	if quantity_label:
		if gives_credits:
			quantity_label.text = str( credits_amount )
		else:
			quantity_label.text = "" if quantity <= 0 else "x" + str( quantity )


func _update_chest_region() -> void:
	if chest_sprite and chest_sprite.region_enabled and COLOR_ROW.has( chest_color ):
		var row: int = COLOR_ROW[ chest_color ]
		chest_sprite.region_rect = Rect2(
			Vector2( 0, row * CHEST_FRAME_HEIGHT ),
			Vector2( CHEST_FRAME_WIDTH, CHEST_FRAME_HEIGHT )
		)


func _update_padlock_region() -> void:
	if not padlock_sprite or not padlock_sprite.region_enabled:
		return

	if PADLOCK_ROW.has( padlock_type ):
		var row: int = PADLOCK_ROW[ padlock_type ]
		padlock_sprite.region_rect = Rect2(
			Vector2( 0, row * PADLOCK_FRAME_HEIGHT ),
			Vector2( PADLOCK_FRAME_WIDTH, PADLOCK_FRAME_HEIGHT )
		)


func sync_with_global() -> void:
	if GlobalChestsState.chests_triggered.has( chest_id ):
		is_open = true
	else:
		is_open = false

	set_chest_state()
