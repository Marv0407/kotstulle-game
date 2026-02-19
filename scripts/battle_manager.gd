extends Node
class_name  BattleManager

#region VARIABLES
@export var party_data: Array[CharData]
@export var enemy_data: Array[CharData]
@export var turn_order_container: HBoxContainer
@export var enemy_scene: PackedScene = preload("res://scenes/EnemySlot.tscn")
@export var damage_popup: PackedScene = preload("res://scenes/DamagePopup.tscn")
@export var turn_order_slot_scene: PackedScene
@export_group("Audio")
@export var sound_focus: AudioStream     
@export var sound_select: AudioStream    
@export var sound_cancel: AudioStream    
# --- PARTIES ---
var party: Array[BattleCharacter] = []
var enemies: Array[BattleCharacter] = []
# --- TURN STATES & ORDER ---
var turn_order: Array[BattleCharacter] = []
var turn_order_slots: Array = []
var current_turn_index : int
enum BattleState { 
	START,
	PLAYER_TURN,
	TARGET_SELECT,
	ENEMY_TURN,
	END
}
var state := BattleState.START
# --- TARGETING ---
var pending_skill: SkillData
var pending_user: BattleCharacter
var focused_target_index: int = 0
# --- VFX & SFX ---
@onready var spawn_point = $"../DebugUI/EnemyPositionAnchor/EnemyPartyContainer"
@onready var party_panel: PartyHUD = $"../DebugUI/CanvasLayer/PartyMenuContainer/ColorRect/PartyHUDContainer"
@onready var log_container = $"../DebugUI/CanvasLayer/PanelContainer/ScrollContainer/LogContainer"
@onready var skill_menu = $"../DebugUI/CanvasLayer/SkillMenu"
@onready var sfx_player: AudioStreamPlayer = $SFXPlayer
@onready var action_menu = $"../DebugUI/CanvasLayer/PartyMenuContainer/ActionsContainer/ColorRect/VBoxContainer"
@onready var victory_panel = $"../DebugUI/VictoryPanel"
@onready var victory_label = $"../DebugUI/VictoryPanel/Header"
@onready var xp_gained_label = $"../DebugUI/VictoryPanel/GridContainer/ExpLabel"
@onready var gold_gained_label = $"../DebugUI/VictoryPanel/GridContainer/GoldLabel"
@onready var loot_gained_label = $"../DebugUI/VictoryPanel/GridContainer/LootLabel"
@onready var victory_button = $"../DebugUI/VictoryPanel/Button"
var earned_xp: int = 0
var earned_gold: int = 0
var earned_loot: Array[String] = []
#endregion

# --- SETUP ---
func _ready():
	skill_menu.skill_selected.connect(_on_skill_chosen)
	skill_menu.canceled.connect(_on_skill_menu_canceled)
	skill_menu.request_sound.connect(_on_skill_menu_sound_requested)
	skill_menu.hide()
	setup_button_sounds(action_menu)

func start_battle(): 
	party.clear(); enemies.clear(); turn_order.clear()
	for child in spawn_point.get_children(): child.queue_free()

	#load party
	for member_dict in GameData.party_members:
		var bc = BattleCharacter.new()
		bc.setup_from_dict(member_dict) 
		party.append(bc)
	party_panel.populate(party)

	#load enemies and placee into slots
	var encounter = GameData.current_encounter
	var enemies_to_load = []
	if encounter and not encounter.enemies.is_empty():
		enemies_to_load = encounter.enemies
	else:
		enemies_to_load = enemy_data # Fallback
	for data in enemies_to_load:
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
			new_slot.hovered.connect(_on_slot_hovered)
			new_slot.unhovered.connect(_on_slot_unhovered)

		# Dynamic positioning of each slot
		var x_offset = (i - (count - 1) / 2.0) * spacing
		new_slot.position = Vector2(x_offset, 0)

		# get sprites from resource 
		var resource_sprite = enemies[i].data.sprite
		var sprite_node = new_slot.get_node("Sprite2D")
		sprite_node.texture = resource_sprite
		enemies[i].battle_node = new_slot

	# initiate battle
	calculate_turn_order()
	current_turn_index = 0
	refresh_turn_order_ui()
	process_turn()

func build_turn_order_ui():
	for child in turn_order_container.get_children():
		child.queue_free()
	turn_order_slots.clear()
	for c in turn_order:
		var slot = turn_order_slot_scene.instantiate()
		turn_order_container.add_child(slot)
		slot.setup(c)
		turn_order_slots.append(slot)
# --------------

#region TURN LOGIC
func process_turn(): 
	if check_battle_victory_condition(): return
	var actor = get_current_actor()
	process_status_effects(actor)

	if not actor.is_alive():
		next_turn()
		process_turn()
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
		execute_skill(actor, selected_skill, targets_array)
	else:
		next_turn()
		process_turn()

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


func refresh_turn_order_ui():
	for slot in turn_order_slots:
		if not slot.character.is_alive():
			slot.set_dead()
		else:
			slot.set_inactive()

	var current = get_current_actor()
	for slot in turn_order_slots:
		if slot.character == current:
			slot.set_active()
			break

func calculate_turn_order():
	turn_order.clear()
	turn_order.append_array(party)
	turn_order.append_array(enemies)
	turn_order.sort_custom(
		func(a, b): return a.data.speed > b.data.speed
		)
	build_turn_order_ui()

func end_battle(player_won: bool):
	for i in range(party.size()):
		var bc = party[i]
		GameData.party_members[i]["current_hp"] = bc.current_hp
	if player_won:
		if GameData.last_encounter_id != "":
			GameData.defeated_encounters.append(GameData.last_encounter_id)
			GameData.last_encounter_id = ""
		for e in enemies: 
			earned_xp += e.data.xp_yield
			earned_gold += e.data.gold
			#if e.data.items and randf_range(0, 100) <= e.data.item_dropchance: #TODO
				#earned_loot.append(e.data.items)
		for i in range(GameData.party_members.size()):
			GameData.add_xp_to_hero(i, earned_xp)
		display_battle_results("SIEG")
	else:
		display_battle_results("VERLOREN LOL")
#endregion

#region ATTACK & SKILL LOGIC
func execute_skill(user: BattleCharacter, skill: SkillData, initial_targets: Array[BattleCharacter]):
	state = BattleState.ENEMY_TURN 
	var context = CombatContext.new(self)
	var targets = initial_targets
	if skill.targeting and skill.targeting.target_selector != "manual":
		var config = {
			"target_pool": skill.targeting.target_pool,
			"state": skill.targeting.target_state,
			"selector": skill.targeting.target_selector,
			"count": skill.targeting.target_count
		}
		targets = get_targets_dynamic(user, config)
	for effect in skill.effects:
		effect.apply(user, targets, context)
	await get_tree().create_timer(0.6).timeout
	next_turn()
	process_turn()

func apply_skill_effects(attacker: BattleCharacter, target: BattleCharacter, damage: int, skill: SkillData):
	var old_hp = target.get_hp()
	target.current_hp -= damage
	if attacker and skill:
		post_log(attacker.data.name + " nutzt " + skill.skill_name + " für " + str(damage) + " Schaden.", Color.WHITE)
	else:
		post_log(target.data.name + " erleidet " + str(damage) + " Schaden durch Effekt.", Color.LIGHT_CORAL)

	# UI Update für Party
	if target in party:
		for ui in party_panel.get_children():
			if ui.character == target:
				ui.update_hp(old_hp)
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

		if is_battle_over():
			check_battle_victory_condition() 
			return

func _on_target_clicked(_target_node):
	if state != BattleState.TARGET_SELECT: return
	play_sfx(sound_select)
	highlight_potential_targets(false)
	if pending_skill.targeting.target_selector == "all":
		execute_skill(pending_user, pending_skill, get_alive_enemies())
	elif pending_skill.targeting.target_selector == "random":
		execute_skill(pending_user, pending_skill, [])
	else:
		var target_character = null
		for e in enemies:
			if e.battle_node == _target_node:
				target_character = e
				break
		if target_character:
			execute_skill(pending_user, pending_skill, [target_character])

func calculate_damage(attacker: BattleCharacter, target: BattleCharacter, skill: SkillData) -> int:
	var attacker_stat = attacker.data.get(skill.scaling_stat)
	var raw_damage = skill.base_damage + (attacker_stat * skill.scaling_factor)

	if skill.can_crit:
		var crit_chance = attacker.data.luck * 0.5 
		if randf() * 100 < crit_chance:
			raw_damage *= skill.crit_multiplier
			post_log("KRITISCHER TREFFER!", Color.YELLOW)

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
#endregion

#region VISUALS
func despawn_enemy_visual(character: BattleCharacter):
	if character.battle_node:
		# TODO insert other/different animations here later
		var tween = create_tween()
		tween.tween_property(character.battle_node, "modulate:a", 0, 0.5)
		tween.tween_property(character.battle_node, "scale", Vector2.ZERO, 0.5)
		tween.finished.connect(func(): character.battle_node.queue_free())

func start_target_selection(user: BattleCharacter, skill: SkillData):
	set_player_ui_enabled(false)
	state = BattleState.TARGET_SELECT
	play_sfx(sound_focus)
	pending_user = user
	pending_skill = skill
	focused_target_index = 0
	highlight_potential_targets(true)
	var alive_enemies = get_alive_enemies()
	if not alive_enemies.is_empty():
		_on_slot_hovered(alive_enemies[0].battle_node)

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

func flash_screen(color: Color, duration: float):
	$ColorRect.modulate = color
	$ColorRect.visible = true
	await get_tree().create_timer(duration).timeout
	$ColorRect.visible = false

func play_skill_sfx(stream: AudioStream):
	if not stream:
		return
	var player = AudioStreamPlayer.new()
	add_child(player)
	player.stream = stream
	player.play()
	player.finished.connect(player.queue_free)

func set_player_ui_enabled(enabled: bool):
	var first_button : Button = null
	for child in action_menu.get_children():
		if child is Button:
			child.disabled = !enabled
			if enabled and first_button == null:
				first_button = child
	if enabled and first_button:
		first_button.grab_focus()

func highlight_potential_targets(active: bool):
	for e in enemies:
		if not e.battle_node: continue
		if e.battle_node.has_meta("highlight_tween"):
			var old_tween = e.battle_node.get_meta("highlight_tween")
			if old_tween and old_tween.is_valid():
				old_tween.kill()
			e.battle_node.remove_meta("highlight_tween")
		e.battle_node.modulate = Color.WHITE
		e.battle_node.get_node("Sprite2D").modulate = Color.WHITE
		if e.battle_node.has_method("reset_visuals"):
			e.battle_node.reset_visuals()

		if active and e.is_alive():
			e.battle_node.is_targetable = true
			var tween = create_tween().set_loops()
			tween.tween_property(e.battle_node, "modulate", Color.YELLOW, 0.5)
			tween.tween_property(e.battle_node, "modulate", Color.WHITE, 0.5)
			e.battle_node.set_meta("highlight_tween", tween)
		else:
			e.battle_node.is_targetable = false

func display_battle_results(title: String):
	victory_panel.show()
	victory_label.text = title
	if title == "SIEG":
		#play_sfx() # TODO
		xp_gained_label.text = str(earned_xp)
		gold_gained_label.text = str(earned_gold)
		loot_gained_label.text = _get_grouped_loot_text()
	else:
		xp_gained_label.text = "0"
		gold_gained_label.text = "0"
		loot_gained_label.text = "Goar nix"
		pass
	victory_button.grab_focus()

func open_skill_menu():
	var actor = get_current_actor()
	var current_focus = get_viewport().gui_get_focus_owner()
	if current_focus:
		current_focus.release_focus()
	set_player_ui_enabled(false)
	skill_menu.setup(actor)
	skill_menu.show()
	await get_tree().process_frame
	await get_tree().process_frame
	skill_menu.focus_first_button()

func _on_skill_chosen(skill: SkillData):
	skill_menu.hide()
	play_sfx(sound_select)
	start_target_selection(get_current_actor(), skill)
	if skill.targeting.target_selector == "all": post_log("Ziel: Alle Gegner", Color.LIGHT_CYAN)
	elif skill.targeting.target_selector == "random": post_log("Ziel: Zufällig", Color.LIGHT_CYAN)
	else: post_log("Ziel wählen...", Color.LIGHT_CYAN)

func _on_skill_menu_canceled():
	play_sfx(sound_cancel)
	skill_menu.hide()
	set_player_ui_enabled(true)

func _on_skills_btn_pressed() -> void:
	open_skill_menu()
#endregion

#region HELPERS
func get_alive_party() -> Array[BattleCharacter]:
	return party.filter(func(c): return c.is_alive())

func check_battle_victory_condition():
	if get_alive_enemies().is_empty():
		end_battle(true)
		return true
	elif get_alive_party().is_empty():
		end_battle(false)
		return true
	return false

func _get_grouped_loot_text() -> String:
	if earned_loot.is_empty():
		return "Kein Loot gefunden"
	var counts = {}
	for item in earned_loot:
		if counts.has(item):
			counts[item] += 1
		else:
			counts[item] = 1

	var final_text = ""
	for item_name in counts.keys():
		var amount = counts[item_name]
		if amount > 1:
			final_text += "- " + item_name + " x" + str(amount) + "\n"
		else:
			final_text += "- " + item_name + "\n"
	return final_text

func get_alive_enemies() -> Array[BattleCharacter]:
	return enemies.filter(func(c): return c.is_alive())

func is_battle_over() -> bool:
	return get_alive_party().is_empty() or get_alive_enemies().is_empty()

func get_current_actor() -> BattleCharacter:
	return turn_order[current_turn_index]

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
			final_targets = pool
			pass 

	return final_targets

func _process(_delta):
	if state == BattleState.TARGET_SELECT:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			cancel_target_selection()
			post_log("Zielauswahl abgebrochen...")

func cancel_target_selection():
	highlight_potential_targets(false)
	state = BattleState.PLAYER_TURN
	play_sfx(sound_cancel)
	set_player_ui_enabled(true)

func _on_slot_hovered(hovered_slot):
	if state != BattleState.TARGET_SELECT or not pending_skill: return
	play_sfx(sound_focus)
	match pending_skill.targeting.target_selector:
		"all", "random":
			for e in enemies:
				if e.is_alive() and e.battle_node:
					e.battle_node.get_node("Sprite2D").modulate = Color(1.5, 1.5, 1.5)

		"manual":
			for e in enemies:
				if e.is_alive() and e.battle_node:
					e.battle_node.get_node("Sprite2D").modulate = Color.WHITE
			if hovered_slot and hovered_slot.has_node("Sprite2D"):
				hovered_slot.get_node("Sprite2D").modulate = Color(1.5, 1.5, 1.5)

func _on_slot_unhovered(_slot):
	if state == BattleState.TARGET_SELECT:
		for e in enemies:
			if e.is_alive() and e.battle_node:
				e.battle_node.get_node("Sprite2D").modulate = Color.WHITE

func _unhandled_input(event):
	if state != BattleState.TARGET_SELECT: return

	if event.is_action_pressed("ui_cancel"):
		cancel_target_selection()
		return

	if event.is_action_pressed("ui_right"):
		change_target_focus(1)
	elif event.is_action_pressed("ui_left"):
		change_target_focus(-1)

	if event.is_action_pressed("ui_accept"):
		var alive_enemies = get_alive_enemies()
		if not alive_enemies.is_empty():
			var target_char = alive_enemies[focused_target_index]
			highlight_potential_targets(false)
			_on_target_clicked(target_char.battle_node)

func change_target_focus(direction: int):
	var alive_enemies = get_alive_enemies()
	if alive_enemies.is_empty(): return
	
	_on_slot_unhovered(null)
	
	focused_target_index += direction
	if focused_target_index >= alive_enemies.size(): focused_target_index = 0
	if focused_target_index < 0: focused_target_index = alive_enemies.size() - 1

	var new_target_node = alive_enemies[focused_target_index].battle_node
	_on_slot_hovered(new_target_node)

func play_sfx(stream: AudioStream):
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func setup_button_sounds(container: Node):
	for child in container.get_children():
		if child is Button:
			if not child.focus_entered.is_connected(play_sfx):
				child.focus_entered.connect(play_sfx.bind(sound_focus))
				child.mouse_entered.connect(play_sfx.bind(sound_focus))
			if not child.pressed.is_connected(play_sfx):
				child.pressed.connect(play_sfx.bind(sound_select))

func _on_skill_menu_sound_requested(type: String):
	match type:
		"focus":
			play_sfx(sound_focus)
		"select":
			play_sfx(sound_select)

	#endregion
