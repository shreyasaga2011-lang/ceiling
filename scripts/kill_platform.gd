extends Area2D
@onready var cpu_particles_2d_2: CPUParticles2D = $CPUParticles2D2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	cpu_particles_2d_2.emitting = true
	await get_tree().create_timer(0.4).timeout
	get_tree().reload_current_scene()
