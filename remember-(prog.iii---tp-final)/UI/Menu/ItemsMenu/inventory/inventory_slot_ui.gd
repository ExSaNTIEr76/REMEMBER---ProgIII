class_name InventorySlotUI    extends Control

@onready var items_menu: ItemsMenu = null
@onready var equip_menu: EquipMenu = null

var click_pos: Vector2 = Vector2.ZERO
var dragging := false
var drag_texture: Control
var drag_threshold := 16.0

@onready var item_button: Button = $VBoxContainer/ItemButton
@onready var item_texture: TextureRect = $ItemTexture
@onready var item_name: Label = $ItemName
@onready var quantity_label: Label = $VBoxContainer/ItemQuantity

var current_item: ItemData = null

func _ready() -> void:
	custom_minimum_size = Vector2(0, 30) # o lo que mida tu slot

	add_to_group("inventory_slot")
	clear()

	# 🔗 Conectamos el validador del botón
	if equip_menu:
		item_button.press_sfx_validator = Callable(self, "_should_play_press_sfx")

	if item_button.has_method("set"):
		item_button.action_validator = Callable(self, "can_use_current_item")

	item_button.focus_entered.connect(_on_focus_entered)
	item_button.focus_exited.connect(_on_focus_exited)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	item_button.pressed.connect(item_pressed)
	item_button.button_down.connect(on_button_down)
	item_button.button_down.connect(_on_button_down_for_equip)
	item_button.button_up.connect(on_button_up)


func clear() -> void:
	current_item = null
	item_texture.texture = null
	item_button.text = ""
	item_name.text = ""
	quantity_label.text = ""


func set_item(item: ItemData) -> void:
	current_item = item
	if not item:
		clear()
		return
	
	item_texture.texture = item.texture
	item_button.text = item.name
	item_name.text = item.name
	if item.is_quantitative:
		quantity_label.text = str(PlayerManager.INVENTORY_DATA.get_quantity(item))
		quantity_label.show()
	else:
		quantity_label.text = ""
		quantity_label.hide()



func refresh_quantity() -> void:
	if current_item and current_item.is_quantitative:
		quantity_label.text = str(PlayerManager.INVENTORY_DATA.get_quantity(current_item))
		quantity_label.show()
	else:
		quantity_label.text = ""
		quantity_label.hide()



func _grab_focus() -> void:
	if is_instance_valid(item_button):
		item_button.grab_focus()

func _on_button_down_for_equip() -> void:
	if equip_menu and equip_menu.last_slot_type != "":
		item_button.equip_requested = true


func item_pressed() -> void:
	if not current_item:
		return


	# --- SI ESTAMOS EN EQUIP MENU ---
	if equip_menu \
	and equip_menu.inventory_preview_mode == EquipMenu.InventoryPreviewMode.SINGULAR \
	and current_item.type == ItemData.ItemType.SINGULAR:
		item_button.equip_requested = true
		item_button.equip_requested = false
		return


	if equip_menu and equip_menu.last_slot_type != "":
		var target_slot := equip_menu.last_slot_type

		if equip_menu.equipment_container and equip_menu.equipment_container.data:
			equip_menu.equipment_container.data.equip(target_slot, current_item)

		if equip_menu.equipment_container:
			equip_menu.equipment_container.set_equipped(target_slot, current_item)

		# 🧠 CONEXIÓN REAL CON PROMISSIO
		if current_item is EquipableItemData:
			if current_item.symbol_scene:
				var promissio := get_tree().get_first_node_in_group("promissio")
				if promissio:
					promissio.set_concrete_symbol(
						target_slot,
						current_item.symbol_scene
					)
					print("🟢 Symbol equipado en", target_slot, "→", current_item.symbol_scene)

		# 🔊 feedback
		if item_button:
			item_button.equip_requested = true



		# 🔄 Volvemos a modo slots
		equip_menu.nav_mode = EquipMenu.NavMode.EQUIP_SLOTS
		equip_menu.inventory_mode = false

		await get_tree().process_frame

		# 🔁 Volver foco al EquipSlot correcto
		if equip_menu.equipment_container \
		and equip_menu.equipment_container.slots.has(target_slot):

			var slot_ui: EquipSlotUI = equip_menu.equipment_container.slots[target_slot]
			slot_ui._grab_focus()

			# 🧹 LIMPIAR NEIGHBORS (MUY IMPORTANTE)
			var equip_button: Button = slot_ui.item_button
			var inv_button: Button = item_button

			equip_button.focus_neighbor_bottom = NodePath("")
			inv_button.focus_neighbor_top = NodePath("")

		equip_menu.last_slot_type = ""
		return




	# --- SI ESTAMOS EN ITEMS MENU ---
	if not current_item or not items_menu:
		return

	# 🛑 Seguridad extra (por si alguien llama esto directo)
	if not can_use_current_item():
		return

	# ✅ Aplicar efectos
	for e in current_item.effects:
		e.use()

	# 📦 Consumir si corresponde
	if current_item.is_quantitative:
		PlayerManager.INVENTORY_DATA.remove_item(current_item, 1)
		refresh_quantity()
		var qty := PlayerManager.INVENTORY_DATA.get_quantity(current_item)

		if qty <= 0:
			var container := get_parent() as InventoryUI
			var old_slots = container.slots.duplicate()
			var idx := old_slots.find(self)

			var preferred_idx := -1
			if idx >= 0:
				if idx < old_slots.size() - 1:
					preferred_idx = idx
				elif idx > 0:
					preferred_idx = idx - 1

			container.update_inventory(
				PlayerManager.INVENTORY_DATA.get_items_by_type(current_item.type),
				preferred_idx
			)
		else:
			refresh_quantity()

			# 🔁 Reaplicar preview si seguimos hovereando
			if current_item is UsableItemData:
				await get_tree().process_frame
				for e in current_item.effects:
						if e is ItemEffectHeal and e.can_use():
							items_menu.preview_item_effect(e)



func can_use_current_item() -> bool:
	if not current_item:
		return false

	# 🚫 NO USABLES
	if current_item.type in [
		ItemData.ItemType.NONE,
		ItemData.ItemType.KEY,
		ItemData.ItemType.MATERIAL,
		ItemData.ItemType.SINGULAR
	]:
		return false

	# 🔍 Validar efectos
	if current_item is UsableItemData:
		for e in current_item.effects:
			if e is ItemEffect and not e.can_use():
				return false

	return true


# --- Hover / focus descripción ---
func _on_focus_entered() -> void:
	if not current_item:
		return

	# 🟦 Items Menu
	if items_menu:
		items_menu.update_item_description(current_item.description)

		if current_item is UsableItemData:
			for e in current_item.effects:
				if e is ItemEffectHeal and e.can_use():
					items_menu.preview_item_effect(e)

		return

	# 🟩 Equip Menu
	if equip_menu:
		if equip_menu.last_slot_type != "":
			equip_menu.preview_equip_item(current_item, equip_menu.last_slot_type)
		else:
			# fallback seguro (por si algo raro pasa)
			equip_menu._show_body_ui()
			equip_menu.update_item_description(current_item.description)

	if equip_menu \
	and current_item is EquipableItemData \
	and equip_menu.last_slot_type != "":
		equip_menu.preview_stats(current_item, equip_menu.last_slot_type)
		if PlayerManager.player and has_node("StatsUpdater"):
			$StatsUpdater.setup(PlayerManager.stats)

	# 🟩 Equip Menu
	if equip_menu:
		# 🔮 SINGULAR PREVIEW
		if equip_menu.inventory_preview_mode == EquipMenu.InventoryPreviewMode.SINGULAR:
			if current_item is EquipableItemData:
				equip_menu._show_singular_symbol_ui(current_item)
			return




func _on_focus_exited() -> void:
	# Items Menu
	if items_menu:
		items_menu.clear_item_preview()
		items_menu.update_item_description("")
		return

	# Equip Menu
	if equip_menu:
		equip_menu.update_item_description("")
		equip_menu.clear_stats_preview()



func _on_mouse_entered() -> void:
	_on_focus_entered()

func _on_mouse_exited() -> void:
	_on_focus_exited()


# --- Drag ---
func on_button_down() -> void:
	click_pos = get_global_mouse_position()
	dragging = true
	drag_texture = item_texture.duplicate()
	drag_texture.z_index = 10
	drag_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(drag_texture)


func on_button_up() -> void:
	dragging = false
	if drag_texture:
		drag_texture.free()


func outside_drag_threshold() -> bool:
	return get_global_mouse_position().distance_to(click_pos) > drag_threshold


func _unhandled_key_input(event: InputEvent) -> void:
	if not equip_menu:
		return

	if event.is_action_pressed("ui_up"):
		var container := get_parent()
		if container is EquipInventoryUI:
			if container.slots.size() > 0 and container.slots[0] == self:
				return


#func _process(_delta):
	#if Input.is_action_just_pressed("ui_accept"):
		#print("FOCUS:", get_viewport().gui_get_focus_owner())
