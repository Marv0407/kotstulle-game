extends Control

@export var active_color := Color.WHITE
@export var inactive_color := Color(0.4, 0.4, 0.4)
@export var dead_color := Color(0.2, 0.2, 0.2)

@export var active_scale := Vector2(1.2, 1.2)
@export var inactive_scale := Vector2.ONE
@export var tween_time := 0.15

@onready var portrait: TextureRect = $Portrait
@onready var frame: NinePatchRect = $Frame

var character: BattleCharacter
var tween: Tween

func setup(c: BattleCharacter):
	character = c
	if portrait and character.data.portrait:
		portrait.texture = character.data.portrait
	set_inactive(true)

func set_active():
	if not character or not character.is_alive():
		return

	_kill_tween()
	$Frame.visible = true

	tween = create_tween()
	tween.tween_property(self, "scale", active_scale, tween_time)
	tween.parallel().tween_property(self, "modulate", active_color, tween_time)

func set_inactive(immediate := false):
	_kill_tween()
	$Frame.visible = false

	if immediate:
		scale = inactive_scale
		modulate = inactive_color
		return

	tween = create_tween()
	tween.tween_property(self, "scale", inactive_scale, tween_time)
	tween.parallel().tween_property(self, "modulate", inactive_color, tween_time)

func set_dead():
	_kill_tween()
	scale = inactive_scale
	modulate = dead_color
	$Frame.visible = false
	portrait.visible = false
	self.hide()

func _kill_tween():
	if tween and tween.is_valid():
		tween.kill()
	tween = null
