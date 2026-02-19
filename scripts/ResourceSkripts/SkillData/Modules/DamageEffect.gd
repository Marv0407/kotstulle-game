extends SkillEffect
class_name DamageEffect

@export var base_damage: int = 10
@export_enum("atk", "sp_atk", "luck", "speed") var scaling_stat: String = "atk"
@export_range(0.0, 5.0) var scaling_factor: float = 1.0
@export_enum("Physical", "Magic", "True") var damage_type: String = "Physical"
@export var can_crit: bool = true
@export var crit_multiplier: float = 1.5
@export var hit_count: int = 1
@export var delay_between_hits: float = 0.0

func apply(user, targets: Array, context):
	for i in hit_count:
		for target in targets:
			if not target.is_alive():
				continue
			var attacker_stat = user.data.get(scaling_stat)
			var raw_damage = base_damage + (attacker_stat * scaling_factor)
			if can_crit:
				var crit_chance = user.data.luck * 0.5
				if randf() * 100 < crit_chance:
					raw_damage *= crit_multiplier
					context.log("KRITISCHER TREFFER!", Color.YELLOW)
			var final_damage = calculate_damage_after_defense(raw_damage, target)
			context.apply_damage(user, target, final_damage)

	if delay_between_hits > 0: 
		await context.manager.get_tree().create_timer(delay_between_hits).timeout

func calculate_damage_after_defense(raw_damage, target):
	match damage_type:
		"Physical":
			return max(1, raw_damage - target.get_def() / 2)
		"Magic":
			return max(1, raw_damage - target.get_sp_def() / 2)
		"True":
			return raw_damage
		_:
			return raw_damage
