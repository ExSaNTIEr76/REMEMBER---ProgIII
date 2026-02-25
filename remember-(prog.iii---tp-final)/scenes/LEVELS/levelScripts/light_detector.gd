#light_detector.gd:

class_name LightDetector    extends Area2D

func _ready():
	monitoring = true
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body is Player:
		print("💡 LightDetector → Encendiendo luz")
		(body as Player).show_light()
		PlayerManager.light_persistent = true
