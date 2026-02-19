extends SkillEffect
class_name PresentationEffect

@export var screen_tint: Color
@export var tint_duration: float = 0.3
@export var sfx: AudioStream
@export var play_on_each_hit: bool = false

func apply(user, targets, context):
	if screen_tint != Color(0,0,0,0):
		context.manager.flash_screen(screen_tint, tint_duration)
	if sfx:
		context.manager.play_skill_sfx(sfx)
