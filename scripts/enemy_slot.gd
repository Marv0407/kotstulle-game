extends Node2D

func _ready() -> void:
	var tween = create_tween()
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2(1,1), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
