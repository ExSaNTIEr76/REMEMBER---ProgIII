class_name ItemsMenu    extends MenuBase

@warning_ignore("unused_signal")
signal preview_stats_changed(item: ItemData)

@onready var button_usables: Button = %USABLES
@onready var button_keys: Button = %KEYS
@onready var button_materials: Button = %MATERIALS
@onready var button_miscellaneous: Button = %MISCELLANEOUS

@onready var inventory_container: InventoryUI = %InventoryContainer
@onready var item_description: Label = %ItemDescription

var last_button: Button = null
var last_preview_effect: ItemEffectHeal = null


func _ready() -> void:
	get_tree().paused = false
	AudioManager.mute_hover_once()
	visible = false

	inventory_container.items_menu = self
	button_usables.pressed.connect(func(): AudioManager.mute_hover_once(); _show_type(ItemData.ItemType.CONSUMABLE, button_usables))
	button_keys.pressed.connect(func(): AudioManager.mute_hover_once(); _show_type(ItemData.ItemType.KEY, button_keys))
	button_materials.pressed.connect(func(): AudioManager.mute_hover_once(); _show_type(ItemData.ItemType.MATERIAL, button_materials))
	button_miscellaneous.pressed.connect(func(): AudioManager.mute_hover_once(); _show_type(ItemData.ItemType.MISCELLANEOUS, button_miscellaneous))

	# Hover con mouse
	button_usables.mouse_entered.connect(func(): _preview_type(ItemData.ItemType.CONSUMABLE, button_usables))
	button_keys.mouse_entered.connect(func(): _preview_type(ItemData.ItemType.KEY, button_keys))
	button_materials.mouse_entered.connect(func(): _preview_type(ItemData.ItemType.MATERIAL, button_materials))
	button_miscellaneous.mouse_entered.connect(func(): _preview_type(ItemData.ItemType.MISCELLANEOUS, button_miscellaneous))

	# Hover con teclado
	button_usables.focus_entered.connect(func(): _preview_type(ItemData.ItemType.CONSUMABLE, button_usables))
	button_keys.focus_entered.connect(func(): _preview_type(ItemData.ItemType.KEY, button_keys))
	button_materials.focus_entered.connect(func(): _preview_type(ItemData.ItemType.MATERIAL, button_materials))
	button_miscellaneous.focus_entered.connect(func(): _preview_type(ItemData.ItemType.MISCELLANEOUS, button_miscellaneous))

	button_usables.grab_focus()
	hidden.emit()


func _on_visibility_changed():
	if visible:
		if PlayerManager.player and has_node("StatsUpdater"):
			$StatsUpdater.setup(PlayerManager.stats)


func initialize_focus() -> void:
	if is_instance_valid(button_usables):
		button_usables.grab_focus()


func preview_item_effect(effect: ItemEffectHeal) -> void:
	last_preview_effect = effect

	if has_node("StatsUpdater"):
		$StatsUpdater.status_panel.preview_heal(
			effect.target_stat,
			effect.heal_amount
		)


func clear_item_preview() -> void:
	last_preview_effect = null

	if has_node("StatsUpdater"):
		$StatsUpdater.status_panel.clear_preview()


func _preview_type(item_type: ItemData.ItemType, _hovered_button: Button) -> void:
	inventory_container.update_inventory(
		PlayerManager.INVENTORY_DATA.get_items_by_type(item_type)
	)


func update_item_description(new_text: String) -> void:
	item_description.text = new_text


# --- Helpers ---
func _show_type(item_type: ItemData.ItemType, pressed_button: Button) -> void:
	inventory_container.update_inventory(
		PlayerManager.INVENTORY_DATA.get_items_by_type(item_type)
	)
	last_button = pressed_button

	if inventory_container.slots.size() > 0:
		await get_tree().process_frame
		inventory_container.slots[0]._grab_focus()


# Revisa si 'node' está dentro del árbol (descendiente) de 'ancestor'
func _is_descendant_of(node: Node, ancestor: Node) -> bool:
	var cur := node
	while cur:
		if cur == ancestor:
			return true
		cur = cur.get_parent()
	return false


# Retornar true si consumimos el cancel
func on_cancel() -> bool:
	var focus_owner: Node = get_viewport().gui_get_focus_owner()

	if focus_owner and (focus_owner.is_in_group("inventory_slot") or _is_descendant_of(focus_owner, inventory_container)):
		await get_tree().process_frame

		if last_button and is_instance_valid(last_button):
			last_button.grab_focus()
		else:
			button_usables.grab_focus()

		# Refrescar el inventario según el último botón real
		if is_instance_valid(last_button):
			var item_type := ItemData.ItemType.CONSUMABLE
			match last_button:
				button_keys: item_type = ItemData.ItemType.KEY
				button_materials: item_type = ItemData.ItemType.MATERIAL
				button_miscellaneous: item_type = ItemData.ItemType.MISCELLANEOUS
			_preview_type(item_type, last_button)

		return true

	return false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var focus_owner : Node = get_viewport().gui_get_focus_owner()
		if focus_owner:
			# Si el foco está dentro del contenedor de inventario, devuelve el foco a la barra
			if _is_descendant_of(focus_owner, inventory_container):
				if last_button and is_instance_valid(last_button):
					last_button.grab_focus()
				else:
					button_usables.grab_focus()
				get_viewport().set_input_as_handled()
				return

	# Si no lo manejamos, delegamos a MenuBase
	super._unhandled_input(event)
