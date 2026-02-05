extends Control

@onready var portrait: TextureRect = $Portrait
@onready var frame: NinePatchRect = $Frame

var character: BattleCharacter

func setup(char: BattleCharacter, is_active: bool):
	character = char
	portrait.texture = char.data.portrait
	set_active(is_active)

func set_active(active: bool):
	frame.visible = active

	var tween = create_tween()
	if active:
		tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.15)
		tween.tween_property(self, "modulate", Color.WHITE, 0.15)
	else:
		tween.tween_property(self, "scale", Vector2.ONE, 0.15)
		tween.tween_property(self, "modulate", Color(0.6,0.6,0.6), 0.15)
