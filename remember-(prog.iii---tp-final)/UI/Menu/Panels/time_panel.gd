class_name TimePanel    extends Control

@onready var hours: Label = %HOURS
@onready var minutes: Label = %MINUTES
@onready var seconds: Label = %SECONDS
@onready var limit: Label = %LIMIT

var total_seconds := 0.0


func _ready():
	set_process(true)
	Engine.max_fps = 60

	await get_tree().process_frame  # 🕐 Espera un frame
	if is_instance_valid(TimeManager):
		total_seconds = TimeManager.total_seconds
		update_time_display()
		print("🕓 TimePanel inicializado con tiempo:", TimeManager.get_time_string())

	# conectar la señal (opcional si ya lo tenías)
	if TimeManager.has_signal("time_loaded"):
		TimeManager.connect("time_loaded", Callable(self, "_on_time_loaded"))


func _process(_delta):
	# Mantiene el reloj sincronizado
	total_seconds = TimeManager.total_seconds
	update_time_display()


func update_time_display():
	var t: int = int(total_seconds)
	var h: int = floor(t / 3600.0)
	var m: int = floor((t % 3600) / 60.0)
	var s: int = t % 60
	hours.text = str(h).pad_zeros(2)
	minutes.text = str(m).pad_zeros(2)
	seconds.text = str(s).pad_zeros(2)


func _on_time_loaded(new_seconds: float) -> void:
	print("🕓 TimePanel sincronizado tras carga:", TimeManager.get_time_string())
	total_seconds = new_seconds
	update_time_display()


func reset_clock():
	total_seconds = 0
	update_time_display()
