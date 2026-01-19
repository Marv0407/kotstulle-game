extends Node
class_name  BattleManager

####################
# Variables
####################
@export var party_data: Array[CharData]
@export var enemy_data: Array[CharData]
@export var turn_order_container: HBoxContainer
var party: Array[BattleCharacter] = []
var enemies: Array[BattleCharacter] = []
var turn_order: Array[BattleCharacter] = []
var current_turn_index : int
enum BattleState { #TODO Turn States später einfügen um Auto Battle abzulösen
	START,
	PLAYER_TURN,
	TARGET_SELECT,
	ENEMY_TURN,
	END
}
var state := BattleState.START


####################
# Functions
####################

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#pass

func start_battle(): # Cleart Daten, erstellt Instanzen, sortiert nach Initiative/Speed und startet Loop (vorerst)

	party.clear()
	enemies.clear()
	turn_order.clear()
	
	for data in party_data:
		var bc = BattleCharacter.new()
		bc.setup(data)
		party.append(bc)

	for data in enemy_data:
		var bc = BattleCharacter.new()
		bc.setup(data)
		enemies.append(bc)
	
	calculate_turn_order()
	current_turn_index = 0
	refresh_turn_order_ui()
	
	print("--- Kampf beginnt ---")
	process_battle_loop()
	

func process_turn(): #TODO hiermit später durch die states iterieren 
	var actor = get_current_actor()

	if not actor.is_alive():
		next_turn()
		process_turn()
		return

	if actor in party:
		state = BattleState.PLAYER_TURN
		print("Spieler ist am Zug: ", actor.data.name)
	else:
		state = BattleState.ENEMY_TURN
		print("Gegner ist am Zug: ", actor.data.name)
		execute_enemy_turn()

func execute_enemy_turn():
	var actor = get_current_actor()
	var targets = get_alive_party()

	if targets.is_empty():
		end_battle(false)
		return

	attack(actor, targets.pick_random())
	await get_tree().create_timer(0.8).timeout
	next_turn()
	process_turn()

func calculate_turn_order():
	turn_order.clear()
	turn_order.append_array(party)
	turn_order.append_array(enemies)
	turn_order.sort_custom(func(a, b):
		return a.data.speed > b.data.speed
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

	print(attacker.data.name, " greift ", target.data.name,
		  " an für ", damage, " Schaden. (",
		  target.current_hp, "/", target.data.max_hp, ")")

	if target.current_hp <= 0:
		print(target.data.name, " wurde besiegt!")

func debug_player_attack():
	if state != BattleState.PLAYER_TURN:
		return

	var actor = get_current_actor()
	var targets = get_alive_enemies()
	if targets.is_empty():
		end_battle(true)
		return

	attack(actor, targets[0])
	next_turn()
	process_turn()

func execute_turn():
	var actor = get_current_actor()

	if not actor.is_alive():
		next_turn()
		return
	# Ziel bestimmen
	if actor in party:
		var targets = get_alive_enemies()
		if targets.is_empty():
			end_battle(true)
			return
		attack(actor, targets.pick_random())
	else:
		var targets = get_alive_party()
		if targets.is_empty():
			end_battle(false)
			return
		attack(actor, targets.pick_random())

	next_turn()

func process_battle_loop(): # prüft ob kampf vorbei ist, führt einen zug aus und ruft sich danach wieder auf # TODO später löschen und durch Turn States ersetzen
	if is_battle_over():
		return

	process_turn()
	
####################
# Helpers
####################
func print_turn_order(): #TODO delete later
	print("Turn Order:")
	for c in turn_order:
		print(" - ", c.data.name)

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

func get_alive_party() -> Array[BattleCharacter]:
	return party.filter(func(c): return c.is_alive())

func get_alive_enemies() -> Array[BattleCharacter]:
	return enemies.filter(func(c): return c.is_alive())

func is_battle_over() -> bool:
	return get_alive_party().is_empty() or get_alive_enemies().is_empty()

func refresh_turn_order_ui():
	if not turn_order_container: return

	for child in turn_order_container.get_children():
		child.queue_free()

	for i in range(turn_order.size()):
		var character = turn_order[i]
		if not character.is_alive(): continue # Tote aus UI ausblenden
		var label := Label.new()
		label.text = character.data.name

		if i == current_turn_index:
			label.text = "> " + label.text
			label.add_theme_color_override("font_color", Color.YELLOW)

		turn_order_container.add_child(label)

func end_battle(player_won: bool): #TODO für spätere Turn States..
	state = BattleState.END
	if player_won:
		print(">>> PARTY GEWINNT <<<")
	else:
		print(">>> PARTY VERLIERT <<<")
