extends CharacterBody2D

@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D
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

func update_particles() -> void:
	if is_on_floor():
		cpu_particles_2d.emitting = true
		var normal = get_floor_normal()
		cpu_particles_2d.position = -normal * HEX_RADIUS / 10.0
		cpu_particles_2d.direction = -normal
		cpu_particles_2d.initial_velocity_min = abs(velocity.x) * 0.1
		cpu_particles_2d.initial_velocity_max = abs(velocity.x) * 0.2
		cpu_particles_2d.gravity = Vector2(0, 200)
	elif is_on_wall():
		cpu_particles_2d.emitting = true
		var normal = get_wall_normal()
		cpu_particles_2d.position = -normal * HEX_RADIUS / 10.0
		cpu_particles_2d.direction = -normal
		cpu_particles_2d.initial_velocity_min = abs(velocity.y) * 0.1
		cpu_particles_2d.initial_velocity_max = abs(velocity.y) * 0.2
		cpu_particles_2d.gravity = Vector2(normal.x * -200, 200)
	elif is_on_ceiling():
		cpu_particles_2d.emitting = true
		cpu_particles_2d.position = Vector2(0, -HEX_RADIUS / 10.0)
		cpu_particles_2d.direction = Vector2.UP
		cpu_particles_2d.initial_velocity_min = abs(velocity.x) * 0.1
		cpu_particles_2d.initial_velocity_max = abs(velocity.x) * 0.2
		cpu_particles_2d.gravity = Vector2(0, -200)
	else:
		cpu_particles_2d.emitting = false

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
		wall_jump_used = false

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

	update_particles()

	roll_speed = lerp(roll_speed, velocity.x / HEX_RADIUS, 10.0 * delta)
	sprite.rotation += roll_speed * delta
