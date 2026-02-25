class_name StatusPanel    extends Control

@onready var current_hp: Label = $StatusPanel/MarginContainer/VBoxContainer/HBoxContainerHP/currentHP
@onready var max_hp: Label = $StatusPanel/MarginContainer/VBoxContainer/HBoxContainerHP/maxHP
@onready var healthbar: Healthbar = $StatusPanel/MarginContainer/VBoxContainer/HBoxContainerHP/maxHP/Healthbar

@onready var current_cp: Label = $StatusPanel/MarginContainer/VBoxContainer/HBoxContainerCP/currentCP
@onready var max_cp: Label = $StatusPanel/MarginContainer/VBoxContainer/HBoxContainerCP/maxCP
@onready var competencebar: Competencebar = $StatusPanel/MarginContainer/VBoxContainer/HBoxContainerCP/maxCP/Competencebar

@onready var current_ep: Label = $StatusPanel/MarginContainer/VBoxContainer/HBoxContainerEP/currentEP
@onready var max_ep: Label = $StatusPanel/MarginContainer/VBoxContainer/HBoxContainerEP/maxEP
@onready var espritbar: Espritbar = $StatusPanel/MarginContainer/VBoxContainer/HBoxContainerEP/maxEP/Espritbar

@onready var actual_status: RichTextLabel = $StatusPanel/MarginContainer/VBoxContainer/HBoxContainerSTATUS/actualStatus

const NORMAL_COLOR := Color.WHITE
const PREVIEW_COLOR := Color(0.25, 1.0, 0.25, 1.0)


func preview_heal(stat: String, amount: int):
	var PM := get_node("/root/PlayerManager")
	var s = PM.get_stats_snapshot()

	match stat:
		"HP":
			var preview = clamp(s["CURRENT_HP"] + amount, 0, s["MAX_HP"])
			current_hp.text = str(preview)
			current_hp.modulate = PREVIEW_COLOR
			healthbar.show_preview(preview)

		"CP":
			var preview = clamp(s["CURRENT_CP"] + amount, 0, s["MAX_CP"])
			current_cp.text = str(preview)
			current_cp.modulate = PREVIEW_COLOR
			competencebar.show_preview(preview)

		"EP":
			var preview = clamp(s["CURRENT_EP"] + amount, 0, s["MAX_EP"])
			current_ep.text = str(preview)
			current_ep.modulate = PREVIEW_COLOR
			espritbar.show_preview(preview)


func clear_preview():
	var PM := get_node("/root/PlayerManager")
	var s = PM.get_stats_snapshot()

	current_hp.text = str(s["CURRENT_HP"])
	current_cp.text = str(s["CURRENT_CP"])
	current_ep.text = str(s["CURRENT_EP"])

	current_hp.modulate = NORMAL_COLOR
	current_cp.modulate = NORMAL_COLOR
	current_ep.modulate = NORMAL_COLOR

	healthbar.clear_preview()
	competencebar.clear_preview()
	espritbar.clear_preview()
