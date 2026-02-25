class_name EquipSlotUI    extends Control

signal slot_hovered(equip_type: String)

@onready var equip_menu: EquipMenu
@onready var equip_slot_button: MenuButton

var click_pos: Vector2 = Vector2.ZERO
var dragging := false
var drag_texture: Control
var drag_threshold := 16.0

@export var equip_type: String = ""

@onready var item_button: Button = %ItemButton
@onready var item_texture: TextureRect = $ItemTexture
@onready var item_name: Label = $ItemName

var current_item: ItemData = null
@export var participates_in_inventory := true
@export var inventory_item_type := ItemData.ItemType.NONE


func _ready() -> void:
	add_to_group("equip_slot")
	clear()

	# Focus / hover → descripción + emitir señal
	item_button.focus_entered.connect(func():
		_on_focus_entered()
		slot_hovered.emit(equip_type)
	)
	item_button.focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(func():
		_on_mouse_entered()
		slot_hovered.emit(equip_type)
	)
	mouse_exited.connect(_on_mouse_exited)

	# Press → equipar item
	item_button.pressed.connect(item_pressed)


func clear() -> void:
	current_item = null
	item_texture.texture = null
	item_button.text = equip_type  # 👈 visible y navegable
	item_name.text = equip_type   # 👈 muestra tipo de slot aunque esté vacío



func set_item(item: ItemData) -> void:
	current_item = item
	if not item:
		clear()
		return
	item_texture.texture = item.texture
	item_button.text = item.name
	item_name.text = item.name


func _grab_focus() -> void:
	if is_instance_valid(item_button):
		item_button.grab_focus()


func item_pressed() -> void:
	if not equip_menu:
		return

	if not _can_open_inventory():
		item_button.is_action_blocked()
		return

	AudioManager.mute_hover_once()
	equip_menu.nav_mode = EquipMenu.NavMode.INVENTORY
	equip_menu.last_slot_type = equip_type
	equip_menu.preview_slot_items(equip_type)

	await get_tree().process_frame

	if equip_menu.inventory_container.slots.is_empty():
		return

	var first_slot: InventorySlotUI = equip_menu.inventory_container.slots[0]
	first_slot._grab_focus()



func _can_open_inventory() -> bool:
	if not equip_menu:
		return false
	return equip_menu.has_items_for_slot(equip_type)


# --- Hover / focus descripción ---
func _on_focus_entered() -> void:
	if equip_menu:
		equip_menu.preview_equip_item(current_item, equip_type)
		if PlayerManager.player and has_node("StatsUpdater"):
			$StatsUpdater.setup(PlayerManager.stats)


func _on_focus_exited() -> void:
	if equip_menu:
		equip_menu.update_item_description("")


func _on_mouse_entered() -> void:
	_on_focus_entered()


func _on_mouse_exited() -> void:
	_on_focus_exited()


func _unhandled_input(event: InputEvent) -> void:
	if not equip_menu:
		return

	# Solo si este slot tiene foco
	if get_viewport().gui_get_focus_owner() != item_button:
		return

	# Solo en modo EQUIP_SLOTS
	if equip_menu.nav_mode != EquipMenu.NavMode.EQUIP_SLOTS:
		return

	# Shortcut: unequip
	if event.is_action_pressed( "ui_attack_a" ) and not event.is_echo():
		if current_item == null:
			return  # nada que remover

		# 🔊 feedback
		item_button.play_unequip_sfx()

		# 1️⃣ Lógica real
		PlayerManager.EQUIPMENT_DATA.unequip(equip_type)

		# 2️⃣ UI local
		clear()

		# 3️⃣ Reset UI descriptiva
		equip_menu.update_item_description("")
		equip_menu.clear_stats_preview()

		 #4️⃣ 🔄 FIX VISUAL
		_on_focus_exited()
		equip_menu.preview_slot_items(equip_type)
		_on_focus_entered()

		# 4️⃣ Promissio sync
		var promissio := get_tree().get_first_node_in_group("promissio")
		if promissio:
			promissio.clear_concrete_symbol(equip_type)

		print("🧹 Unequipped:", equip_type)

		get_viewport().set_input_as_handled()
