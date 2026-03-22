extends Node

var death = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass

func die():
	death = true
	await get_tree().create_timer(0.1).timeout
	death = false
	
