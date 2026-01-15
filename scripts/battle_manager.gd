extends Node
class_name  BattleManager

####################
# Variables
####################
@export var party_data: Array[CharData]
@export var enemy_data: Array[CharData]
var party: Array[BattleCharacter] = []
var enemies: Array[BattleCharacter] = []
var turn_order: Array[BattleCharacter] = []
var current_turn_index := 0
enum BattleState {
	START,
	PLAYER_TURN,
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func start_battle():
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

	print("--- Kampf beginnt ---")
	process_battle_loop()
	

func process_turn():
	var actor = get_current_actor()

	if actor in party:
		state = BattleState.PLAYER_TURN
	else:
		state = BattleState.ENEMY_TURN

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
	current_turn_index += 1
	if current_turn_index >= turn_order.size():
		current_turn_index = 0

func attack(attacker: BattleCharacter, target: BattleCharacter):
	var damage = max(attacker.data.atk - target.data.def, 1)
	target.current_hp -= damage

	print(attacker.data.name, " greift ", target.data.name,
		  " an für ", damage, " Schaden. (",
		  target.current_hp, "/", target.data.max_hp, ")")

	if target.current_hp <= 0:
		print(target.data.name, " wurde besiegt!")

func execute_turn():
	var actor = get_current_actor()

	if not actor.is_alive():
		next_turn()
		return

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

func process_battle_loop():
	if is_battle_over():
		return

	execute_turn()

	await get_tree().create_timer(0.8).timeout
	process_battle_loop()

####################
# Helpers
####################
func print_turn_order(): #TODO delete later
	print("Turn Order:")
	for c in turn_order:
		print(" - ", c.data.name)

func get_alive_party() -> Array[BattleCharacter]:
	return party.filter(func(c): return c.is_alive())

func get_alive_enemies() -> Array[BattleCharacter]:
	return enemies.filter(func(c): return c.is_alive())

func is_battle_over() -> bool:
	return get_alive_party().is_empty() or get_alive_enemies().is_empty()

func end_battle(player_won: bool):
	if player_won:
		print(">>> PARTY GEWINNT <<<")
	else:
		print(">>> PARTY VERLIERT <<<")
