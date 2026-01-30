extends Node2D
signal clicked(slot)

@onready var sprite = $Sprite2D
@onready var btn = $Button
var is_targetable: bool = false

func _ready() -> void:
	var tween = create_tween()
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2(1,1), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_callback(self.breathing_effect)

func breathing_effect():
	var tween = create_tween().set_loops()
	var duration = randf_range(1.5, 2.2)
	tween.tween_property(sprite, "scale", Vector2(1.04, 0.96), duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

func _on_button_pressed() -> void:
	clicked.emit(self)

func _on_button_mouse_entered() -> void:
	if sprite.modulate == Color.WHITE and is_targetable:
		sprite.modulate = Color(1.2, 1.2, 1.2)

func _on_button_mouse_exited() -> void:
	if sprite.modulate != Color.YELLOW and is_targetable:
		sprite.modulate = Color.WHITE
