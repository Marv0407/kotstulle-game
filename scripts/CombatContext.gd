extends RefCounted
class_name CombatContext

var manager

func _init(battle_manager):
	manager = battle_manager

func apply_damage(user, target, amount):
	manager.apply_skill_effects(user, target, amount, null)

func apply_status(user, target, status):
	manager.apply_status_effect(user, target, status)

func log(text, color):
	manager.post_log(text, color)
