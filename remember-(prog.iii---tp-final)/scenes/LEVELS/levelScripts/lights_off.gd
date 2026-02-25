class_name LightsOFF extends Area2D

@onready var collisions := get_children().filter(func(c): return c is CollisionShape2D)

func _ready():
	monitoring = true
	connect("body_entered", Callable(self, "_on_body_entered"))

	# 🚫 Desactivamos temporalmente todas las colisiones
	for col in collisions:
		col.disabled = true

	# ✅ Reactivamos después de 0.2 segundos
	await get_tree().create_timer(0.2).timeout
	for col in collisions:
		col.disabled = false


func _on_body_entered(body: Node) -> void:
	if body is Player:
		print("🌑 LightsOFF → Apagando luz (forzado)")
		(body as Player).hide_light(true)
