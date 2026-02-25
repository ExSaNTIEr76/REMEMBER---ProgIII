@icon("res://addons/proyect_icons/floating_cube_proyect_icon.png")

class_name FloatingBlock     extends CharacterBody2D

enum BlockStates { EMERGING, IDLE, SPINNING, PRESSED, DESCENDING, RESOLVED }

@export var block_number: int = 0

@export_enum("Yellow", "Lime", "Purple", "Pink", "Blue", "Orange", "Green", "Red", "Black", "White")
var block_color: String = "Yellow"

@export_enum("Yellow", "Lime", "Purple", "Pink", "Blue", "Orange", "Green", "Red", "Black", "White")
var hole_color: String = "Yellow"

@onready var block_hole: AnimatedSprite2D = $BlockHole
@onready var block_animations: AnimatedSprite2D = $BlockAnimations
@onready var block_sparkles: AnimatedSprite2D = $BlockSparkles
@onready var block_effects: AnimationPlayer = $BlockEffects
@onready var block_area: FloatingBlockArea = $BlockArea
@onready var block_area_collision: CollisionShape2D = $BlockArea/BlockAreaCollision

@export var one_time: bool = false
@export var snap_to_grid: bool = false:
	set(_v): _snap_to_grid()

var triggered := false
var current_state := BlockStates.EMERGING
var last_state = null
var just_spawned := true

var _original_collision_layer: int = 0
var _original_collision_mask: int = 0
var _original_area_monitoring: bool = true

func _ready():
	# Guardar valores originales de colisión/monitoring
	_original_collision_layer = collision_layer
	_original_collision_mask = collision_mask
	if block_area:
		_original_area_monitoring = block_area.monitoring

	_play_hole_color("%s_blockHole" % hole_color)
	update_animation_from_state()


func _process(_delta: float) -> void:
	update_animation_from_state()


func _snap_to_grid():
	position.x = round(position.x / 16) * 16
	position.y = round(position.y / 16) * 16


func update_animation_from_state():
	if current_state == last_state:
		return

	last_state = current_state

	match current_state:
		BlockStates.EMERGING:
			_play_block_animation("%s_emerging" % block_color)
			if just_spawned:
				just_spawned = false
				await block_animations.animation_finished
				current_state = BlockStates.IDLE

		BlockStates.IDLE:
			block_area_collision.disabled = false
			_play_block_animation("%s_idle" % block_color)

		BlockStates.SPINNING:
			block_sparkles.play("Sparkle")
			block_effects.play("flash")
			_play_block_animation("%s_spinning" % block_color)

		BlockStates.PRESSED:
			block_area_collision.disabled = true
			block_sparkles.play("Sparkle")
			block_effects.play("flash")
			_play_block_animation("%s_pressed" % block_color)

		BlockStates.DESCENDING:
			block_effects.play("flash")
			block_area_collision.disabled = true
			block_sparkles.play("Sparkle")
			SceneTransition.white_flash()
			await block_sparkles.animation_finished
			CinematicManager._wait(8.0)
			_play_block_animation("%s_descending" % block_color)
			await block_animations.animation_finished
			current_state = BlockStates.RESOLVED

		BlockStates.RESOLVED:
			_play_hole_color("no_hole")
			_play_block_animation("no_block")
			block_area_collision.disabled = true
			set_collision_layer(0)
			set_collision_mask(0)
			if block_area:
				block_area.set_deferred("monitoring", false)

		_:
			push_warning("⚠️ Estado desconocido del bloque: %s" % str(current_state))


func _play_block_animation(anim_name: String):
	if block_animations and block_animations.sprite_frames.has_animation(anim_name):
		block_animations.play(anim_name)
	else:
		push_warning("⚠️ Animación no encontrada: %s" % anim_name)


func _play_hole_color(anim_name: String):
	if block_hole and block_hole.sprite_frames.has_animation(anim_name):
		block_hole.play(anim_name)


func advance_state():
	match current_state:
		BlockStates.IDLE:
			current_state = BlockStates.SPINNING
		BlockStates.SPINNING:
			current_state = BlockStates.PRESSED
		BlockStates.PRESSED:
			print("⛔ Este bloque ya fue presionado completamente.")
		BlockStates.RESOLVED:
			print("✔️ Puzzle resuelto, este bloque ya no se puede tocar.")


func mark_as_resolved():
	CinematicManager._wait(3.0)
	current_state = BlockStates.DESCENDING


func puzzle_completed():
	CinematicManager._wait(1.0)
	current_state = BlockStates.RESOLVED


func reset_state():
	# efecto visual de reset
	if block_effects:
		block_effects.play("reset_flash")

	# restaurar estado lógico
	current_state = BlockStates.IDLE
	last_state = null # fuerza update en el próximo frame
	just_spawned = false
	triggered = false

	# restaurar hole (hitbox visual)
	_play_hole_color("%s_blockHole" % hole_color)

	# restaurar area/colisiones
	if block_area:
		block_area.reset_trigger()
		# restaurar monitoring con deferred para no romper el árbol si se llama durante unpack
		block_area.set_deferred("monitoring", _original_area_monitoring)

	if block_area_collision:
		block_area_collision.disabled = false

	# restaurar collision layer/mask con deferred
	set_deferred("collision_layer", _original_collision_layer)
	set_deferred("collision_mask", _original_collision_mask)

	# reproducir animación idle ya que forzamos last_state = null
	_play_block_animation("%s_idle" % block_color)
