extends CharacterBody2D

@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D
@onready var sprite = $Sprite2D

# --- TUNED PHYSICS ---
const SPEED = 1500.0
const ACCEL = 6000.0
const DECEL = 4000.0
const JUMP_VELOCITY = -2800.0 
const GRAVITY = 3600.0
const HEX_RADIUS = 300.0

# --- SENSOR CONFIG ---
const SENSOR_COUNT = 16        
const SENSOR_DIST = 46.0       
const SAFE_MARGIN = 10.0      
const FLOOR_ANGLE_LIMIT = 45.0 
const SIDE_ANGLE_LIMIT = 45.0  

# --- NEW: ANTI-ROCKET STATE ---
var jump_buffer_timer = 0.0
var ground_jump_available = 0
var wall_jump_available = 0
var last_jump_side = 0 # 0 = None, 1 = Left, 2 = Right
var wall_jump_cooldown = 0.0

func _physics_process(delta: float) -> void:
	# 1. TIMERS
	jump_buffer_timer -= delta
	wall_jump_cooldown -= delta
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = 0.15

	# 2. RADIAL SENSOR SCAN
	var scan_data = perform_360_sensor_scan()
	
	var is_near_floor = is_on_floor() or scan_data["floor_detected"]
	var is_near_left  = scan_data["left_detected"]
	var is_near_right = scan_data["right_detected"]
	var is_near_wall  = is_on_wall() or is_near_left or is_near_right

	# 3. RECHARGE & RESET
	if is_near_floor:
		ground_jump_available = 1
		wall_jump_available = 1
		last_jump_side = 0 # Reset side lock on ground
	elif is_near_wall:
		wall_jump_available = 1

	# 4. HORIZONTAL MOVEMENT
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, DECEL * delta)

	# 5. THE 50% SPEED WALL SLIDE
	if is_near_floor:
		if velocity.y > 0: velocity.y = 200.0 
	elif is_near_wall and velocity.y > 0:
		velocity.y += (GRAVITY * 0.5) * delta
	else:
		velocity.y += GRAVITY * delta

	# 6. JUMP EXECUTION (The "Anti-Rocket" Logic)
	if jump_buffer_timer > 0 and wall_jump_cooldown <= 0:
		if is_near_floor and ground_jump_available > 0:
			execute_jump("floor", false, false)
		# Only jump if we are touching a NEW side OR if we've started falling
		elif is_near_left and wall_jump_available > 0 and (last_jump_side != 1 or velocity.y > 0):
			execute_jump("wall", false, true)
		elif is_near_right and wall_jump_available > 0 and (last_jump_side != 2 or velocity.y > 0):
			execute_jump("wall", true, false)

	move_and_slide()

	# 7. VISUALS
	sprite.rotation += (velocity.x / HEX_RADIUS) * delta
	update_particles()

# --- THE PUNCH-THROUGH SCANNER ---
func perform_360_sensor_scan() -> Dictionary:
	var results = {"floor_detected": false, "left_detected": false, "right_detected": false}
	for i in range(SENSOR_COUNT):
		var angle_rad = deg_to_rad(i * (360.0 / SENSOR_COUNT))
		var direction = Vector2(cos(angle_rad), sin(angle_rad))
		var test_start_pos = global_transform.translated(-direction * SAFE_MARGIN)
		var test_vector = direction * (SENSOR_DIST + SAFE_MARGIN)
		
		if test_move(test_start_pos, test_vector):
			var angle_deg = fposmod(rad_to_deg(angle_rad), 360.0)
			if angle_deg > (90 - FLOOR_ANGLE_LIMIT) and angle_deg < (90 + FLOOR_ANGLE_LIMIT):
				results["floor_detected"] = true
			if angle_deg > (180 - SIDE_ANGLE_LIMIT) and angle_deg < (180 + SIDE_ANGLE_LIMIT):
				results["left_detected"] = true
			if angle_deg < SIDE_ANGLE_LIMIT or angle_deg > (360 - SIDE_ANGLE_LIMIT):
				results["right_detected"] = true
	return results

# --- JUMP EXECUTION (With Cooldown and Side Memory) ---
func execute_jump(type: String, hit_right: bool, hit_left: bool) -> void:
	jump_buffer_timer = 0.0
	
	if type == "floor":
		velocity.y = JUMP_VELOCITY
		ground_jump_available = 0
		last_jump_side = 0
	else:
		velocity.y = JUMP_VELOCITY * 0.8
		wall_jump_available = 0
		wall_jump_cooldown = 0.1 # 100ms prevents "machine gun" jumping
		
		if hit_right:
			last_jump_side = 2
			global_position.x -= 20.0 # Push further away
			velocity.x = -SPEED * 1.2 # Stronger kick
		elif hit_left:
			last_jump_side = 1
			global_position.x += 20.0 
			velocity.x = SPEED * 1.2

# --- PARTICLE LOGIC ---
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
