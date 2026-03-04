extends SkillEffect
class_name BlizzardEffect

@export var base_damage := 20
@export var scaling_factor := 1.2
@export var scaling_stat := "sp_atk"
@export var damage_type := "Magic"
@export var hit_delay := 0.3
@export var final_hit_delay := 0.9
@export var hit_sfx: AudioStream
@export var final_hit_sfx: AudioStream
@export var skill_sfx: AudioStream
@export var screen_tint := Color(0.6, 0.8, 1.0, 0.4)

func apply(user, targets, context):
	if skill_sfx:
		context.manager.play_skill_sfx(skill_sfx)
	context.manager.flash_screen(screen_tint, 0.6)
	var damage_map := {}
	for target in targets:
		if not target.is_alive():
			continue

		var total = DamageCalculator.calculate_total_damage(
			user,
			target,
			base_damage,
			scaling_stat,
			scaling_factor,
			damage_type
		)

		var hit1 = int(total * 0.10)
		var hit2 = int(total * 0.10)
		var hit3 = int(total * 0.10)
		var hit4 = int(total * 0.10)
		var hit5 = total - hit1 - hit2 - hit3 - hit4
		damage_map[target] = [hit1, hit2, hit3, hit4, hit5]

	# ---- HIT 1 ----
	await apply_hit_phase(user, damage_map, 0, context)
	await context.wait(hit_delay)

	# ---- HIT 2 ----
	await apply_hit_phase(user, damage_map, 1, context)
	await context.wait(hit_delay)

	# ---- HIT 3 ----
	await apply_hit_phase(user, damage_map, 2, context)
	await context.wait(hit_delay)
	
	# ---- HIT 4 ----
	await apply_hit_phase(user, damage_map, 3, context)
	await context.wait(final_hit_delay)
	
	# ---- HIT 5 ----
	await apply_hit_phase(user, damage_map, 4, context, true)

func apply_hit_phase(user, damage_map, hit_index: int, context, is_final := false):
	if is_final:
		if final_hit_sfx:
			context.manager.play_sfx(final_hit_sfx)
	else:
		if hit_sfx:
			context.manager.play_sfx(hit_sfx)
	if is_final:
		context.manager.flash_screen(Color(0.8, 0.9, 1.0, 0.6), 0.2)
		context.manager.shake_camera(0.4, 6.0)
	# --- DAMAGE ---
	for target in damage_map.keys():
		if not target.is_alive():
			continue
		var damage = damage_map[target][hit_index]
		context.apply_damage(user, target, damage)
