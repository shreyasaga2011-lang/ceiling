extends CharacterBody2D

@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D
@onready var sprite = $Sprite2D

# --- MOVEMENT ---
const SPEED = 1500.0
const ACCEL = 6000.0
const DECEL = 4000.0

# --- JUMP ---
const JUMP_VELOCITY = -1500.0
const JUMP_GRAVITY = 1800.0
const FALL_GRAVITY = 3600.0

# --- WALL ---
const WALL_SLIDE_GRAVITY = 150.0
const WALL_SLIDE_MAX = 120.0
const WALL_STICK_TIME = 0.15
const WALL_JUMP_FORCE = 1500.0

# --- GAME FEEL ---
const COYOTE_TIME = 0.12
const JUMP_BUFFER = 0.12

# --- VISUAL ---
const HEX_RADIUS = 300.0

# --- STATE ---
var roll_speed = 0.0
var wall_stick_timer = 0.0
var wall_jump_used = false

# --- TIMERS ---
var coyote_timer = 0.0
var jump_buffer_timer = 0.0


func _physics_process(delta: float) -> void:
	# --- TIMERS ---
	coyote_timer -= delta
	jump_buffer_timer -= delta

	# --- INPUT ---
	var direction := Input.get_axis("move_left", "move_right")

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER

	# --- FLOOR ---
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		wall_jump_used = false

	# --- WALL CHECK ---
	var on_wall = is_on_wall()
	var pushing_into_wall = false
	
	if on_wall:
		var normal = get_wall_normal()
		pushing_into_wall = sign(direction) == -sign(normal.x)

	# --- WALL STICK / SLIDE ---
	if on_wall and pushing_into_wall and velocity.y >= 0:
		if wall_stick_timer > 0:
			# FULL GRIP (no falling)
			velocity.y = 0
			wall_stick_timer -= delta
		else:
			# SLOW SLIDE
			velocity.y += WALL_SLIDE_GRAVITY * delta
			velocity.y = min(velocity.y, WALL_SLIDE_MAX)
	else:
		wall_stick_timer = WALL_STICK_TIME
		
		# NORMAL GRAVITY
		var grav = FALL_GRAVITY if velocity.y > 0 else JUMP_GRAVITY
		velocity.y += grav * delta

	# --- JUMPING ---
	if jump_buffer_timer > 0:
		# Normal jump (coyote)
		if coyote_timer > 0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0
			coyote_timer = 0
		
		# WALL JUMP (ONLY ONE)
		elif on_wall and pushing_into_wall and not wall_jump_used:
			wall_jump_used = true
			jump_buffer_timer = 0
			
			var normal = get_wall_normal()
			velocity.y = JUMP_VELOCITY
			velocity.x = -sign(normal.x) * WALL_JUMP_FORCE

	# --- HORIZONTAL MOVEMENT ---
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, DECEL * delta)

	# --- MOVE ---
	move_and_slide()

	# --- VISUALS ---
	update_particles()

	roll_speed = lerp(roll_speed, velocity.x / HEX_RADIUS, 15.0 * delta)
	sprite.rotation += roll_speed * delta


func update_particles() -> void:
	if is_on_floor():
		cpu_particles_2d.emitting = true
		var normal = get_floor_normal()
		cpu_particles_2d.position = -normal * HEX_RADIUS / 10.0
		cpu_particles_2d.direction = -normal
		
		var speed = clamp(abs(velocity.x), 0, 1000)
		cpu_particles_2d.initial_velocity_min = speed * 0.1
		cpu_particles_2d.initial_velocity_max = speed * 0.2
		
		cpu_particles_2d.gravity = Vector2(0, 200)

	elif is_on_wall():
		cpu_particles_2d.emitting = true
		var normal = get_wall_normal()
		cpu_particles_2d.position = -normal * HEX_RADIUS / 10.0
		cpu_particles_2d.direction = -normal
		
		var speed = clamp(abs(velocity.y), 0, 1000)
		cpu_particles_2d.initial_velocity_min = speed * 0.1
		cpu_particles_2d.initial_velocity_max = speed * 0.2
		
		cpu_particles_2d.gravity = Vector2(normal.x * -200, 200)

	elif is_on_ceiling():
		cpu_particles_2d.emitting = true
		cpu_particles_2d.position = Vector2(0, -HEX_RADIUS / 10.0)
		cpu_particles_2d.direction = Vector2.UP
		
		var speed = clamp(abs(velocity.x), 0, 1000)
		cpu_particles_2d.initial_velocity_min = speed * 0.1
		cpu_particles_2d.initial_velocity_max = speed * 0.2
		
		cpu_particles_2d.gravity = Vector2(0, -200)

	else:
		cpu_particles_2d.emitting = false
