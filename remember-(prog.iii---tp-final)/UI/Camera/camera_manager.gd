class_name CameraManager extends Node2D

@onready var main_camera := $MainCamera
@export var transition_duration := 0.8

var player: Node = null
var camera_markers := {}
var current_zone := -1

func _ready():
	print("🎬 CameraManager inicializado.")
	await get_tree().process_frame

	# ⏳ Esperamos hasta 2 segundos para que PlayerManager instancie al jugador
	var max_wait_frames := 120
	while (PlayerManager.player == null or not PlayerManager.player.is_inside_tree()) and max_wait_frames > 0:
		await get_tree().process_frame
		max_wait_frames -= 1

	if PlayerManager.player == null:
		push_error("❗ No se pudo encontrar al jugador.")
		return

	player = PlayerManager.player
	print("🎯 Player detectado:", player.name)

	_detect_camera_markers()
	_connect_area_signals()

	# Zona forzada desde transición
	var forced_zone = GameManager.camera_zones_by_scene.get("__override__", -1)
	if forced_zone != -1:
		_move_camera_to_zone(forced_zone, true)
		GameManager.camera_zones_by_scene.erase("__override__")


func _detect_camera_markers():
	var regex := RegEx.new()
	regex.compile("^CameraZone(\\d+)$")
	camera_markers.clear()

	for area in get_children():
		if area is Area2D:
			for node in area.get_children():
				if node is Marker2D:
					var match := regex.search(node.name)
					if match:
						var index := int(match.get_string(1))
						camera_markers[index] = node
						print("📍 Marker zona %d detectado: %s" % [index, node.name])

func _connect_area_signals():
	var regex := RegEx.new()
	regex.compile("^AreaZone(\\d+)$")

	for area in get_children():
		if area is Area2D:
			var match := regex.search(area.name)
			if match:
				var index := int(match.get_string(1))
				area.body_entered.connect(func(body):
					if body == player:
						print("🚶 Player entró a zona %d" % index)
						_move_camera_to_zone(index))

func _move_camera_to_zone(index: int, instant := false):
	if not camera_markers.has(index):
		push_warning("⚠️ Zona %d no tiene marker asignado." % index)
		return

	var target = camera_markers[index]
	current_zone = index

	if instant:
		main_camera.position = target.global_position
		print("⚡ Cámara movida instantáneamente a zona %d" % index)
	else:
		var tween := create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(main_camera, "position", target.global_position, transition_duration)
		print("🎥 Moviendo cámara suavemente a zona %d" % index)
