extends Node
class_name DamageCalculator

static func calculate_total_damage(user, target, base_damage: int, scaling_stat: String, scaling_factor: float, damage_type: String) -> int:
	var attacker_stat = user.get_stat(scaling_stat)
	var raw_damage = base_damage + (attacker_stat * scaling_factor)
	return apply_defense(raw_damage, target, damage_type)

static func apply_defense(raw_damage: float, target, damage_type: String) -> int:
	var defense_value := 0
	match damage_type:
		"Physical":
			defense_value = target.get_stat("def")
		"Magic":
			defense_value = target.get_stat("sp_def")
	return max(1, int(raw_damage - defense_value * 0.5))
