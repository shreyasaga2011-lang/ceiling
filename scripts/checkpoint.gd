extends Area2D

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass


func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int) -> void:
	checkpointglobal.checkX = position.x
	checkpointglobal.checkY = position.y
	queue_free()
