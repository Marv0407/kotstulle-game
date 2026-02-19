extends SkillEffect
class_name MultiHitEffect

@export var hit_count: int = 3
@export var retarget_each_hit: bool = false
@export var inner_effect: SkillEffect

func apply(user, targets: Array, context):
	for i in hit_count:
		var current_targets = targets
		if retarget_each_hit:
			current_targets = context.retarget_random(user)
		await inner_effect.apply(user, current_targets, context)
