class_name EquipMenu    extends MenuBase

@warning_ignore("unused_signal")
signal preview_stats_changed(item: ItemData)

@onready var body_button: Button = %BODY
@onready var symbols_button: Button = %SYMBOLS

@onready var equipment_container: EquipmentUI = %EquipmentContainer

@onready var inventory_container: EquipInventoryUI = %InventoryContainer
@onready var inventory_slot: InventorySlotUI

@onready var symbol_icon: AnimatedSprite2D = %SymbolIcon
@onready var symbol_space: TextureRect = %SymbolSpace
@onready var symbol_description: Label = %SymbolDescription
@onready var armor_description: Label = %ArmorDescription
@onready var cost_label: Label = %CostLabel
@onready var singulars_label: Label = %SingularsLabel

@onready var singulars_ui_label: Label = %SingularsUILabel
@onready var unequip_ui_label: Label = %UnequipUILabel

@onready var sleeves: AnimatedSprite2D = %SleevesTexture
@onready var sleeves_ui_label: Label = %SleevesUILabel

@onready var menu_animations: AnimationPlayer = %MenuAnimations

@onready var stats_panel: EquipStatsPanel = $EQUIPSTATS

var _ui_ready := false
var inventory_mode := false

var last_slot_type: String = ""
var last_button: Button = null

enum InventoryPreviewMode {
	NONE,
	EQUIPABLE,
	SINGULAR
}

var inventory_preview_mode := InventoryPreviewMode.NONE


func _ready() -> void:
	override_cancel_behaviour = true
	get_tree().paused = false
	AudioManager.mute_hover_once()
	visible = false

	inventory_container.equip_menu = self
	equipment_container.set_equip_menu(self)


	body_button.pressed.connect(func():
		AudioManager.mute_hover_once()
		_show_group("BODY", body_button, true)
		unequip_ui_label.show(); singulars_ui_label.hide())

	symbols_button.pressed.connect(func():
		AudioManager.mute_hover_once()
		_show_group("SYMBOLS", symbols_button, true)
		unequip_ui_label.show(); singulars_ui_label.show())


	body_button.mouse_entered.connect(func():
		_show_group("BODY", body_button, false)
	)
	symbols_button.mouse_entered.connect(func():
		_show_group("SYMBOLS", symbols_button, false)
	)


	body_button.focus_entered.connect(func():
		_show_group("BODY", body_button, false)
		unequip_ui_label.hide(); singulars_ui_label.hide())
	symbols_button.focus_entered.connect(func():
		_show_group("SYMBOLS", symbols_button, false)
		unequip_ui_label.hide(); singulars_ui_label.hide())

	unequip_ui_label.hide()
	if is_instance_valid(body_button) and GlobalConditions.first_symbol_count >= 1:
		symbols_button.show()
		symbols_button.grab_focus()
	else:
		symbols_button.hide()
		body_button.grab_focus()

	hidden.emit()
	_ui_ready = true


func _on_visibility_changed() -> void:
	if not _ui_ready:
		return

	if not visible:
		_reset_menu_state()
		return

	if PlayerManager.player and has_node("StatsUpdater"):
		$StatsUpdater.setup(PlayerManager.stats)



func initialize_focus() -> void:
	unequip_ui_label.hide()
	if is_instance_valid(body_button) and GlobalConditions.first_symbol_count >= 1:
		symbols_button.show()
		symbols_button.grab_focus()
	else:
		symbols_button.hide()
		body_button.grab_focus()


func _preview_group(group: String, _hovered_button: Button) -> void:
	print("Preview group:", group)


enum NavMode {
	CATEGORIES,
	EQUIP_SLOTS,
	INVENTORY
}

var nav_mode := NavMode.CATEGORIES


func preview_slot_items(equip_type: String) -> void:
	inventory_preview_mode = InventoryPreviewMode.EQUIPABLE
	last_slot_type = equip_type
	var item_type := ItemData.ItemType.NONE

	if equip_type == "DEFENSIVO 1":
		item_type = ItemData.ItemType.DEF1
	elif equip_type == "DEFENSIVO 2":
		item_type = ItemData.ItemType.DEF2
	elif equip_type.begins_with("ESPECIAL"):
		item_type = ItemData.ItemType.SPECIAL
	elif equip_type.begins_with("CONCRETO"):
		item_type = ItemData.ItemType.CONCRETE
	elif equip_type == "ABSTRACTO":
		item_type = ItemData.ItemType.ABSTRACT


	inventory_container.update_inventory(
		PlayerManager.INVENTORY_DATA.get_items_by_type(item_type)
	)


func update_item_description(new_text: String) -> void:
	armor_description.text = new_text


func _show_group(group: String, pressed_button: Button, auto_focus_slot: bool = false) -> void:
	inventory_preview_mode = InventoryPreviewMode.NONE
	if nav_mode == NavMode.INVENTORY:
		return

	last_button = pressed_button

	# LIMPIAR INVENTARIO SI VOLVEMOS A CATEGORÍAS
	_clear_inventory_preview()
	last_slot_type = ""

	if group == "BODY":
		_show_body_ui()
	elif group == "SYMBOLS":
		_show_body_ui()


	# mostrar/ocultar slots según categoría
	var show_body := (group == "BODY")
	equipment_container.defensive_1.visible = show_body
	equipment_container.defensive_2.visible = show_body
	equipment_container.special_1.visible   = show_body
	equipment_container.special_2.visible   = show_body and GlobalConditions.special_2_slot_obtained

	var show_symbols := (group == "SYMBOLS")
	equipment_container.concrete_a.visible = show_symbols
	equipment_container.concrete_b.visible = show_symbols
	equipment_container.abstract.visible   = show_symbols and GlobalConditions.first_symbol_count >= 2

	await get_tree().process_frame

	if auto_focus_slot:
		nav_mode = NavMode.EQUIP_SLOTS
		for slot in equipment_container.slots.values():
			if slot.visible:
				slot._grab_focus()
				return
	else:
		if nav_mode == NavMode.CATEGORIES and is_instance_valid(pressed_button):
			pressed_button.grab_focus()


func preview_equip_item(item: ItemData, equip_type: String) -> void:
	if not item:
		_show_body_ui()
		update_item_description("Espacio vacío para " + equip_type)
		return

	if item and item.type == ItemData.ItemType.SINGULAR:
		_show_body_ui()
		update_item_description(item.description + "\n\n[ Read-only Symbol ]")
		return

	# BODY (solo si NO estamos en símbolos)
	if not equip_type.begins_with("CONCRETO") and equip_type != "ABSTRACTO":
		_show_body_ui()
		update_item_description(item.description)
		return

	# SYMBOLS
	if item is EquipableItemData:
		_show_symbol_ui(item, equip_type)


func _clear_inventory_preview() -> void:
	if inventory_container:
		inventory_container.clear_inventory()


func _show_body_ui() -> void:
	armor_description.show()

	symbol_icon.hide()
	symbol_space.hide()
	symbol_description.hide()
	cost_label.hide()


func _show_symbol_ui(item: EquipableItemData, equip_type: String) -> void:
	armor_description.hide()
	singulars_ui_label.show()

	# Icono
	if item.symbol_icon_name != "":
		symbol_icon.show()
		if symbol_icon.sprite_frames.has_animation(item.symbol_icon_name):
			symbol_icon.play(item.symbol_icon_name)
		else:
			symbol_icon.stop()
	else:
		symbol_icon.hide()

	# Espacio + descripción
	symbol_space.show()
	symbol_description.show()
	symbol_description.text = item.description

	# Coste
	cost_label.show()
	if equip_type.begins_with("CONCRETO"):
		cost_label.text = "CP / %d" % item.cep_cost
	elif equip_type == "ABSTRACTO":
		cost_label.text = "EP / %d" % item.cep_cost
	else:
		cost_label.hide()


func _show_singular_symbol_ui(item: EquipableItemData) -> void:
	armor_description.hide()
	singulars_label.show()
	singulars_ui_label.show()

	# Icono
	if item.symbol_icon_name != "":
		symbol_icon.show()
		if symbol_icon.sprite_frames.has_animation(item.symbol_icon_name):
			symbol_icon.play(item.symbol_icon_name)
		else:
			symbol_icon.stop()
	else:
		symbol_icon.hide()

	# Descripción
	symbol_space.show()
	symbol_description.show()
	symbol_description.text = item.description

	cost_label.hide()


func _open_singulars_preview() -> void:
	var singulars := PlayerManager.INVENTORY_DATA.get_items_by_type(
		ItemData.ItemType.SINGULAR
	)

	if singulars.is_empty():
		AudioManager.play_sfx_path("res://audio/SFX/GUI SFX/menu/Sfx_Blocked.ogg", 1.5, -15.0)
		return

	AudioManager.mute_hover_once()

	inventory_preview_mode = InventoryPreviewMode.SINGULAR
	nav_mode = NavMode.INVENTORY
	last_slot_type = ""

	_clear_inventory_preview()
	inventory_container.update_inventory(singulars)

	# Limpiar UI simbólica hasta hover
	symbol_icon.hide()
	symbol_space.hide()
	symbol_description.hide()
	cost_label.hide()
	armor_description.hide()
	singulars_label.hide()

	await get_tree().process_frame
	if inventory_container.slots.size() > 0:
		inventory_container.slots[0]._grab_focus()


# Helper local: revisa si 'node' está dentro del árbol (descendiente) de 'ancestor'
func _is_descendant_of(node: Node, ancestor: Node) -> bool:
	var cur := node
	while cur:
		if cur == ancestor:
			return true
		cur = cur.get_parent()
	return false


func has_items_for_slot(equip_type: String) -> bool:
	var item_type := ItemData.ItemType.NONE

	if equip_type == "DEFENSIVO 1":
		item_type = ItemData.ItemType.DEF1
	elif equip_type == "DEFENSIVO 2":
		item_type = ItemData.ItemType.DEF2
	elif equip_type.begins_with("ESPECIAL"):
		item_type = ItemData.ItemType.SPECIAL
	elif equip_type.begins_with("CONCRETO"):
		item_type = ItemData.ItemType.CONCRETE
	elif equip_type == "ABSTRACTO":
		item_type = ItemData.ItemType.ABSTRACT

	if item_type == ItemData.ItemType.NONE:
		return false

	return not PlayerManager.INVENTORY_DATA.get_items_by_type(item_type).is_empty()


func on_cancel() -> bool:
	match nav_mode:
		NavMode.INVENTORY:
			# Inventario → EquipSlot
			if inventory_preview_mode == InventoryPreviewMode.SINGULAR:
				inventory_preview_mode = InventoryPreviewMode.NONE
				nav_mode = NavMode.EQUIP_SLOTS
				last_slot_type = ""
				_clear_inventory_preview()

				# Limpiar UI simbólica
				symbol_icon.hide()
				symbol_space.hide()
				symbol_description.hide()
				cost_label.hide()
				menu_animations.play("singulars_label_fade_out")

				# Volver a slot visible
				for slot in equipment_container.slots.values():
					if slot.visible:
						slot._grab_focus()
						break

				return true


			if last_slot_type != "" and equipment_container.slots.has(last_slot_type):
				var slot: EquipSlotUI = equipment_container.slots[last_slot_type]
				slot._grab_focus()
				nav_mode = NavMode.EQUIP_SLOTS
				return true

		NavMode.EQUIP_SLOTS:
			# EquipSlot → Categorías
			if last_button and is_instance_valid(last_button):
				last_button.grab_focus()
				nav_mode = NavMode.CATEGORIES
				_clear_inventory_preview()
				_show_body_ui()
				return true

	return false


func _reset_menu_state() -> void:
	# Estados lógicos
	nav_mode = NavMode.CATEGORIES
	inventory_preview_mode = InventoryPreviewMode.NONE
	last_slot_type = ""
	last_button = null
	inventory_mode = false

	# Inventario
	_clear_inventory_preview()

	# UI simbólica
	symbol_icon.hide()
	symbol_space.hide()
	symbol_description.hide()
	cost_label.hide()
	singulars_ui_label.hide()
	unequip_ui_label.hide()
	singulars_label.hide()

	# UI body
	if visible:
		_show_body_ui()


func preview_stats(item: EquipableItemData, slot_name: String) -> void:
	@warning_ignore("shadowed_variable")
	var preview_stats := PlayerManager.get_preview_stats(item, slot_name)
	stats_panel.show_preview(PlayerManager.stats, preview_stats)

func clear_stats_preview():
	stats_panel.show_preview(PlayerManager.stats, PlayerManager.stats)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return

	if nav_mode != NavMode.EQUIP_SLOTS:
		return

	# Solo desde SYMBOLS
	if last_button != symbols_button:
		return

	if event.is_action_pressed("ui_attack_b"):
		menu_animations.play("singulars_label_fade_in")
		AudioManager.play_sfx_path("res://audio/SFX/GUI SFX/menu/Sfx_Accept.ogg", 1.5, -18.0)
		_menu_opened()
		_open_singulars_preview()
		get_viewport().set_input_as_handled()


#func _process(_delta):
	#if Input.is_action_just_pressed("ui_accept"):
		#print("FOCUS:", get_viewport().gui_get_focus_owner())
