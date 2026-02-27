extends Node

signal time_loaded

var total_seconds: float = 0.0
var is_running: bool = true

func _ready() -> void:
	set_process(true)
	print("⏱️ TimeManager activo, procesando tiempo...")

func _process(delta: float) -> void:
	if not is_running:
		return
	if not get_tree().paused:
		total_seconds += delta

func get_time_string() -> String:
	var t: int = int(total_seconds)
	var h: int = floor(t / 3600.0)
	var m: int = floor((t % 3600) / 60.0)
	var s: int = t % 60
	return "%02d:%02d:%02d" % [h, m, s]

func reset_time() -> void:
	total_seconds = 0

func set_time_from_string(time_str: String) -> void:
	var parts := time_str.split(":")
	if parts.size() == 3:
		var h = int(parts[0])
		var m = int(parts[1])
		var s = int(parts[2])
		total_seconds = (h * 3600) + (m * 60) + s
		print("🕓 Tiempo restaurado desde save:", time_str)
	emit_signal("time_loaded", total_seconds)

func pause_time() -> void:
	is_running = false
	print("⏸️ TimeManager pausado")

func resume_time() -> void:
	is_running = true
	print("▶️ TimeManager reanudado")
