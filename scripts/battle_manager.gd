extends Node
class_name  BattleManager

#region VARIABLES
@export var party_data: Array[CharData]
@export var enemy_data: Array[CharData]
@export var turn_order_container: HBoxContainer
@export var enemy_scene: PackedScene = preload("res://scenes/EnemySlot.tscn")
@export var damage_popup: PackedScene = preload("res://scenes/DamagePopup.tscn")
var party: Array[BattleCharacter] = []
var enemies: Array[BattleCharacter] = []
var turn_order: Array[BattleCharacter] = []
var current_turn_index : int
enum BattleState { 
	START,
	PLAYER_TURN,
	TARGET_SELECT,
	ENEMY_TURN,
	END
}
var state := BattleState.START
@onready var particelSpawner = $"../DebugUI/HBoxContainer/ParticelSpawner"
@onready var spawn_point = $"../DebugUI/EnemyPositionAnchor/EnemyPartyContainer"
@onready var party_panel: PartyHUD = $"../DebugUI/CanvasLayer/PartyMenuContainer/ColorRect/PartyHUDContainer"
#endregion

####################
# Functions
####################
func start_battle(): 

	party.clear()
	enemies.clear()
	turn_order.clear()

	for child in spawn_point.get_children():
		child.queue_free()

	for data in party_data:
		var bc = BattleCharacter.new()
		bc.setup(data)
		party.append(bc)
	
	party_panel.populate(party)
	
	for data in enemy_data:
		var bc = BattleCharacter.new()
		bc.setup(data)
		enemies.append(bc)

	var count = enemies.size()
	var spacing = 250.0

	for i in range(count):
		# Create slot
		var new_slot = enemy_scene.instantiate()
		spawn_point.add_child(new_slot)

		# Dynamic positioning of each slot
		var x_offset = (i - (count - 1) / 2.0) * spacing
		new_slot.position = Vector2(x_offset, 0)

		# get sprites from resource 
		var resource_sprite = enemies[i].data.sprite
		var sprite_node = new_slot.get_node("Sprite2D")
		sprite_node.texture = resource_sprite
		enemies[i].battle_node = new_slot

	calculate_turn_order()
	current_turn_index = 0
	refresh_turn_order_ui()

	print("--- Kampf beginnt ---")
	process_battle_loop()

func process_turn(): 
	var actor = get_current_actor()
	process_status_effects(actor)
	if is_battle_over():
		return

	if not actor.is_alive():
		next_turn()
		return

	if actor in party:
		start_player_turn(actor)
	else:
		start_enemy_turn(actor)

func start_player_turn(actor):
	state = BattleState.PLAYER_TURN
	print("Player turn: ", actor.data.name)

func start_enemy_turn(actor: BattleCharacter):
	state = BattleState.ENEMY_TURN

	var selected_skill = actor.data.skills[0] 
	var config = {"target_pool": "enemies", "state": "alive", "selector": "random", "count": 1}
	var targets_array = get_targets_dynamic(actor, config)

	if not targets_array.is_empty():
		var first_target = targets_array[0]
		execute_skill(actor, selected_skill, first_target)

func execute_skill(user: BattleCharacter, skill: SkillData, target: BattleCharacter):

	for i in range(skill.hit_count):
		var damage = calculate_damage(user, target, skill)
		apply_skill_effects(user, target, damage, skill)
		if skill.hit_count > 1:
			await get_tree().create_timer(skill.delay_between_hits).timeout

	if skill.status_to_apply and randf() * 100 < skill.chance_to_apply:
		apply_status_effect(target, skill.status_to_apply)

	await get_tree().create_timer(0.8).timeout
	
	next_turn()
	process_turn()

func calculate_turn_order():
	turn_order.clear()
	turn_order.append_array(party)
	turn_order.append_array(enemies)
	turn_order.sort_custom(
		func(a, b): return a.data.speed > b.data.speed
		)

func get_current_actor() -> BattleCharacter:
	return turn_order[current_turn_index]

func next_turn():
	var checked := 0

	while checked < turn_order.size():
		current_turn_index += 1
		if current_turn_index >= turn_order.size():
			current_turn_index = 0

		var actor = get_current_actor()
		if actor.is_alive():
			refresh_turn_order_ui()
			return

		checked += 1

	end_battle(true)

func attack(attacker: BattleCharacter, target: BattleCharacter):
	var damage = max(attacker.data.atk - target.data.def, 1)
	target.current_hp -= damage

	if target in party:
		for ui in party_panel.get_children():
			if ui.character == target:
				ui.update_hp()
				break

	if target.battle_node:
		var tween = create_tween()
		tween.tween_property(target.battle_node, "modulate", Color.RED, 0.1)
		tween.tween_property(target.battle_node, "modulate", Color.WHITE, 0.1)
		var particel_pos = target.battle_node.global_position
		particelSpawner.global_position = particel_pos
		particelSpawner.z_index = 3
		particelSpawner.restart()
		spawn_damage_number(target.battle_node.global_position, damage)

	if target.current_hp <= 0:
		print(target.data.name, " wurde besiegt!")
		despawn_enemy_visual(target)

func debug_player_attack():
	if state != BattleState.PLAYER_TURN:
		return

	var actor = get_current_actor()
	var targets = get_alive_enemies()
	if targets.is_empty():
		end_battle(true)
		return

	attack(actor, targets[0])

	await get_tree().create_timer(0.8).timeout

	next_turn()
	process_turn()

func process_battle_loop():
	if is_battle_over():
		return

	process_turn()

####################
# Helpers
####################
#region TURN STATES
func is_player_turn() -> bool:
	var actor = get_current_actor()
	return actor.is_player_controlled

func enter_player_turn():
	state = BattleState.PLAYER_TURN
	emit_signal("player_turn_started", get_current_actor())

func enter_enemy_turn():
	state = BattleState.ENEMY_TURN

	var enemy = get_current_actor()
	var target = get_alive_party()
	attack(enemy, target)
	next_turn()

func refresh_turn_order_ui():
	if not turn_order_container: return

	for child in turn_order_container.get_children():
		child.queue_free()

	for i in range(turn_order.size()):
		var character = turn_order[i]
		if not character.is_alive(): continue
		var label := Label.new()
		var portrait := Image.new()
		label.text = character.data.name
		portrait = character.data.portrait

		if i == current_turn_index:
			label.text = "> " + label.text
			label.add_theme_color_override("font_color", Color.YELLOW)

		turn_order_container.add_child(label)

func end_battle(player_won: bool):
	state = BattleState.END
	if player_won:
		var _sum_exp = 0
		for e in enemies: _sum_exp += e.data.xp
#endregion

#region VISUALS
func despawn_enemy_visual(character: BattleCharacter):
	if character.battle_node:
		# TODO insert other/different animations here later
		var tween = create_tween()
		tween.tween_property(character.battle_node, "modulate:a", 0, 0.5)
		tween.tween_property(character.battle_node, "scale", Vector2.ZERO, 0.5)
		tween.finished.connect(func(): character.battle_node.queue_free())

func spawn_damage_number(pos: Vector2, value: int):
	var dmg_node = damage_popup.instantiate()
	get_tree().current_scene.add_child(dmg_node)

	# some randomness in spawn logic
	var random_offset = Vector2(randf_range(-20, 20), randf_range(-10, 10))
	dmg_node.global_position = pos + random_offset

	# TODO Future crit colors or other colors in case of big dmg
	var color = Color.WHITE
	if value > 50: color = Color.YELLOW #FIXME example code

	dmg_node.setup(value, color)

func apply_skill_effects(attacker: BattleCharacter, target: BattleCharacter, damage: int, skill: SkillData):
	target.current_hp -= damage
	print(attacker.data.name, " nutzt ", skill.skill_name, " gegen ", target.data.name, " für ", damage, " Schaden.")

	# UI Update für Party
	if target in party:
		for ui in party_panel.get_children():
			if ui.character == target:
				ui.update_hp()
				break

	# Visuals am Ziel
	if target.battle_node:
		var tween = create_tween()
		tween.tween_property(target.battle_node, "modulate", Color.RED, 0.1)
		tween.tween_property(target.battle_node, "modulate", Color.WHITE, 0.1)
		
		# Partikel & Damage Popup
		particelSpawner.global_position = target.battle_node.global_position
		particelSpawner.restart()
		spawn_damage_number(target.battle_node.global_position, damage)

	if target.current_hp <= 0:
		despawn_enemy_visual(target)
#endregion

#region LOGIC
func get_targets_dynamic(user: BattleCharacter, config: Dictionary) -> Array[BattleCharacter]:
	var pool: Array[BattleCharacter] = []
	
	# --- 1. POOL (Wer?) ---
	var is_player = (user in party)
	match config.get("target_pool", "enemies"):
		"enemies": pool = enemies if is_player else party
		"friends": pool = party if is_player else enemies
		"all": pool = party + enemies
		"user": return [user]

	# --- 2. STATE (Filter) ---
	match config.get("state", "alive"):
		"alive": pool = pool.filter(func(c): return c.is_alive())
		"dead":  pool = pool.filter(func(c): return not c.is_alive())
		"any":   pass # Filter überspringen

	# --- 3. SELECTOR (Wie viele und welche?) ---
	var count = config.get("count", 1)
	var final_targets: Array[BattleCharacter] = []
	
	match config.get("selector", "all"):
		"all": 
			final_targets = pool
		"random":
			pool.shuffle()
			final_targets = pool.slice(0, count)
		"manual":
			# Hier später UI-Targeting logik
			pass 

	return final_targets

func calculate_damage(attacker: BattleCharacter, target: BattleCharacter, skill: SkillData) -> int:
	var attacker_stat = attacker.data.get(skill.scaling_stat)
	var raw_damage = skill.base_damage + (attacker_stat * skill.scaling_factor)

	if skill.can_crit:
		var crit_chance = attacker.data.luck * 0.5 
		if randf() * 100 < crit_chance:
			raw_damage *= skill.crit_multiplier
			print("KRITISCHER TREFFER!") # Später: Signal für gelbe Zahlen

	var defense = target.data.def
	@warning_ignore("integer_division")
	var final_damage = int(raw_damage) - (defense / 2)

	if skill.damage_type == "Heal":
		return -int(raw_damage) 

	return max(1, final_damage) # Mindestens 1 Schaden

func apply_status_effect(target: BattleCharacter, effect_data: StatusEffectData):
	var existing_effect = null
	for e in target.active_effects:
		if e.effect_name == effect_data.effect_name:
			existing_effect = e
			break

	if existing_effect:
		existing_effect.duration = effect_data.duration

		if existing_effect.is_stackable:
			existing_effect.current_stacks = min(
				existing_effect.current_stacks + 1, 
				existing_effect.stack_cap
			)
			print(target.data.name, ": ", existing_effect.effect_name, " gestapelt auf ", existing_effect.current_stacks)
	else:
		var new_effect = effect_data.duplicate()
		new_effect.current_stacks = 1
		target.active_effects.append(new_effect)
		print(target.data.name, " leidet nun unter: ", new_effect.effect_name)
	
	# TODO: kleines Icon über dem Gegner spawnen

func process_status_effects(actor: BattleCharacter):
	for i in range(actor.active_effects.size() - 1, -1, -1):
		var effect = actor.active_effects[i]

		if effect.type == "DoT" and effect.damage_per_turn > 0:
			var total_dot_damage = effect.damage_per_turn * effect.current_stacks
			apply_skill_effects(null, actor, total_dot_damage, null)

		effect.duration -= 1
		if effect.duration <= 0:
			actor.active_effects.remove_at(i)

func get_alive_party() -> Array[BattleCharacter]:
	return party.filter(func(c): return c.is_alive())

func get_alive_enemies() -> Array[BattleCharacter]:
	return enemies.filter(func(c): return c.is_alive())

func is_battle_over() -> bool:
	return get_alive_party().is_empty() or get_alive_enemies().is_empty()
#endregion
