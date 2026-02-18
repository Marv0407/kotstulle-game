extends SkillEffect
class_name DamageEffect

@export var base_damage: int = 10
@export_enum("atk", "sp_atk", "luck", "speed") var scaling_stat: String = "atk"
@export_range(0.0, 5.0) var scaling_factor: float = 1.0
@export_enum("Physical", "Magic", "True") var damage_type: String = "Physical"

@export var can_crit: bool = true
@export var crit_multiplier: float = 1.5

@export var hit_count: int = 1

func apply(user, targets: Array, context):
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

		var defense = target.data.def
		var final_damage = int(raw_damage) - (defense / 2)
		final_damage = max(1, final_damage)

		context.apply_damage(user, target, final_damage)
