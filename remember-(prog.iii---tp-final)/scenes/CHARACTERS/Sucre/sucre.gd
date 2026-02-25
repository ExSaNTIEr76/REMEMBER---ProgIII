@icon("res://addons/proyect_icons/sucre_proyect_icon.png")

class_name Sucre extends CharacterBody2D

@export var skin: String = "default"
@export var start_facing_direction: String = "Down"

@onready var state_machine: StateMachine = $"STATE MACHINE"
@onready var sucre_sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var current_direction: Vector2 = Vector2.ZERO
var last_direction_name: String = "Down"

var animations: SucreAnimations = SucreAnimations.new()


func _ready():
	_update_spritesheet_by_type()
	last_direction_name = start_facing_direction
	play_animation("Idle/Idle" + last_direction_name)


# 🧁 Actualiza el spritesheet dependiendo del "sucre_type"
func _update_spritesheet_by_type():
	var base_path := "res://scenes/CHARACTERS/Sucre/sprites/"
	var texture_path := base_path + "Sucre_" + skin + "_spritesheet.png"
	var tex := load(texture_path)

	if tex:
		sucre_sprite.texture = tex

		# 💫 Ajustes opcionales según el tipo (por ejemplo, si lleva algo encima)
		match skin:
			"maid":
				sucre_sprite.offset.y = -22
			"winter":
				sucre_sprite.offset.y = -22
			"battle":
				sucre_sprite.offset.y = -22
			_:
				sucre_sprite.offset.y = -22  # default
	else:
		push_error("❌ Spritesheet no encontrada para sucre_type: " + skin)


# ▶️ Reproduce animaciones de forma segura
func play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		push_warning("⚠️ Animación '%s' no encontrada en Sucre." % anim_name)


# 🔍 Helper opcional para detectar obstáculos si lo necesitás luego
func is_area_blocked() -> bool:
	if has_node("AreaDetector"):
		return $AreaDetector.is_colliding()
	return false
