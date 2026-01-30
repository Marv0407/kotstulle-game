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
var pending_skill: SkillData
var pending_user: BattleCharacter
#@onready var particelSpawner = $"../DebugUI/HBoxContainer/ParticelSpawner"
@onready var spawn_point = $"../DebugUI/EnemyPositionAnchor/EnemyPartyContainer"
@onready var party_panel: PartyHUD = $"../DebugUI/CanvasLayer/PartyMenuContainer/ColorRect/PartyHUDContainer"
@onready var log_container = $"../DebugUI/CanvasLayer/PanelContainer/ScrollContainer/LogContainer"
@onready var skill_menu = $"../DebugUI/CanvasLayer/SkillMenu"
#endregion

func _ready():
	skill_menu.skill_selected.connect(_on_skill_chosen)
	skill_menu.canceled.connect(_on_skill_menu_canceled)
	skill_menu.hide()

####################
# Functions
####################
func start_battle(): 

	party.clear()
	enemies.clear()
	turn_order.clear()

	for child in spawn_point.get_children():
		child.queue_free()

	for i in range(party_data.size()):
		var data = party_data[i]
		
		if i == 0 and GameData.player_name != "":
			data = data.duplicate()
			data.name = GameData.player_name
		
		var bc = BattleCharacter.new()
		bc.setup(data)
		party.append(bc)

	#for data in party_data:
		#var bc = BattleCharacter.new()
		#bc.setup(data)
		#party.append(bc)
	#
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

		if new_slot.has_signal("clicked"):
			new_slot.clicked.connect(_on_target_clicked)

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
	set_player_ui_enabled(true)
	print("Player turn: ", actor.data.name)

func start_enemy_turn(actor: BattleCharacter):
	state = BattleState.ENEMY_TURN
	set_player_ui_enabled(false)
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
		apply_status_effect(user, target, skill.status_to_apply)

	await get_tree().create_timer(0.8).timeout
	
	next_turn()
	process_turn()

func execute_skill_aoe(user: BattleCharacter, skill: SkillData, targets: Array[BattleCharacter]):
	for i in range(skill.hit_count):
		for target in targets:
			if target.is_alive():
				var damage = calculate_damage(user, target, skill)
				apply_skill_effects(user, target, damage, skill)

				if i == skill.hit_count - 1:
					if skill.status_to_apply and randf() * 100 < skill.chance_to_apply:
						apply_status_effect(user, target, skill.status_to_apply)

		if skill.hit_count > 1:
			await get_tree().create_timer(skill.delay_between_hits).timeout
		else:
			await get_tree().create_timer(0.2).timeout

	await get_tree().create_timer(0.6).timeout
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
		#var particel_pos = target.battle_node.global_position
		#particelSpawner.global_position = particel_pos
		#particelSpawner.z_index = 3
		#particelSpawner.restart()
		spawn_damage_number(target.battle_node.global_position, damage)

	if target.current_hp <= 0:
		print(target.data.name, " wurde besiegt!")
		despawn_enemy_visual(target)

func debug_player_attack():
	if state != BattleState.PLAYER_TURN:
		return
	
	var actor = get_current_actor()
	var targets = get_alive_enemies()
	
	if not targets.is_empty():
		state = BattleState.TARGET_SELECT

		var skill = load("res://ressources/skills/PlayerAttack.tres")
		
		if skill:
			start_target_selection(get_current_actor(), skill)
			
		else:
			# Fallback
			attack(actor, targets[0])
			await get_tree().create_timer(0.8).timeout
			next_turn()
			process_turn()

func process_battle_loop():
	if is_battle_over():
		return

	process_turn()

func start_target_selection(user: BattleCharacter, skill: SkillData):
	state = BattleState.TARGET_SELECT
	pending_user = user
	pending_skill = skill
	highlight_potential_targets(true)

func _on_target_clicked(target_node):
	if state != BattleState.TARGET_SELECT:
		return
	
	var target_character = null
	for e in enemies:
		if e.battle_node == target_node:
			target_character = e
			break
	
	if target_character and target_character.is_alive():
		highlight_potential_targets(false)
		state = BattleState.ENEMY_TURN
		execute_skill(pending_user, pending_skill, target_character)

####################
# Helpers
####################
#region TURN STATES

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

func set_player_ui_enabled(enabled: bool):
	var action_menu = $"../DebugUI/CanvasLayer/PartyMenuContainer/ActionsContainer/ColorRect/VBoxContainer"
	
	for child in action_menu.get_children():
		if child is Button:
			child.disabled = !enabled

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

func post_log(text: String, color: Color = Color.WHITE):
	print(text) 

	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", color)
	#label.autowrap_mode = TextServer.AUTOWRAP_WORD
	log_container.add_child(label)
	await get_tree().process_frame
	log_container.get_parent().scroll_vertical = log_container.size.y

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
	if attacker and skill:
		post_log(attacker.data.name + " nutzt " + skill.skill_name + " für " + str(damage) + " Schaden.", Color.WHITE)
	else:
		post_log(target.data.name + " erleidet " + str(damage) + " Schaden durch Effekt.", Color.LIGHT_CORAL)
	
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
		if skill != null and skill.vfx_scene:
			var vfx_instance = skill.vfx_scene.instantiate()
			get_tree().current_scene.add_child(vfx_instance)
			vfx_instance.global_position = target.battle_node.global_position
			vfx_instance.emitting = true
			
		spawn_damage_number(target.battle_node.global_position, damage)

	if target.current_hp <= 0:
		post_log(target.data.name + " wurde besiegt!", Color.ORANGE_RED)
		despawn_enemy_visual(target)

func open_skill_menu():
	var actor = get_current_actor()
	set_player_ui_enabled(false)
	skill_menu.setup(actor)
	skill_menu.show()

func _on_skill_chosen(skill: SkillData):
	skill_menu.hide()
	if skill.target_selector == "all":
		var all_enemies = get_alive_enemies()
		execute_skill_aoe(get_current_actor(), skill, all_enemies)
	else:
		start_target_selection(get_current_actor(), skill)

func _on_skill_menu_canceled():
	skill_menu.hide()
	set_player_ui_enabled(true)

func _on_skills_btn_pressed() -> void:
	open_skill_menu()

func highlight_potential_targets(active: bool):
	for e in enemies:
		if not e.is_alive() or not e.battle_node: continue
		e.battle_node.is_targetable = active
		if e.battle_node.has_meta("highlight_tween"):
			var old_tween = e.battle_node.get_meta("highlight_tween")
			if old_tween and old_tween.is_valid():
				old_tween.kill()

		if active:
			var tween = create_tween().set_loops()
			tween.tween_property(e.battle_node, "modulate", Color.YELLOW, 0.5)
			tween.tween_property(e.battle_node, "modulate", Color.WHITE, 0.5)

			e.battle_node.set_meta("highlight_tween", tween)
		else:
			e.battle_node.modulate = Color.WHITE 
			e.battle_node.remove_meta("highlight_tween")

#endregion

#region LOGIC
func get_targets_dynamic(user: BattleCharacter, config: Dictionary) -> Array[BattleCharacter]:
	var pool: Array[BattleCharacter] = []
	
	# --- 1. POOL  ---
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

	# --- 3. SELECTOR ---
	var count = config.get("count", 1)
	var final_targets: Array[BattleCharacter] = []
	
	match config.get("selector", "all"):
		"all": 
			final_targets = pool
		"random":
			pool.shuffle()
			final_targets = pool.slice(0, count)
		"manual":
			# TODO: hier später UI-Targeting logik
			pass 

	return final_targets

func calculate_damage(attacker: BattleCharacter, target: BattleCharacter, skill: SkillData) -> int:
	var attacker_stat = attacker.data.get(skill.scaling_stat)
	var raw_damage = skill.base_damage + (attacker_stat * skill.scaling_factor)

	if skill.can_crit:
		var crit_chance = attacker.data.luck * 0.5 
		if randf() * 100 < crit_chance:
			raw_damage *= skill.crit_multiplier
			print("KRITISCHER TREFFER!") # TODO: Signal für gelbe Zahlen im Dmg Popup

	var defense = target.data.def
	@warning_ignore("integer_division")
	var final_damage = int(raw_damage) - (defense / 2)

	if skill.damage_type == "Heal":
		return -int(raw_damage) 

	return max(1, final_damage)

func apply_status_effect(attacker: BattleCharacter, target: BattleCharacter, effect_data: StatusEffectData):
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
			post_log(target.data.name + ": " + effect_data.effect_name + " verlängert.", Color.CYAN)
	else:
		var new_effect = effect_data.duplicate()
		new_effect.current_stacks = 1
		if new_effect.scaling_stat != "none":
			new_effect.stored_actor_stat = attacker.data.get(new_effect.scaling_stat)
		target.active_effects.append(new_effect)
		post_log(target.data.name + " wurde " + effect_data.effect_name + "!", Color.GOLD)
	
	# TODO: kleines Icon über dem Gegner spawnen

func process_status_effects(actor: BattleCharacter):
	for i in range(actor.active_effects.size() - 1, -1, -1):
		var effect = actor.active_effects[i]

		if effect.type == "DoT" and effect.base_dot_damage > 0:
			var damage_per_stack = effect.base_dot_damage + (effect.stored_actor_stat * effect.scaling_factor)
			var total_damage = int(damage_per_stack * effect.current_stacks)
			apply_skill_effects(null, actor, total_damage, null)

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
