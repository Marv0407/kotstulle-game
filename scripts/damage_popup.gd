extends Node2D

func setup(value: int, color: Color = Color.WHITE):
	var label = $Label
	label.text = str(value)
	label.add_theme_color_override("font_color", color)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(
		self, 
		"position", 
		position + Vector2(0, -80), 
		0.7).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
		
	tween.tween_property(self, "modulate:a", 0.0, 0.7)
	tween.chain().tween_callback(queue_free)
