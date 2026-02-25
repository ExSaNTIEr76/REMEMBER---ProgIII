class_name StatsUpdater extends Node

@export var status_panel: StatusPanel
@export var stats_panel: StatsPanel
@export var equip_stats_panel: EquipStatsPanel
@export var level_panel: LevelPanel
@export var gold_panel: GoldPanel
@export var time_panel: TimePanel

var stats = null

func setup(_stats = null):
	# 1️. Obtener PlayerManager real
	var PM := get_node_or_null("/root/PlayerManager")
	if not PM:
		push_warning("StatsUpdater: PlayerManager no encontrado.")
		return

	# 2️. Desconectar si ya estaba
	if PM.is_connected("stats_changed", Callable(self, "update_all")):
		PM.disconnect("stats_changed", Callable(self, "update_all"))

	# 3️. Conectar
	PM.connect("stats_changed", Callable(self, "update_all"))

	# 4️. Guardar stats si vienen
	stats = _stats

	# 5️. Forzar primer update
	update_all()


func update_all():
	var s := {}

	# 1) SIEMPRE priorizar PlayerManager si existe
	if Engine.has_singleton("PlayerManager"):
		var PM = Engine.get_singleton("PlayerManager")
		s = PM.get_stats_snapshot()

	# 2) Si no existe PlayerManager, usar lo que se tenga en stats
	elif typeof(stats) == TYPE_DICTIONARY:
		s = stats

	# 3) Si es un Resource viejo, extraer manualmente
	elif stats:
		s = {
			"MAX_HP": stats.MAX_HP,
			"CURRENT_HP": stats.CURRENT_HP,
			"MAX_CP": stats.MAX_CP,
			"CURRENT_CP": stats.CURRENT_CP,
			"MAX_EP": stats.MAX_EP,
			"CURRENT_EP": stats.CURRENT_EP,
			"ATK": stats.ATK, "STR": stats.STR, "ESP": stats.ESP,
			"DEF": stats.DEF, "CON": stats.CON, "LCK": stats.LCK,
			"CURRENT_LEVEL": stats.CURRENT_LEVEL,
			"XP": stats.XP, "NEXT_XP": stats.NEXT_XP,
			"CREDITS": stats.CREDITS
		}
	else:
		# Sin PM ni stats → no se puede actualizar nada
		return


	# 🔧 Normalización a int
	for key in s.keys():
		if typeof(s[key]) in [TYPE_INT, TYPE_FLOAT]:
			s[key] = int(s[key])

	# 🟩 PANEL STATUS
	if status_panel:
		status_panel.current_hp.text = str(s["CURRENT_HP"])
		status_panel.max_hp.text = str(s["MAX_HP"])
		status_panel.current_cp.text = str(s["CURRENT_CP"])
		status_panel.max_cp.text = str(s["MAX_CP"])
		status_panel.current_ep.text = str(s["CURRENT_EP"])
		status_panel.max_ep.text = str(s["MAX_EP"])
		status_panel.actual_status.text = DamageData.get_colored_status_name(
			s.get("CURRENT_ALTERED_STATE", DamageData.StatusEffect.PURE)
		)

		status_panel.healthbar.setUp(s["MAX_HP"])
		status_panel.healthbar.updateValue(s["CURRENT_HP"])
		status_panel.competencebar.setUp(s["MAX_CP"])
		status_panel.competencebar.updateValue(s["CURRENT_CP"])
		status_panel.espritbar.setUp(s["MAX_EP"])
		status_panel.espritbar.updateValue(s["CURRENT_EP"])

	# PANELES RESTANTES
	if stats_panel:
		stats_panel.atk_number.text = str(s.get("ATK", 0))
		stats_panel.str_number.text = str(s.get("STR", 0))
		stats_panel.esp_number.text = str(s.get("ESP", 0))
		stats_panel.def_number.text = str(s.get("DEF", 0))
		stats_panel.con_number.text = str(s.get("CON", 0))
		stats_panel.lck_number.text = str(s.get("LCK", 0))

	if equip_stats_panel:
		equip_stats_panel.atk_number.text = str(s.get("ATK", 0))
		equip_stats_panel.str_number.text = str(s.get("STR", 0))
		equip_stats_panel.esp_number.text = str(s.get("ESP", 0))
		equip_stats_panel.def_number.text = str(s.get("DEF", 0))
		equip_stats_panel.con_number.text = str(s.get("CON", 0))
		equip_stats_panel.lck_number.text = str(s.get("LCK", 0))

	if level_panel:
		level_panel.current_level.text = str(s.get("CURRENT_LEVEL", 1))
		level_panel.exp_number.text = str(s.get("XP", 0))
		level_panel.next_number.text = str(s.get("NEXT_XP", 0))

	if gold_panel:
		gold_panel.credits_number.text = str(s.get("CREDITS", 0))
