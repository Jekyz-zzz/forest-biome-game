class_name BinarPlayer
extends CharacterBody2D
## Karakter pemain (Binar).
##
## control_mode:
##   PLAYER -> dikendalikan input (scene eksplorasi)
##   LOCKED -> input dikunci, meluncur pelan-pelan berhenti (saat dialog/popup)
##   SCRIPT -> dikendalikan penuh oleh skrip mini-game (mis. lari dari harimau)

enum ControlMode { PLAYER, LOCKED, SCRIPT }

const SPEED = 260.0
const JUMP_VELOCITY = -430.0
const FALL_LIMIT = 600.0

var control_mode := ControlMode.PLAYER
var spawn_position: Vector2
var facing := 1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	spawn_position = global_position
	sprite.play("idle")


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match control_mode:
		ControlMode.PLAYER:
			if Input.is_action_just_pressed("jump") and is_on_floor():
				velocity.y = JUMP_VELOCITY
			var direction := Input.get_axis("move_left", "move_right")
			if absf(direction) > 0.01:
				velocity.x = direction * SPEED
			else:
				velocity.x = move_toward(velocity.x, 0.0, SPEED)
		ControlMode.LOCKED:
			velocity.x = move_toward(velocity.x, 0.0, SPEED)
		ControlMode.SCRIPT:
			pass  # kecepatan diatur langsung oleh skrip mini-game

	move_and_slide()
	_update_animation()

	if global_position.y > FALL_LIMIT:
		global_position = spawn_position
		velocity = Vector2.ZERO


func _update_animation() -> void:
	if absf(velocity.x) > 8.0:
		facing = signf(velocity.x)
	sprite.flip_h = facing < 0.0
	if not is_on_floor():
		if sprite.animation != &"jump":
			sprite.play("jump")
	elif absf(velocity.x) > 8.0:
		if sprite.animation != &"run":
			sprite.play("run")
	elif sprite.animation != &"idle":
		sprite.play("idle")
