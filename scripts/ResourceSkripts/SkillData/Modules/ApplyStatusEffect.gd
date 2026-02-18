extends SkillEffect
class_name ApplyStatusEffect

@export var status: StatusEffectData
@export_range(0,100) var chance: float = 100.0

func apply(user, targets: Array, context):
	for target in targets:
		if randf() * 100 <= chance:
			context.apply_status(user, target, status)
