extends CharacterBody2D

var can_wall_jump = false
var jumped_from_wall = false
var wall_jump_used = false
var roll_speed = 0.0
const SPEED = 1500.0
const JUMP_VELOCITY = -1500.0
const JUMP_GRAVITY = 1800.0
const FALL_GRAVITY = 3600.0
const WALL_SLIDE_GRAVITY = 200.0
const WALL_SLIDE_MAX = 300.0
const HEX_RADIUS = 300.0

@onready var sprite = $Sprite2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		if is_on_wall():
			jumped_from_wall = false
			if velocity.y > 0:
				velocity.y += WALL_SLIDE_GRAVITY * delta
				velocity.y = min(velocity.y, WALL_SLIDE_MAX)
			else:
				velocity.y += JUMP_GRAVITY * delta
			can_wall_jump = true
		else:
			can_wall_jump = false
			if velocity.y > 0 and jumped_from_wall:
				velocity.y += WALL_SLIDE_GRAVITY * delta
				velocity.y = min(velocity.y, WALL_SLIDE_MAX)
			else:
				var grav = FALL_GRAVITY if velocity.y > 0 else JUMP_GRAVITY
				velocity.y += grav * delta
	else:
		jumped_from_wall = false
		wall_jump_used = false  # reset on landing

	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		elif is_on_wall() and not wall_jump_used:
			jumped_from_wall = true
			wall_jump_used = true
			velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	roll_speed = lerp(roll_speed, velocity.x / HEX_RADIUS, 10.0 * delta)
	sprite.rotation += roll_speed * delta
