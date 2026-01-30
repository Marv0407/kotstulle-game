extends Node2D
signal clicked(slot)

@onready var sprite = $Sprite2D
@onready var btn = $Button
var is_targetable: bool = false

func _ready() -> void:
	var tween = create_tween()
	scale = Vector2.ZERO
	tween.tween_property(self, "scale", Vector2(1,1), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_button_pressed() -> void:
	clicked.emit(self)

func _on_button_mouse_entered() -> void:
	if sprite.modulate == Color.WHITE and is_targetable:
		sprite.modulate = Color(1.2, 1.2, 1.2)

func _on_button_mouse_exited() -> void:
	if sprite.modulate != Color.YELLOW and is_targetable:
		sprite.modulate = Color.WHITE
